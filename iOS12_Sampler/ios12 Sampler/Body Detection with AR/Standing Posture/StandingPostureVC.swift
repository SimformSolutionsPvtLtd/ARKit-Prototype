//
//  StandingPostureVC.swift
//  BodyDetection
//
//  Created by Dhruvil Vora on 04/03/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import UIKit
import RealityKit
import ARKit
import Combine

class StandingPostureVC: UIViewController {

    // MARK: IBOutlets
    @IBOutlet var arView: ARView!

    // MARK: Variables
    private var bodyEntity: BodySkeleton?
    private var character: Entity?
    private var anchorSkeletonEntity = AnchorEntity()
    private var cancellable: AnyCancellable? = nil

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        configureARBodyTracking()
    }
}

extension StandingPostureVC {
    func configureARBodyTracking() {
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        arView.session.delegate = self
        arView.scene.addAnchor(anchorSkeletonEntity)
    }
}

extension StandingPostureVC: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            if let entity = bodyEntity {
                entity.updateTrackedBodyAnchor(bodyEntity: bodyAnchor)
//                let position = Transform(matrix: bodyAnchor.transform).translation
//                entity.look(at: position, from: position, relativeTo: nil)
            } else {
                bodyEntity = BodySkeleton(bodyEntity: bodyAnchor)
                guard let bodyTrackedEntity = bodyEntity else { continue }
                anchorSkeletonEntity.addChild(bodyTrackedEntity)
            }
        }
    }
}
