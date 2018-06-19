/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages the major steps in scanning an object.
*/

import Foundation
import UIKit
import ARKit

class Scan {
    
    static let stateChangedNotification = Notification.Name("ScanningStateChanged")
    static let stateUserInfoKey = "ScanState"
    
    enum State {
        case ready
        case defineBoundingBox
        case scanning
        case adjustingOrigin
    }
    
    // The current state the scan is in
    private var stateValue: State = .ready
    var state: State {
        get {
            return stateValue
        }
        set {
            // Check that preconditions for the state change are met.
            switch newValue {
            case .ready:
                break
            case .defineBoundingBox where !boundingBoxExists && !ghostBoundingBoxExists:
                print("Error: Ghost bounding box not yet created.")
                return
            case .scanning where !boundingBoxExists, .adjustingOrigin where !boundingBoxExists:
                print("Error: Bounding box not yet created.")
                return
            case .scanning where stateValue == .defineBoundingBox && !isReasonablySized,
                 .adjustingOrigin where stateValue == .scanning && !isReasonablySized:
                
                let title = "Scanned object too big or small"
                let message = """
                Each dimension of the bounding box should be at least 1 centimeters and not exceed 5 meters.
                In addition, the volume of the bounding box should be at least 500 cubic cm.
                Do you want to go back and adjust the bounding box of the scanned object?
                """
                let previousState = stateValue
                ScanObjectsVC.instance?.showAlert(title: title, message: message, buttonTitle: "Yes", showCancel: true) { _ in
                    self.state = previousState
                }
            case .scanning:
                // When entering the scanning state, take a screenshot of the object to be scanned.
                // This screenshot will later be saved in the *.arobject file
                createScreenshot()
            case .adjustingOrigin where stateValue == .scanning && qualityIsLow:
                let title = "Not enough detail"
                let message = """
                This scan has not enough detail. It is unlikely that a good reference object can be generated.
                Do you want to go back and continue the scan?
                """
                ScanObjectsVC.instance?.showAlert(title: title, message: message, buttonTitle: "Yes", showCancel: true) { _ in
                    self.state = .scanning
                }
            case .adjustingOrigin where stateValue == .scanning:
                if let boundingBox = scannedObject.boundingBox, boundingBox.progressPercentage < 100 {
                    let title = "Scan not complete"
                    let message = """
                    The object was not scanned from all sides, scanning progress is \(boundingBox.progressPercentage)%.
                    It is likely that it won't detect from all angles.
                    Do you want to go back and continue the scan?
                    """
                    ScanObjectsVC.instance?.showAlert(title: title, message: message, buttonTitle: "Yes", showCancel: true) { _ in
                        self.state = .scanning
                    }
                }
            default:
                break
            }
            // Apply the new state
            stateValue = newValue

            NotificationCenter.default.post(name: Scan.stateChangedNotification,
                                            object: self,
                                            userInfo: [Scan.stateUserInfoKey: self.state])
        }
    }
    
    // The object which we want to scan
    private(set) var scannedObject: ScannedObject
    
    // The result of this scan, an ARReferenceObject
    private(set) var scannedReferenceObject: ARReferenceObject?
    
    // The node for visualizing the point cloud.
    private(set) var pointCloud: ScannedPointCloud
    
    private var sceneView: ARSCNView
    
    private var isBusyCreatingReferenceObject = false
    
    private(set) var screenshot = UIImage()
    
    private var hasWarnedAboutLowLight = false
    
