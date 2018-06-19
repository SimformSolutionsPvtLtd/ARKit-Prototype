/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom rotation gesture reconizer that fires only when a threshold is passed.
*/
import UIKit.UIGestureRecognizerSubclass

class ThresholdRotationGestureRecognizer: UIRotationGestureRecognizer {
    
    /// The threshold after which this gesture is detected.
    private static let threshold: CGFloat = .pi / 15 // (12°)
    
    /// Indicates whether the currently active gesture has exceeeded the threshold.
    private(set) var isThresholdExceeded = false
    
    var previousRotation: CGFloat = 0
    var rotationDelta: CGFloat = 0
    
    /// Observe when the gesture's `state` changes to reset the threshold.
    override var state: UIGestureRecognizer.State {
        didSet {
            switch state {
            case .began, .changed:
                break
            default:
                // Reset threshold check.
                isThresholdExceeded = false
                previousRotation = 0
                rotationDelta = 0
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if isThresholdExceeded {
            rotationDelta = rotation - previousRotation
            previousRotation = rotation
        }
        
        if !isThresholdExceeded && abs(rotation) > ThresholdRotationGestureRecognizer.threshold {
            isThresholdExceeded = true
            previousRotation = rotation
        }
    }
}
