//
//  ARPostureDetection.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 28/02/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import Combine
import SwiftUI

class ARPostureDetection: UIViewController {

    @IBOutlet var arView: ARView!

    // The 3D character to display.
    var meshEntity: ModelEntity?
    var meshAnchor = AnchorEntity()
    var character: BodyTrackedEntity?

    private let labelView: UILabel = {
        let label = UILabel()
        label.text = "Angle"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = UIColor.green
        return label
    }()

    override func viewDidLoad() {
        loadLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self

        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        self.arView.scene.addAnchor(meshAnchor)
    }

    private func loadLabel() {
        arView.addSubview(labelView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -20).isActive = true
        labelView.leadingAnchor.constraint(equalTo: arView.leadingAnchor, constant: 0).isActive = true
        labelView.trailingAnchor.constraint(equalTo: arView.trailingAnchor, constant: 0).isActive = true
        labelView.textAlignment = .center
    }
}

// MARK: ARSessionDelegate
extension ARPostureDetection: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            /// Return if there is no body det3ected
            guard let bodyAnchor = anchor as? ARBodyAnchor else { return }
            /// Fetch the skeleton from the bodyanchor which will provide all transforms from the joints
            meshAnchor.position = Transform(matrix: bodyAnchor.transform).translation
            let skeleton = bodyAnchor.skeleton
            /// For this usecase we only have to consider "left_leg_joint" & "spine_7_joint"  as we have to find ths sitting posture angle correctly.
            guard let leftLegJointTransform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "left_leg_joint")),
                  let spine7JointJointTransform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_7_joint"))
            else { return }
            /// Then find the angle between 2 position
            let angle = SIMD3<Float>.angleBetween(v1: Transform(matrix: leftLegJointTransform).translation,
                                                  v2: Transform(matrix: spine7JointJointTransform).translation)
            //            let angle1 = Transform(matrix: leftLegJointTransform).translation
            //                .angle(v: Transform(matrix: spine7JointJointTransform).translation)
            /// Then convert radian to degree and update the label
            let radToDeg = angle * 180.0 / Float.pi
            DispatchQueue.main.async {
                self.labelView.text = "Angle for posture :- \(Int(radToDeg))"
            }

            /// Align the anchor's orientation with bodynchor's rotataion
            meshAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
            /// FInd out towards which side the face is facing
            let isFacingleft = meshAnchor.orientation.imag.y.isNegative
            /// Reset all orientation to its default
            meshAnchor.setOrientation(simd_quatf(real: 1, imag: [0,0,0]), relativeTo: nil)

            /// If the meshEntity do not have any parent that means meshEntity is not yet added to the anchor
            /// So we need to create an entity and add it to the ARAnchor
            if meshEntity?.parent == nil {
                guard let mesh = MeshResource.createSemiCircleMeshForAngle(angle: (radToDeg), isFacingLeft: isFacingleft) else { return }
                meshEntity = generateEntityFromMesh(mesh: mesh, angle: Int(radToDeg))
                meshAnchor.addChild(meshEntity!)
            }
            /// so now instead of creating whole 2d shape again and again we will just update its mesh
            /// according to the newly updated angle
            else {
                updateSemiCircleMesh(forAngle: Double(radToDeg), modelEntity: meshEntity, isFacingLeft: isFacingleft)
            }
        }
    }
}

/// Used to Generate/Update mesh
extension ARPostureDetection {
    func updateSemiCircleMesh(forAngle: Double, modelEntity: ModelEntity?, isFacingLeft: Bool) {
        guard let entity = modelEntity,
                let mesh = MeshResource.createSemiCircleMeshForAngle(angle: Float(forAngle),
                                                                     isFacingLeft: isFacingLeft) else { return }
        entity.model?.materials[0] = SimpleMaterial(color: Int(forAngle).postureIntensityColor(),
                                                    isMetallic: false)
        entity.model?.mesh = mesh
    }

    func generateEntityFromMesh(mesh: MeshResource, angle: Int) -> ModelEntity {
        let material = SimpleMaterial(color: angle.postureIntensityColor(), isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.setScale([0.35, 0.35, 0.35], relativeTo: nil)
        return entity
    }
}

