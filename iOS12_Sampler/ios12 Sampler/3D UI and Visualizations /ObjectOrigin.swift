/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An interactive visualization of x/y/z coordinate axes for use in placing the origin/anchor point of a scanned object.
*/

import Foundation
import SceneKit
import ARKit

// Instances of this class represent the origin of the scanned 3D object - both
// logically as well as visually (as an SCNNode).
class ObjectOrigin: SCNNode {
    
    static let movedOutsideBoxNotification = Notification.Name("ObjectOriginMovedOutsideBoundingBox")
    
    private let axisLength: Float = 1.0
    private let axisThickness: Float = 6.0 // Axis thickness in percent of length.
    
    private let axisSizeToObjectSizeRatio: Float = 0.25
    private let minAxisSize: Float = 0.05
    private let maxAxisSize: Float = 0.2
    
    private var xAxis: ObjectOriginAxis!
    private var yAxis: ObjectOriginAxis!
    private var zAxis: ObjectOriginAxis!
    
    private var customModel: SCNNode?
    
    private var omniLightNode: SCNNode?
    private var ambientLightNode: SCNNode?
    
    private var currentAxisDrag: PlaneDrag?
    private var currentPlaneDrag: PlaneDrag?
    
    private var sceneView: ARSCNView
    
    var positionHasBeenAdjustedByUser: Bool = false
    
    var isDisplayingCustom3DModel: Bool {
        return customModel != nil
    }
    
