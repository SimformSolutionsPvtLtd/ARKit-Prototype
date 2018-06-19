/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Gesture interaction methods for the main view controller.
*/

import UIKit
import SceneKit

extension ScanObjectsVC: UIGestureRecognizerDelegate {
        
    @IBAction func didTap(_ gesture: UITapGestureRecognizer) {
        if state == .scanning {
            scan?.didTap(gesture)
        }
    }
    
    @IBAction func didOneFingerPan(_ gesture: UIPanGestureRecognizer) {
        if state == .scanning {
            scan?.didOneFingerPan(gesture)
        }
    }
    
    @IBAction func didTwoFingerPan(_ gesture: ThresholdPanGestureRecognizer) {
        if state == .scanning {
            scan?.didTwoFingerPan(gesture)
        }
    }
    
    @IBAction func didRotate(_ gesture: ThresholdRotationGestureRecognizer) {
        if state == .scanning {
            scan?.didRotate(gesture)
        }
    }
    
    @IBAction func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        if state == .scanning {
            scan?.didLongPress(gesture)
        }
    }
    
    @IBAction func didPinch(_ gesture: ThresholdPinchGestureRecognizer) {
        if state == .scanning {
            scan?.didPinch(gesture)
        }
    }
    
    func gestureRecognizer(_ first: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith second: UIGestureRecognizer) -> Bool {
        if first is UIRotationGestureRecognizer && second is UIPinchGestureRecognizer {
            return true
        } else if first is UIRotationGestureRecognizer && second is UIPanGestureRecognizer {
            return true
        } else if first is UIPinchGestureRecognizer && second is UIRotationGestureRecognizer {
            return true
        } else if first is UIPinchGestureRecognizer && second is UIPanGestureRecognizer {
            return true
        } else if first is UIPanGestureRecognizer && second is UIPinchGestureRecognizer {
            return true
        } else if first is UIPanGestureRecognizer && second is UIRotationGestureRecognizer {
            return true
        }
        return false
    }
}
