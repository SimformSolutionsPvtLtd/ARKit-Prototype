/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages the process of testing detection after scanning an object.
*/

import Foundation
import ARKit

// This class represents a test run of a scanned object.
class TestRun {
    
    // The ARReferenceObject to be tested in this run.
    var referenceObject: ARReferenceObject?
    
    private(set) var detectedObject: DetectedObject?
    
    var detections = 0
    var lastDetectionDelayInSeconds: Double = 0
    var averageDetectionDelayInSeconds: Double = 0
    
    var resultDisplayDuration: Double {
        // The recommended display duration for detection results
        // is the average time it takes to detect it, plus 200 ms buffer.
        return averageDetectionDelayInSeconds + 0.2
    }
    
    private var lastDetectionStartTime: Date?
    
    private var sceneView: ARSCNView
    
    private(set) var previewImage = UIImage()
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    deinit {
        self.detectedObject?.removeFromParentNode()
        
        if self.sceneView.session.configuration as? ARWorldTrackingConfiguration != nil {
            // Make sure we switch back to an object scanning configuration & no longer
            // try to detect the object.
            let configuration = ARObjectScanningConfiguration()
            configuration.planeDetection = .horizontal
            self.sceneView.session.run(configuration, options: .resetTracking)
        }
    }
    
    var statistics: String {
        let lastDelayMilliseconds = String(format: "%.0f", lastDetectionDelayInSeconds * 1000)
        let averageDelayMilliseconds = String(format: "%.0f", averageDetectionDelayInSeconds * 1000)
        return "Detected after: \(lastDelayMilliseconds) ms. Avg: \(averageDelayMilliseconds) ms"
    }
    
    func setReferenceObject(_ object: ARReferenceObject, screenshot: UIImage) {
        referenceObject = object
        previewImage = screenshot
        detections = 0
        lastDetectionDelayInSeconds = 0
        averageDetectionDelayInSeconds = 0
        
        self.detectedObject = DetectedObject(referenceObject: object)
        ScanObjectsVC.serialQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.detectedObject!)
        }
        
        self.lastDetectionStartTime = Date()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionObjects = [object]
        self.sceneView.session.run(configuration)
    }
    
    func successfulDetection(_ objectAnchor: ARObjectAnchor) {
        
        // Compute the time it took to detect this object & the average.
        lastDetectionDelayInSeconds = Date().timeIntervalSince(self.lastDetectionStartTime!)
        detections += 1
        averageDetectionDelayInSeconds = (averageDetectionDelayInSeconds * Double(detections - 1) + lastDetectionDelayInSeconds) / Double(detections)
        
        // Update the detected object's display duration
        self.detectedObject?.displayDuration = resultDisplayDuration
        
        // Immediately remove the anchor from the session again to force a re-detection.
        self.lastDetectionStartTime = Date()
        self.sceneView.session.remove(anchor: objectAnchor)
        
        if let currentPointCloud = self.sceneView.session.currentFrame?.rawFeaturePoints {
            self.detectedObject?.updateVisualization(newTransform: objectAnchor.transform,
                                                     currentPointCloud: currentPointCloud)
        }
    }
    
    func updateOnEveryFrame() {
        if let detectedObject = self.detectedObject {
            ScanObjectsVC.serialQueue.async {
                if let currentPointCloud = self.sceneView.session.currentFrame?.rawFeaturePoints {
                    detectedObject.updatePointCloud(currentPointCloud)
                }
            }
        }
    }
}
