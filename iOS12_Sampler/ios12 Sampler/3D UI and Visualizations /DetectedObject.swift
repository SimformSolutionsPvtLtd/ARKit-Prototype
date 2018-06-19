/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A visualization of a detected object, using either a loaded 3D asset or a simple bounding box.
*/

import Foundation
import ARKit
import SceneKit

class DetectedObject: SCNNode {
    
    var displayDuration: TimeInterval = 1.0 // How long this visualization is displayed in seconds after an update
    
    private var detectedObjectVisualizationTimer: Timer?
    
    private let pointCloudVisualization: DetectedPointCloud
    
    private var boundingBox: DetectedBoundingBox?
    
    private var originVis: SCNNode
    private var customModel: SCNNode?
    
    private let referenceObject: ARReferenceObject
    
    func set3DModel(_ url: URL?) {
        if let url = url, let model = load3DModel(from: url) {
            customModel?.removeFromParentNode()
            customModel = nil
            originVis.removeFromParentNode()
            ScanObjectsVC.instance?.sceneView.prepare([model], completionHandler: { _ in
                self.addChildNode(model)
            })
            customModel = model
            pointCloudVisualization.isHidden = true
            boundingBox?.isHidden = true
        } else {
            customModel?.removeFromParentNode()
            customModel = nil
            addChildNode(originVis)
            pointCloudVisualization.isHidden = false
            boundingBox?.isHidden = false
        }
    }
    
    init(referenceObject: ARReferenceObject) {
        self.referenceObject = referenceObject
        pointCloudVisualization = DetectedPointCloud(referenceObjectPointCloud: referenceObject.rawFeaturePoints,
                                                     center: referenceObject.center, extent: referenceObject.extent)
        
        if let scene = SCNScene(named: "axes.scn", inDirectory: "art.scnassets") {
            originVis = SCNNode()
            for child in scene.rootNode.childNodes {
                originVis.addChildNode(child)
            }
        } else {
            originVis = SCNNode()
            print("Error: Coordinate system visualization missing.")
        }
        
        super.init()
        addChildNode(pointCloudVisualization)
        isHidden = true
        
        set3DModel(ScanObjectsVC.instance?.modelURL)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateVisualization(newTransform: float4x4, currentPointCloud: ARPointCloud) {
        // Update the transform
        self.simdTransform = newTransform
        
        // Update the point cloud visualization
        updatePointCloud(currentPointCloud)
        
        if boundingBox == nil {
            let scale = CGFloat(referenceObject.scale.x)
            let boundingBox = DetectedBoundingBox(points: referenceObject.rawFeaturePoints.points, scale: scale)
            boundingBox.isHidden = customModel != nil
            addChildNode(boundingBox)
            self.boundingBox = boundingBox
        }
        
        // This visualization should only displayed for displayDuration seconds on every update.
        self.detectedObjectVisualizationTimer?.invalidate()
        self.isHidden = false
        self.detectedObjectVisualizationTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { _ in
            self.isHidden = true
        }
    }
    
    func updatePointCloud(_ currentPointCloud: ARPointCloud) {
        pointCloudVisualization.updateVisualization(for: currentPointCloud)
    }
}
