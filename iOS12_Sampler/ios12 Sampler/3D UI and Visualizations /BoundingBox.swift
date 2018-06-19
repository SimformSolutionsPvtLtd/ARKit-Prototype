/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An interactive visualization of a bounding box in 3D space with movement and resizing controls.
*/

import Foundation
import ARKit

class BoundingBox: SCNNode {
    
    static let extentChangedNotification = Notification.Name("BoundingBoxExtentChanged")
    static let positionChangedNotification = Notification.Name("BoundingBoxPositionChanged")
    static let scanPercentageChangedNotification = Notification.Name("ScanPercentageChanged")
    static let scanPercentageUserInfoKey = "ScanPercentage"
    
    var extent: float3 = float3(0.1, 0.1, 0.1) {
        didSet {
            extent = max(extent, minSize)
            updateVisualization()
            NotificationCenter.default.post(name: BoundingBox.extentChangedNotification,
                                            object: self)
        }
    }
    
    override var simdPosition: float3 {
        didSet {
            NotificationCenter.default.post(name: BoundingBox.positionChangedNotification,
                                            object: self)
        }
    }
    
    var hasBeenAdjustedByUser = false
    private var maxDistanceToFocusPoint: Float = 0.05
    
    private var minSize: Float = 0.01
    
    private struct SideDrag {
        var side: BoundingBoxSide
        var planeTransform: float4x4
        var beginWorldPos: float3
        var beginExtent: float3
    }
    
    private var currentSideDrag: SideDrag?
    
    private var currentAxisDrag: PlaneDrag?
    private var currentPlaneDrag: PlaneDrag?
    
    private var wireframe: Wireframe?
    
    private var sidesNode = SCNNode()
    private var sides: [BoundingBoxSide.Position: BoundingBoxSide] = [:]
    
    private var color = UIColor.appYellow
    
    private var cameraRaysAndHitLocations: [(ray: Ray, hitLocation: float3)] = []
    private var frameCounter: Int = 0
    
    var progressPercentage: Int = 0
    private var isUpdatingCapturingProgress = false
    
    private var sceneView: ARSCNView
    
