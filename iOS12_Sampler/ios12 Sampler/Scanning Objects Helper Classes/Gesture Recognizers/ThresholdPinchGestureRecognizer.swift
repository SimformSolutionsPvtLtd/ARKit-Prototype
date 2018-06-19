/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom pinch gesture reconizer that fires only when a threshold is passed.
*/

import UIKit.UIGestureRecognizerSubclass

class ThresholdPinchGestureRecognizer: UIPinchGestureRecognizer {
    
    /// The threshold in screen pixels after which this gesture is detected.
    private static let threshold: CGFloat = 50
    
    /// Indicates whether the currently active gesture has exceeeded the threshold.
    private(set) var isThresholdExceeded = false
    
    var initialTouchDistance: CGFloat = 0
    
    /// Observe when the gesture's `state` changes to reset the threshold.
    override var state: UIGestureRecognizer.State {
        didSet {
            switch state {
            case .began, .changed:
                break
            default:
                // Reset threshold check.
                isThresholdExceeded = false
            }
        }
    }
    
    func touchDistance(from touches: Set<UITouch>) -> CGFloat {
        guard touches.count == 2 else {
            return 0
        }
        
        var points: [CGPoint] = []
        for touch in touches {
            points.append(touch.location(in: view))
        }
        let distance = sqrt((points[0].x - points[1].x) * (points[0].x - points[1].x) + (points[0].y - points[1].y) * (points[0].y - points[1].y))
        return distance
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard touches.count == 2 else {
            return
        }
        
        super.touchesMoved(touches, with: event)
        
        switch state {
        case .began:
            initialTouchDistance = touchDistance(from: touches)
        case .changed:
            let touchDistance = self.touchDistance(from: touches)
            if abs(touchDistance - initialTouchDistance) > ThresholdPinchGestureRecognizer.threshold {
                isThresholdExceeded = true
            }
        default:
            break
        }
        
        if !isThresholdExceeded {
            scale = 1.0
        }
    }
}
