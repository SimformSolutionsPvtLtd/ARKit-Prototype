//
//  ARPostureDetection+ARSessionDelegate.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 26/03/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import RealityKit
import ARKit

// MARK: ARSessionDelegate
extension ARPostureDetection: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            /// Return if there is no body det3ected
            guard let bodyAnchor = anchor as? ARBodyAnchor else { return }
            /// Fetch the skeleton from the bodyanchor which will provide all transforms from the joints
            let bodyAnchorTransform = Transform(matrix: bodyAnchor.transform).translation
            meshAnchor.position = bodyAnchorTransform
            let skeleton = bodyAnchor.skeleton
            /// For this usecase we only have to consider "left_leg_joint" & "spine_7_joint"  as we have to find ths sitting posture angle correctly.spine_1_joint
            guard let leftLegJointTransform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "left_leg_joint")),
                  let spine7JointJointTransform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_7_joint"))
            else { return }
            /// Then find the angle between 2 position
            let abc = bodyAnchorTransform + Transform(matrix: leftLegJointTransform).translation
            let xyz = bodyAnchorTransform + Transform(matrix: spine7JointJointTransform).translation
            let angle = SIMD3<Float>.angleBetween(v1: abc, v2: xyz)
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