    init(_ sceneView: ARSCNView) {
        self.sceneView = sceneView
        
        scannedObject = ScannedObject(sceneView)
        pointCloud = ScannedPointCloud()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationStateChanged(_:)),
                                               name: ScanObjectsVC.appStateChangedNotification,
                                               object: nil)
        
        ScanObjectsVC.serialQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.scannedObject)
            self.sceneView.scene.rootNode.addChildNode(self.pointCloud)
        }
    }
    
    deinit {
        self.scannedObject.removeFromParentNode()
        self.pointCloud.removeFromParentNode()
    }
    
    @objc
    private func applicationStateChanged(_ notification: Notification) {
        guard let appState = notification.userInfo?[ScanObjectsVC.appStateUserInfoKey] as? ScanObjectsVC.State else { return }
        switch appState {
        case .scanning:
            scannedObject.isHidden = false
            pointCloud.isHidden = false
        default:
            scannedObject.isHidden = true
            pointCloud.isHidden = true
        }
    }
    
    func didOneFingerPan(_ gesture: UIPanGestureRecognizer) {
        if state == .ready {
            state = .defineBoundingBox
        }
        
        if state == .defineBoundingBox || state == .scanning {
            switch gesture.state {
            case .possible:
                break
            case .began:
                scannedObject.boundingBox?.startAxisOrPlaneDrag(screenPos: gesture.location(in: sceneView))
            case .changed:
                scannedObject.boundingBox?.updateAxisOrPlaneDrag(screenPos: gesture.location(in: sceneView))
            case .failed, .cancelled, .ended:
                scannedObject.boundingBox?.endAxisOrPlaneDrag()
            }
        } else if state == .adjustingOrigin {
            switch gesture.state {
            case .possible:
                break
            case .began:
                scannedObject.origin?.startDrag(screenPos: gesture.location(in: sceneView), keepOffset: true)
            case .changed:
                scannedObject.origin?.updateDrag(screenPos: gesture.location(in: sceneView))
            case .failed, .cancelled, .ended:
                scannedObject.origin?.endDrag()
            }
        }
    }
    
    func didTwoFingerPan(_ gesture: ThresholdPanGestureRecognizer) {
        if state == .ready {
            state = .defineBoundingBox
        }
        
        if state == .defineBoundingBox || state == .scanning {
            switch gesture.state {
            case .possible:
                break
            case .began:
                if gesture.numberOfTouches == 2 {
                    scannedObject.boundingBox?.startPlaneDrag(screenPos: gesture.location(in: sceneView), keepOffset: true)
                }
            case .changed where gesture.isThresholdExceeded:
                if gesture.numberOfTouches == 2 {
                    scannedObject.boundingBox?.updatePlaneDrag(screenPos: gesture.location(in: sceneView))
                }
            case .changed:
                break
            case .failed, .cancelled, .ended:
                scannedObject.boundingBox?.endPlaneDrag()
            }
        } else if state == .adjustingOrigin {
            switch gesture.state {
            case .possible:
                break
            case .began:
                if gesture.numberOfTouches == 2 {
                    scannedObject.origin?.startDrag(screenPos: gesture.location(in: sceneView), keepOffset: true)
                }
            case .changed where gesture.isThresholdExceeded:
                if gesture.numberOfTouches == 2 {
                    scannedObject.origin?.updateDrag(screenPos: gesture.location(in: sceneView))
                }
            case .changed:
                break
            case .failed, .cancelled, .ended:
                scannedObject.origin?.endDrag()
            }
        }
    }
    
    func didRotate(_ gesture: ThresholdRotationGestureRecognizer) {
        if state == .ready {
            state = .defineBoundingBox
        }
        
        if state == .defineBoundingBox || state == .scanning {
            if gesture.state == .changed {
                scannedObject.rotateOnYAxis(by: -Float(gesture.rotationDelta))
            }
        } else if state == .adjustingOrigin {
            if gesture.state == .changed {
                scannedObject.origin?.simdLocalRotate(by: simd_quatf(angle: -Float(gesture.rotationDelta), axis: .y))
            }
        }
    }
    
    func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        if state == .ready {
            state = .defineBoundingBox
        }
        
        if state == .defineBoundingBox || state == .scanning {
            switch gesture.state {
            case .possible:
                break
            case .began:
                scannedObject.boundingBox?.startSideDrag(screenPos: gesture.location(in: sceneView))
            case .changed:
                scannedObject.boundingBox?.updateSideDrag(screenPos: gesture.location(in: sceneView))
            case .failed, .cancelled, .ended:
                scannedObject.boundingBox?.endSideDrag()
            }
        } else if state == .adjustingOrigin {
            switch gesture.state {
            case .possible:
                break
            case .began:
                scannedObject.origin?.startDrag(screenPos: gesture.location(in: sceneView), keepOffset: true)
            case .changed:
                scannedObject.origin?.updateDrag(screenPos: gesture.location(in: sceneView))
            case .failed, .cancelled, .ended:
                scannedObject.origin?.endDrag()
            }
        }
    }
    
    func didTap(_ gesture: UITapGestureRecognizer) {
        if state == .ready {
            state = .defineBoundingBox
        }
        
        if state == .defineBoundingBox || state == .scanning {
            if gesture.state == .ended {
                scannedObject.createOrMoveBoundingBox(screenPos: gesture.location(in: sceneView))
            }
        } else if state == .adjustingOrigin {
            if gesture.state == .ended {
                scannedObject.origin?.flashOrReposition(screenPos: gesture.location(in: sceneView))
            }
        }
    }
    
    func didPinch(_ gesture: ThresholdPinchGestureRecognizer) {
        if state == .ready {
            state = .defineBoundingBox
        }
        
        if state == .defineBoundingBox || state == .scanning {
            switch gesture.state {
            case .possible, .began:
                break
            case .changed where gesture.isThresholdExceeded:
                scannedObject.scaleBoundingBox(scale: gesture.scale)
                gesture.scale = 1
            case .changed:
                break
            case .failed, .cancelled, .ended:
                break
            }
        } else if state == .adjustingOrigin {
            switch gesture.state {
            case .possible, .began:
                break
            case .changed where gesture.isThresholdExceeded:
                scannedObject.scaleOrigin(scale: gesture.scale)
                gesture.scale = 1
            case .changed, .failed, .cancelled, .ended:
                break
            }
        }
    }
    
    func updateOnEveryFrame(_ frame: ARFrame) {
        if state == .ready || state == .defineBoundingBox {
            if let points = frame.rawFeaturePoints {
                // Automatically adjust the size of the bounding box.
                self.scannedObject.fitOverPointCloud(points)
            }
        }
        
        if state == .ready || state == .defineBoundingBox || state == .scanning {
            
            if let lightEstimate = frame.lightEstimate, lightEstimate.ambientIntensity < 500, !hasWarnedAboutLowLight {
                hasWarnedAboutLowLight = true
                let title = "Too dark for scanning"
                let message = "Consider moving to an environment with more light."
                ScanObjectsVC.instance?.showAlert(title: title, message: message)
            }
            
            // Try a preliminary creation of the reference object based off the current
            // bounding box & update the point cloud visualization based on that.
            if let boundingBox = scannedObject.eitherBoundingBox {
                // Note: Creating the reference object is asynchronous and likely
                //       takes some time to complete. Avoid calling it again while we
                //       still wait for the previous call to complete.
                if !isBusyCreatingReferenceObject {
                    isBusyCreatingReferenceObject = true
                    sceneView.session.createReferenceObject(transform: boundingBox.simdWorldTransform,
                                                            center: float3(),
                                                            extent: boundingBox.extent) { object, error in
                        if let referenceObject = object {
                            // Pass the feature points to the point cloud visualization.
                            self.pointCloud.update(referenceObject.rawFeaturePoints, for: boundingBox)
                        }
                        self.isBusyCreatingReferenceObject = false
                    }
                }
            }
        }
        
        // Update bounding box side coloring to visualize scanning coverage
        if state == .scanning {
            scannedObject.boundingBox?.highlightCurrentTile()
            scannedObject.boundingBox?.updateCapturingProgress()
        }
        
        scannedObject.updateOnEveryFrame()
        pointCloud.updateOnEveryFrame()
    }
    
    var qualityIsLow: Bool {
        return pointCloud.count < 100
    }
    
    var boundingBoxExists: Bool {
        return scannedObject.boundingBox != nil
    }
    
    var ghostBoundingBoxExists: Bool {
        return scannedObject.ghostBoundingBox != nil
    }
    
    var isReasonablySized: Bool {
        guard let boundingBox = scannedObject.boundingBox else {
            return false
        }
        
        // The bounding box should not be too small and not too large.
        // Note: 3D object detection is optimized for tabletop scenarios.
        let validSizeRange: ClosedRange<Float> = 0.01...5.0
        if validSizeRange.contains(boundingBox.extent.x) && validSizeRange.contains(boundingBox.extent.y) &&
            validSizeRange.contains(boundingBox.extent.z) {
            // Check that the volume of the bounding box is at least 500 cubic centimeters.
            let volume = boundingBox.extent.x * boundingBox.extent.y * boundingBox.extent.z
            return volume >= 0.0005
        }
        
        return false
    }
    
    /// - Tag: ExtractReferenceObject
    func createReferenceObject(completionHandler creationFinished: @escaping (ARReferenceObject?) -> Void) {
        guard let boundingBox = scannedObject.boundingBox, let origin = scannedObject.origin else {
            print("Error: No bounding box or object origin present.")
            creationFinished(nil)
            return
        }
        
        // Extract the reference object based on the position & orientation of the bounding box.
        sceneView.session.createReferenceObject(
            transform: boundingBox.simdWorldTransform,
            center: float3(), extent: boundingBox.extent,
            completionHandler: { object, error in
                if let referenceObject = object {
                    // Adjust the object's origin with the user-provided transform.
                    self.scannedReferenceObject =
                        referenceObject.applyingTransform(origin.simdTransform)
                    self.scannedReferenceObject!.name = self.scannedObject.scanName
                    creationFinished(self.scannedReferenceObject)
                } else {
                    print("Error: Failed to create reference object. \(error!.localizedDescription)")
                    creationFinished(nil)
                }
        })
    }
    
    private func createScreenshot() {
        guard let frame = self.sceneView.session.currentFrame else {
            print("Error: Failed to create a screenshot - no current ARFrame exists.")
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: frame.capturedImage)
        let context = CIContext()
        if let cgimage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width:
            frame.camera.imageResolution.width, height: frame.camera.imageResolution.height)) {
            screenshot = UIImage(cgImage: cgimage, scale: 1.0, orientation: .right)
        }
    }
}