    init(_ sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.scanningStateChanged(_:)),
                                               name: Scan.stateChangedNotification,
                                               object: nil)
        updateVisualization()
    }
    
    @objc
    private func scanningStateChanged(_ notification: Notification) {
        guard let state = notification.userInfo?[Scan.stateUserInfoKey] as? Scan.State else { return }
        switch state {
        case .ready, .defineBoundingBox:
            resetCapturingProgress()
            sides.forEach { $0.value.isHidden = false }
        case .scanning:
            sides.forEach { $0.value.isHidden = false }
        case .adjustingOrigin:
            // Hide the sides while adjusting the origin.
            sides.forEach { $0.value.isHidden = true }
        }
    }
    
    func fitOverPointCloud(_ pointCloud: ARPointCloud, focusPoint: float3?) {
        var filteredPoints: [vector_float3] = []
        
        for point in pointCloud.points {
            if let focus = focusPoint {
                // Skip this point if it is more than maxDistanceToFocusPoint meters away from the focus point.
                let distanceToFocusPoint = length(point - focus)
                if distanceToFocusPoint > maxDistanceToFocusPoint {
                    continue
                }
            }
            
            // Skip this point if it is an outlier (not at least 3 other points closer than 3 cm)
            var nearbyPoints = 0
            for otherPoint in pointCloud.points {
                if distance(point, otherPoint) < 0.03 {
                    nearbyPoints += 1
                    if nearbyPoints >= 3 {
                        filteredPoints.append(point)
                        break
                    }
                }
            }
        }
        
        guard !filteredPoints.isEmpty else { return }
        
        var localMin = -extent / 2
        var localMax = extent / 2
        
        for point in filteredPoints {
            // The bounding box is in local coordinates, so convert point to local, too.
            let localPoint = self.simdConvertPosition(point, from: nil)
            
            localMin = min(localMin, localPoint)
            localMax = max(localMax, localPoint)
        }
        
        // Update the position & extent of the bounding box based on the new min & max values.
        self.simdPosition += (localMax + localMin) / 2
        self.extent = localMax - localMin
    }
    
    private func updateVisualization() {
        ScanObjectsVC.serialQueue.async {
            self.updateSides()
            self.updateWireframe()
        }
    }
    
    private func updateWireframe() {
        // Note: No serialQueue.async in here because this method is called only from updateVisualization()
        // When this method is called the first time, create the wireframe and add them as child node.
        guard let wireframe = self.wireframe else {
            let wireframe = Wireframe(extent: self.extent, color: color)
            self.addChildNode(wireframe)
            self.wireframe = wireframe
            return
        }
        
        // Otherwise just update the wireframe's size and position.
        wireframe.update(extent: self.extent)
    }
    
    private func updateSides() {
        // Note: No serialQueue.async in here because this method is called only from updateVisualization()
        // When this method is called the first time, create the sides and add them to the sidesNode.
        guard sides.count == 6 else {
            createSides()
            self.addChildNode(sidesNode)
            return
        }
        
        // Otherwise just update the geometries's size and position.
        sides.forEach { $0.value.update(boundingBoxExtent: self.extent) }
    }
    
    private func createSides() {
        for position in BoundingBoxSide.Position.allCases {
            self.sides[position] = BoundingBoxSide(position, boundingBoxExtent: self.extent, color: self.color)
            self.sidesNode.addChildNode(self.sides[position]!)
        }
    }
    
    func startSideDrag(screenPos: CGPoint) {
        guard let camera = sceneView.pointOfView else { return }

        // Check if the user is starting the drag on one of the sides. If so, pull/push that side.
        let hitResults = sceneView.hitTest(screenPos, options: [
            .rootNode: sidesNode,
            .ignoreHiddenNodes: false])
        
        for result in hitResults {
            if let side = result.node.parent as? BoundingBoxSide {
                side.showZAxisExtensions()
                
                let sideNormalInWorld = normalize(self.simdConvertVector(side.normal, to: nil) -
                    self.simdConvertVector(float3(0), to: nil))
                
                let ray = Ray(origin: float3(result.worldCoordinates), direction: sideNormalInWorld)
                let transform = dragPlaneTransform(for: ray, cameraPos: camera.simdWorldPosition)
                
                currentSideDrag = SideDrag(side: side, planeTransform: transform, beginWorldPos: self.simdWorldPosition, beginExtent: self.extent)
                hasBeenAdjustedByUser = true
                return
            }
        }
    }
    
    func updateSideDrag(screenPos: CGPoint) {
        guard let drag = currentSideDrag else { return }
        
        // Compute a new position for this side of the bounding box based on the given screen position.
        if let hitPos = sceneView.unprojectPointLocal(screenPos, ontoPlane: drag.planeTransform) {
            let movementAlongRay = hitPos.x

            // First column of the planeTransform is the ray along which the box
            // is manipulated, in world coordinates. The center of the bounding box
            // has be be moved by half of the finger's movement on that ray.
            let originOffset = (drag.planeTransform.columns.0 * (movementAlongRay / 2)).xyz
            
            let extentOffset = drag.side.dragAxis.normal * movementAlongRay
            let newExtent = drag.beginExtent + extentOffset
            guard newExtent.x >= minSize && newExtent.y >= minSize && newExtent.z >= minSize else { return }
            
            // Push/pull a single side of the bounding box by a combination
            // of moving & changing the extent of the box.
            self.simdWorldPosition = drag.beginWorldPos + originOffset
            self.extent = newExtent
        }
    }
    
    func endSideDrag() {
        guard let drag = currentSideDrag else { return }
        drag.side.hideZAxisExtensions()
        currentSideDrag = nil
    }
    
    func startAxisOrPlaneDrag(screenPos: CGPoint) {
        guard let camera = sceneView.pointOfView else { return }

        let hitResults = sceneView.hitTest(screenPos, options: [
            .rootNode: sidesNode,
            .ignoreHiddenNodes: false])
        
        for result in hitResults {
            if let side = result.node.parent as? BoundingBoxSide {
                for side in sidesForAxis(side.dragAxis) {
                    side?.showZAxisExtensions()
                }
                
                let sideNormalInWorld = normalize(self.simdConvertVector(side.dragAxis.normal, to: nil) -
                    self.simdConvertVector(float3(0), to: nil))
                
                let dragRay = Ray(origin: float3(result.worldCoordinates), direction: sideNormalInWorld)
                let transform = dragPlaneTransform(for: dragRay, cameraPos: camera.simdWorldPosition)
                
                var offset = float3()
                if let hitPos = sceneView.unprojectPointLocal(screenPos, ontoPlane: transform) {
                    // Project the result onto the plane's X axis & transform into world coordinates.
                    let posOnPlaneXAxis = float4(hitPos.x, 0, 0, 1)
                    let worldPosOnPlaneXAxis = transform * posOnPlaneXAxis
                    offset = self.simdWorldPosition - worldPosOnPlaneXAxis.xyz
                }
                
                currentAxisDrag = PlaneDrag(planeTransform: transform, offset: offset)
                hasBeenAdjustedByUser = true
                return
            }
        }
        
        // If no side was hit, reposition the bounding box in the XZ-plane.
        startPlaneDrag(screenPos: screenPos, keepOffset: true)
    }
    
    func updateAxisOrPlaneDrag(screenPos: CGPoint) {
        if let drag = currentAxisDrag {
            if let hitPos = sceneView.unprojectPointLocal(screenPos, ontoPlane: drag.planeTransform) {
                // Project the result onto the plane's X axis & transform into world coordinates.
                let posOnPlaneXAxis = float4(hitPos.x, 0, 0, 1)
                let worldPosOnPlaneXAxis = drag.planeTransform * posOnPlaneXAxis
                
                self.simdWorldPosition = worldPosOnPlaneXAxis.xyz + drag.offset
            }
        } else {
            updatePlaneDrag(screenPos: screenPos)
        }
    }
    
    func endAxisOrPlaneDrag() {
        if currentAxisDrag != nil {
            hideExtensionsOnAllAxes()
            currentAxisDrag = nil
        } else {
            endPlaneDrag()
        }
    }
    
    func hideExtensionsOnAllAxes() {
        sides.forEach {
            $0.value.hideXAxisExtensions()
            $0.value.hideYAxisExtensions()
            $0.value.hideZAxisExtensions()
        }
    }
    
    func startPlaneDrag(screenPos: CGPoint, keepOffset: Bool) {
        let dragPlane = self.simdWorldTransform
        var offset = float3(0)
        if keepOffset, let hitPos = sceneView.unprojectPoint(screenPos, ontoPlane: dragPlane) {
            offset = self.simdWorldPosition - hitPos
        }
        self.currentPlaneDrag = PlaneDrag(planeTransform: dragPlane, offset: offset)
        hasBeenAdjustedByUser = true
    }
    
    func updatePlaneDrag(screenPos: CGPoint) {
        sides[.bottom]?.showXAxisExtensions()
        sides[.bottom]?.showYAxisExtensions()
        
        guard let drag = currentPlaneDrag else { return }
        if let hitPos = sceneView.unprojectPoint(screenPos, ontoPlane: drag.planeTransform) {
            self.simdWorldPosition = hitPos + drag.offset
        }
    }
    
    func endPlaneDrag() {
        currentPlaneDrag = nil
        sides[.bottom]?.hideXAxisExtensions()
        sides[.bottom]?.hideYAxisExtensions()
    }
    
    func isHit(screenPos: CGPoint) -> Bool {
        
        let hitResults = sceneView.hitTest(screenPos, options: [
            .rootNode: sidesNode,
            .ignoreHiddenNodes: false])
        
        for result in hitResults {
            for (_, side) in sides where result.node == side {
                return true
            }
        }
        
        return false
    }
    
    func resetCapturingProgress() {
        cameraRaysAndHitLocations.removeAll()
        for (_, side) in self.sides {
            side.tiles.forEach {
                $0.isCaptured = false
                $0.isHighlighted = false
                $0.updateVisualization()
            }
        }
    }
    
    func highlightCurrentTile() {
        // Create a new hit test ray. A line segment defined by its start and end point
        // is used to hit test against bounding box tiles. The ray's length allows for
        // intersections if the user is no more than five meters away from the bounding box.
        let ray = Ray(from: sceneView.pointOfView!, length: 5.0)
        
        for (_, side) in self.sides {
            for tile in side.tiles where tile.isHighlighted {
                tile.isHighlighted = false
            }
        }
        
        if let (tile, _) = tile(hitBy: ray) {
            tile.isHighlighted = true
        }
        
        // Update the opacity of all tiles.
        for (_, side) in self.sides {
            side.tiles.forEach { $0.updateVisualization() }
        }
    }
    
    func updateCapturingProgress() {
        frameCounter += 1

        // Add new hit test rays at a lower frame rate to keep the list of previous rays
        // at a reasonable size.
        if frameCounter % 20 == 0 {
            frameCounter = 0
            
            // Create a new hit test ray. A line segment defined by its start and end point
            // is used to hit test against bounding box tiles. The ray's length allows for
            // intersections if the user is no more than five meters away from the bounding box.
            let currentRay = Ray(from: sceneView.pointOfView!, length: 5.0)
            
            // Only remember the ray if it hit the bounding box,
            // and the hit location is significantly different from all previous hit locations.
            if let (_, hitLocation) = tile(hitBy: currentRay) {
                if isHitLocationDifferentFromPreviousRayHitTests(hitLocation) {
                    cameraRaysAndHitLocations.append((ray: currentRay, hitLocation: hitLocation))
                }
            }
        }
        
        // Update tiles at a frame rate that provides a trade-off between responsiveness and performance.
        guard frameCounter % 10 == 0, !isUpdatingCapturingProgress else { return }
        
        ScanObjectsVC.serialQueue.async {
            self.isUpdatingCapturingProgress = true
            
            var capturedTiles: [Tile] = []
            
            // Perform hit tests with all previous rays.
            for hitTest in self.cameraRaysAndHitLocations {
                if let (tile, _) = self.tile(hitBy: hitTest.ray) {
                    capturedTiles.append(tile)
                    tile.isCaptured = true
                }
            }
            
            for (_, side) in self.sides {
                side.tiles.forEach {
                    if !capturedTiles.contains($0) {
                        $0.isCaptured = false
                    }
                }
            }
            
            // Update the opacity of all tiles.
            for (_, side) in self.sides {
                side.tiles.forEach { $0.updateVisualization() }
            }
            
            // Update scan percentage for all sides, except the bottom
            var sum: Float = 0
            for (pos, side) in self.sides where pos != .bottom {
                sum += side.completion / 5.0
            }
            let progressPercentage: Int = min(Int(floor(sum * 100)), 100)
            if self.progressPercentage != progressPercentage {
                self.progressPercentage = progressPercentage
                NotificationCenter.default.post(name: BoundingBox.scanPercentageChangedNotification,
                                                object: self,
                                                userInfo: [BoundingBox.scanPercentageUserInfoKey: progressPercentage])
            }
            
            self.isUpdatingCapturingProgress = false
        }
    }
    
    /// Returns true if the given location differs from all hit locations in the cameraRaysAndHitLocations array
    /// by at least the threshold distance.
    func isHitLocationDifferentFromPreviousRayHitTests(_ location: float3) -> Bool {
        let distThreshold: Float = 0.03
        for hitTest in cameraRaysAndHitLocations.reversed() {
            if distance(hitTest.hitLocation, location) < distThreshold {
                return false
            }
        }
        return true
    }
    
    private func tile(hitBy ray: Ray) -> (tile: Tile, hitLocation: float3)? {
        // Perform hit test with given ray
        let hitResults = self.sceneView.scene.rootNode.hitTestWithSegment(from: ray.origin, to: ray.direction, options: [
            .ignoreHiddenNodes: false,
            .boundingBoxOnly: true,
            .searchMode: SCNHitTestSearchMode.all])
        
        // We cannot just look at the first result because we might have hits with other than the tile geometries.
        for result in hitResults {
            if let tile = result.node as? Tile {
                if let side = tile.parent as? BoundingBoxSide, side.isBusyUpdatingTiles {
                    continue
                }
                
                // Each ray should only hit one tile, so we can stop iterating through results if a hit was successful.
                return (tile: tile, hitLocation: float3(result.worldCoordinates))
            }
        }
        return nil
    }
    
    private func sidesForAxis(_ axis: Axis) -> [BoundingBoxSide?] {
        switch axis {
        case .x:
            return [sides[.left], sides[.right]]
        case .y:
            return [sides[.top], sides[.bottom]]
        case .z:
            return [sides[.front], sides[.back]]
        }
    }
    
    func updateOnEveryFrame() {
        if let frame = sceneView.session.currentFrame {
            // Check if the bounding box should align its bottom with a nearby plane.
            tryToAlignWithPlanes(frame.anchors)
        }
        
        sides.forEach { $0.value.updateVisualizationIfNeeded() }
    }
    
    func tryToAlignWithPlanes(_ anchors: [ARAnchor]) {
        guard !hasBeenAdjustedByUser, ScanObjectsVC.instance?.scan?.state == .defineBoundingBox else { return }
        
        let bottomCenter = SCNVector3(x: position.x, y: position.y - extent.y / 2, z: position.z)
        
        var distanceToNearestPlane = Float.greatestFiniteMagnitude
        var offsetToNearestPlaneOnY: Float = 0
        var planeFound = false
        
        // Check which plane is nearest to the bounding box.
        for anchor in anchors {
            guard let plane = anchor as? ARPlaneAnchor else {
                continue
            }
            guard let planeNode = sceneView.node(for: plane) else {
                continue
            }
            
            // Get the position of the bottom center of this bounding box in the plane's coordinate system.
            let bottomCenterInPlaneCoords = planeNode.convertPosition(bottomCenter, from: parent)
            
            // Add 10% tolerance to the corners of the plane.
            let tolerance: Float = 0.1
            let minX = plane.center.x - plane.extent.x / 2 - plane.extent.x * tolerance
            let maxX = plane.center.x + plane.extent.x / 2 + plane.extent.x * tolerance
            let minZ = plane.center.z - plane.extent.z / 2 - plane.extent.z * tolerance
            let maxZ = plane.center.z + plane.extent.z / 2 + plane.extent.z * tolerance
            
            guard (minX...maxX).contains(bottomCenterInPlaneCoords.x) && (minZ...maxZ).contains(bottomCenterInPlaneCoords.z) else {
                continue
            }
            
            let offsetToPlaneOnY = bottomCenterInPlaneCoords.y
            let distanceToPlane = abs(offsetToPlaneOnY)
            
            if distanceToPlane < distanceToNearestPlane {
                distanceToNearestPlane = distanceToPlane
                offsetToNearestPlaneOnY = offsetToPlaneOnY
                planeFound = true
            }
        }
        
        guard planeFound else { return }
        
        // Check that the object is not already on the nearest plane (closer than 1 mm).
        let epsilon: Float = 0.001
        guard distanceToNearestPlane > epsilon else { return }
        
        // Check if the nearest plane is close enough to the bounding box to "snap" to that
        // plane. The threshold is half of the bounding box extent on the y axis.
        let maxDistance = extent.y / 2
        if distanceToNearestPlane < maxDistance && offsetToNearestPlaneOnY > 0 {
            // Adjust the bounding box position & extent such that the bottom of the box
            // aligns with the plane.
            simdPosition.y -= offsetToNearestPlaneOnY / 2
            extent.y += offsetToNearestPlaneOnY
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
