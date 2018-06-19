/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A visualization of the 3D point cloud data during object scanning.
*/

import Foundation
import ARKit
import SceneKit

class ScannedPointCloud: SCNNode, PointCloud {
    
    private var pointNode = SCNNode()
    
    // The latest known set of points inside the reference object.
    private var referenceObjectPoints: [float3] = []
    
    // The set of currently rendered points, in world coordinates.
    // Note: We render them in world coordinates instead of local coordinates to
    //       prevent rendering issues with points jittering e.g. when the
    //       bounding box is rotated.
    private var renderedPoints: [float3] = []
    
    private var boundingBox: BoundingBox?
    
    override init() {
        super.init()
        
        addChildNode(pointNode)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.scanningStateChanged(_:)),
                                               name: Scan.stateChangedNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.boundingBoxPositionOrExtentChanged(_:)),
                                               name: BoundingBox.extentChangedNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.boundingBoxPositionOrExtentChanged(_:)),
                                               name: BoundingBox.positionChangedNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.scannedObjectPositionChanged(_:)),
                                               name: ScannedObject.positionChangedNotification,
                                               object: nil)
    }
    
    @objc
    func boundingBoxPositionOrExtentChanged(_ notification: Notification) {
        guard let boundingBox = notification.object as? BoundingBox else { return }
        updateBoundingBox(boundingBox)
    }
    
    @objc
    func scannedObjectPositionChanged(_ notification: Notification) {
        guard let scannedObject = notification.object as? ScannedObject else { return }
        let boundingBox = scannedObject.boundingBox != nil ? scannedObject.boundingBox : scannedObject.ghostBoundingBox
        updateBoundingBox(boundingBox)
    }
    
    func updateBoundingBox(_ boundingBox: BoundingBox?) {
        ScanObjectsVC.serialQueue.async {
            self.boundingBox = boundingBox
        }
    }
    
    func update(_ pointCloud: ARPointCloud, for boundingBox: BoundingBox) {
        // Convert the points to world coordinates because we display them
        // in world coordinates.
        var pointsInWorld: [float3] = []
        for point in pointCloud.points {
            pointsInWorld.append(boundingBox.simdConvertPosition(point, to: nil))
        }
        
        ScanObjectsVC.serialQueue.async {
            self.referenceObjectPoints = pointsInWorld
        }
    }
    
    func updateOnEveryFrame() {
        guard !self.isHidden else { return }
        guard !referenceObjectPoints.isEmpty, let boundingBox = boundingBox else {
            self.pointNode.geometry = nil
            return
        }
        
        renderedPoints = []
        
        let min = -boundingBox.extent / 2
        let max = boundingBox.extent / 2
        
        // Abort if the bounding box has no extent yet
        guard max.x > 0 else { return }
        
        // Check which of the reference object's points are still within the bounding box.
        // Note: The creation of the latest ARReferenceObject happens at a lower frequency
        //       than rendering and updates of the bounding box, so some of the points
        //       may no longer be inside of the box.
        for point in referenceObjectPoints {
            let localPoint = boundingBox.simdConvertPosition(point, from: nil)
            if (min.x..<max.x).contains(localPoint.x) &&
                (min.y..<max.y).contains(localPoint.y) &&
                (min.z..<max.z).contains(localPoint.z) {
                renderedPoints.append(point)
            }
        }
        
        self.pointNode.geometry = createVisualization(for: renderedPoints, color: .appYellow, size: 12)
    }
    
    var count: Int {
        return renderedPoints.count
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func scanningStateChanged(_ notification: Notification) {
        guard let state = notification.userInfo?[Scan.stateUserInfoKey] as? Scan.State else { return }
        switch state {
        case .ready, .scanning, .defineBoundingBox:
            self.isHidden = false
        case .adjustingOrigin:
            self.isHidden = true
        }
    }
}
