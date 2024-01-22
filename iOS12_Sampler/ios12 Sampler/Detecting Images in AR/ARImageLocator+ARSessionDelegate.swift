//
//  ARImageLocator+ARSessionDelegate.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 11/01/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import ARKit

extension ARImageLocator: ARSessionDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        /// Notify users about current tracking camera quality
        statusViewController.showCameraQualityInfo(trackingState: camera.trackingState, autoHide: true)

        switch camera.trackingState {
        case .notAvailable:
            statusViewController.showRecommendationForCameraQuality(trackingState: camera.trackingState,
                                                                    duration: 3, autoHide: false)
        default:
            break
        }
    }

}
