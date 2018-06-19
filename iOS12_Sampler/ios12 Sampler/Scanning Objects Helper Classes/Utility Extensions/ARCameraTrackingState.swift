/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Presentation information about the current tracking state.
*/

import Foundation
import ARKit

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "ARKit tracking UNAVAILABLE"
        case .normal:
            return "ARKit tracking NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "ARKit tracking LIMITED: Excessive motion"
            case .insufficientFeatures:
                return "ARKit tracking LIMITED: Low detail"
            case .initializing:
                return "ARKit is initializing"
            case .relocalizing:
                return "ARKit is relocalizing"
            }
        }
    }
    
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        case .limited(.initializing):
            return "Try moving left or right, or reset the session."
        case .limited(.relocalizing):
            return "Try returning to the location where you left off."
        default:
            return nil
        }
    }
}