    init(extent: float3, _ sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        
        let length = axisLength
        let thickness = (axisLength / 100.0) * axisThickness
        let radius = CGFloat(axisThickness / 2.0)
        let sphereRadius = CGFloat(axisLength / 8)
        
        xAxis = ObjectOriginAxis(axis: .x, length: length, thickness: thickness, radius: radius,
                                 sphereRadius: sphereRadius)
        yAxis = ObjectOriginAxis(axis: .y, length: length, thickness: thickness, radius: radius,
                                 sphereRadius: sphereRadius)
        zAxis = ObjectOriginAxis(axis: .z, length: length, thickness: thickness, radius: radius,
                                 sphereRadius: sphereRadius)
        
        setupShading()
        set3DModel(ScanObjectsVC.instance?.modelURL, extentForScaling: extent)
        adjustToExtent(extent)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.scanningStateChanged(_:)),
                                               name: Scan.stateChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.boundingBoxExtentChanged(_:)),
                                               name: BoundingBox.extentChangedNotification, object: nil)
        isHidden = true
    }
    
    func set3DModel(_ url: URL?, extentForScaling: float3?=nil) {
        if let url = url, let model = load3DModel(from: url) {
            customModel?.removeFromParentNode()
            customModel = nil
            xAxis.removeFromParentNode()
            yAxis.removeFromParentNode()
            zAxis.removeFromParentNode()
            omniLightNode?.isHidden = true
            ambientLightNode?.isHidden = true
            ScanObjectsVC.instance?.sceneView.prepare([model], completionHandler: { _ in
                self.addChildNode(model)
            })
            customModel = model
        } else {
            customModel?.removeFromParentNode()
            customModel = nil
            
            addChildNode(xAxis)
            addChildNode(yAxis)
            addChildNode(zAxis)
            omniLightNode?.isHidden = false
            ambientLightNode?.isHidden = false
        }
        
        adjustToExtent(extentForScaling)
    }
    
    @objc
    func boundingBoxExtentChanged(_ notification: Notification) {
        guard let boundingBox = notification.object as? BoundingBox else { return }
        self.adjustToExtent(boundingBox.extent)
    }
    
    func adjustToExtent(_ extent: float3?) {
        guard let extent = extent else {
            self.simdScale = float3(1.0)
            xAxis.simdScale = float3(1.0)
            yAxis.simdScale = float3(1.0)
            zAxis.simdScale = float3(1.0)
            return
        }
        
        if let model = customModel {
            // Scale the origin such that the custom 3D model fits into the given extent.
            let modelExtent = model.boundingSphere.radius * 2
            let scaleFactor = min(extent.x, extent.y, extent.z) / modelExtent
            self.simdScale = float3(scaleFactor)
        } else {
            // Make sure the origin's scale is 1 if we aren't displaying a custom 3D model.
            self.simdScale = float3(1.0)
            
            var scaleFactor = max(extent.x, extent.y, extent.z) * axisSizeToObjectSizeRatio
            
            // Stay within minimal and maximal size
            scaleFactor = min(scaleFactor, maxAxisSize)
            scaleFactor = max(scaleFactor, minAxisSize)
            
            // Adjust the scale of the axes (not the origin itself!)
            xAxis.simdScale = float3(scaleFactor)
            yAxis.simdScale = float3(scaleFactor)
            zAxis.simdScale = float3(scaleFactor)
        }
    }
    
    private func setupShading() {
        let omniLight = SCNLight()
        omniLight.type = .omni
        omniLight.intensity = 500
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        addChildNode(omniLightNode)
        self.omniLightNode = omniLightNode
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 500
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        addChildNode(ambientLightNode)
        self.ambientLightNode = ambientLightNode
    }
    
    func startDrag(screenPos: CGPoint, keepOffset: Bool) {
        if !isDisplayingCustom3DModel {
            guard let camera = sceneView.pointOfView else { return }

            // Check if the user is starting the drag on one of the axes. If so, drag along that axis.
            let hitResults = sceneView.hitTest(screenPos, options: [
                .rootNode: self,
                .boundingBoxOnly: true])
            
            for result in hitResults {
                if let hitAxis = result.node.parent as? ObjectOriginAxis {
                    hitAxis.isHighlighted = true
                    
                    let worldAxis = hitAxis.simdConvertVector(hitAxis.axis.normal, to: nil)
                    let worldPosition = hitAxis.simdConvertVector(float3(0), to: nil)
                    let hitAxisNormalInWorld = normalize(worldAxis - worldPosition)

                    let dragRay = Ray(origin: self.simdWorldPosition, direction: hitAxisNormalInWorld)
                    let transform = dragPlaneTransform(for: dragRay, cameraPos: camera.simdWorldPosition)
                    
                    var offset = float3()
                    if let hitPos = sceneView.unprojectPointLocal(screenPos, ontoPlane: transform) {
                        // Project the result onto the plane's X axis & transform into world coordinates.
                        let posOnPlaneXAxis = float4(hitPos.x, 0, 0, 1)
                        let worldPosOnPlaneXAxis = transform * posOnPlaneXAxis
                        
                        offset = self.simdWorldPosition - worldPosOnPlaneXAxis.xyz
                    }
                    
                    currentAxisDrag = PlaneDrag(planeTransform: transform, offset: offset)
                    positionHasBeenAdjustedByUser = true
                    return
                }
            }
        }
        
        // If no axis was hit, reposition the origin in the XZ-plane.
        let dragPlane = self.simdWorldTransform
        var offset = float3(0)
        if keepOffset, let hitPos = sceneView.unprojectPoint(screenPos, ontoPlane: dragPlane) {
            offset = self.simdWorldPosition - hitPos
        }
        self.currentPlaneDrag = PlaneDrag(planeTransform: dragPlane, offset: offset)
        positionHasBeenAdjustedByUser = true
    }
    
    func updateDrag(screenPos: CGPoint) {
        if let drag = currentPlaneDrag {
            if let hitPos = sceneView.unprojectPoint(screenPos, ontoPlane: drag.planeTransform) {
                self.simdWorldPosition = hitPos + drag.offset
                
                if isOutsideBoundingBox {
                    NotificationCenter.default.post(name: ObjectOrigin.movedOutsideBoxNotification, object: self)
                }
            }
        } else if let drag = currentAxisDrag {
            if let hitPos = sceneView.unprojectPointLocal(screenPos, ontoPlane: drag.planeTransform) {
                // Project the result onto the plane's X axis & transform into world coordinates.
                let posOnPlaneXAxis = float4(hitPos.x, 0, 0, 1)
                let worldPosOnPlaneXAxis = drag.planeTransform * posOnPlaneXAxis

                self.simdWorldPosition = worldPosOnPlaneXAxis.xyz + drag.offset

                if isOutsideBoundingBox {
                    NotificationCenter.default.post(name: ObjectOrigin.movedOutsideBoxNotification, object: self)
                }
            }
        }
    }
    
    func endDrag() {
        currentPlaneDrag = nil
        currentAxisDrag = nil
        xAxis.isHighlighted = false
        yAxis.isHighlighted = false
        zAxis.isHighlighted = false
    }
    
    func flashOrReposition(screenPos: CGPoint) {
        if !isDisplayingCustom3DModel {
            // Check if the user tapped on one of the axes. If so, highlight it.
            let hitResults = sceneView.hitTest(screenPos, options: [
                .rootNode: self,
                .boundingBoxOnly: true])
            
            for result in hitResults {
                if let hitAxis = result.node.parent as? ObjectOriginAxis {
                    hitAxis.flash()
                    return
                }
            }
        }
        
        // If no axis was hit, reposition the origin in the XZ-plane.
        if let hitPos = sceneView.unprojectPoint(screenPos, ontoPlane: self.simdWorldTransform) {
            self.simdWorldPosition = hitPos
            
            if isOutsideBoundingBox {
                NotificationCenter.default.post(name: ObjectOrigin.movedOutsideBoxNotification, object: self)
            }
        }
    }
    
    var isOutsideBoundingBox: Bool {
        guard let boundingBox = self.parent as? BoundingBox else { return true }
        
        let threshold = float3(0.002)
        let extent = boundingBox.extent + threshold
        
        let pos = simdPosition
        return pos.x < -extent.x / 2 || pos.y < -extent.y / 2 || pos.z < -extent.z / 2 ||
            pos.x > extent.x / 2 || pos.y > extent.y / 2 || pos.z > extent.z / 2
    }
    
    @objc
    private func scanningStateChanged(_ notification: Notification) {
        guard let state = notification.userInfo?[Scan.stateUserInfoKey] as? Scan.State else { return }
        switch state {
        case .ready, .defineBoundingBox, .scanning:
            self.isHidden = true
        case .adjustingOrigin:
            self.isHidden = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func isPartOfCustomModel(_ node: SCNNode) -> Bool {
        if node == customModel {
            return true
        }
        
        if let parent = node.parent {
            return isPartOfCustomModel(parent)
        }
        
        return false
    }
}
