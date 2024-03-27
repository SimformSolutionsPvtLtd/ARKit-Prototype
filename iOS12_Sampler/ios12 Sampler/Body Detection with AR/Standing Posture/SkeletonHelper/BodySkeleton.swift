//
//  BodySkeleton.swift
//  BodyDetection
//
//  Created by Dhruvil Vora on 04/03/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import RealityKit
import ARKit

class BodySkeleton: Entity {

    private var joints: [String: Entity] = [:]
    private var customBones: [String: Entity] = [:]
    var customLabels: [String: ModelEntity] = [:]

    required init(bodyEntity: ARBodyAnchor) {
        super.init()
        /// get the position of root(hip) joint
        let hipPosition = Transform(matrix: bodyEntity.transform).translation
        /// Loop for creating joints
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            ///  get the position of joint
            let jointModelTransform = bodyEntity.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName))!
//            let bodyOrientation = Transform(matrix: jointModelTransform).rotation
            /// Now here when we get the translation of the joint it's actually is not the world position of that joint
            /// It's actually the offset of that joint from the root joint
            let jointModelOffset = Transform(matrix: jointModelTransform).translation
            /// So inorder to get the actual world position of the joint we need to add hip's position & joint's offset
            let jointPosition = hipPosition + jointModelOffset
//            let rotatedJointTransform = bodyOrientation.act(jointPosition)
            /// We can now create and place entity in the required position
            let updatedRadiiAndColor = setMeshEntityAccordingToJoints(jointName: jointName, jointRadius: 0.03)
            let sphereEntity = makeSphereEntity(radius: updatedRadiiAndColor.radius, color: updatedRadiiAndColor.color, 
                                                position: jointPosition, showAngle: jointName.isJointFromLegOrhand, 
                                                jointName: jointName, bodyEntity: bodyEntity)
            self.addChild(sphereEntity)
            /// Add joints to the dict as we afterwards also wants to update them
            joints[jointName] = sphereEntity
        }
        /// Loop for creating Bones
        for bone in Bones.allCases {
            constructBoneEntity(bodyEntity: bodyEntity, customBone: bone)
        }
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    private func constructBoneEntity(bodyEntity: ARBodyAnchor, customBone: Bones) {
        guard let jointsBone = constructSkeletonBone(customBone: customBone, bodyEntity: bodyEntity) else { return }
        let boneEntity = makeBoneEntity(skeletonBone: jointsBone)
        self.addChild(boneEntity)
        boneEntity.look(at: jointsBone.toJoint.position, from: jointsBone.centerPoint, relativeTo: nil)
        /// Add joints to the dict as we afterwards also wants to update them
        customBones[customBone.name] = boneEntity
    }

    func updateTrackedBodyAnchor(bodyEntity: ARBodyAnchor) {
        /// get the position of root(hip) joint
        let hipPosition = Transform(matrix: bodyEntity.transform).translation
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {

            ///  get the position of joint
            let jointModelTransform = bodyEntity.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName))!

            let bodyOrientation = Transform(matrix: jointModelTransform).rotation
            /// Now here when we get the translation of the joint it's actually is not the world position of that joint
            /// It's actually the offset of that joint from the root joint
            let jointModelOffset = Transform(matrix: jointModelTransform).translation
            /// So inorder to get the actual world position of the joint we need to add hip's position & joint's offset
            let jointPosition = hipPosition + jointModelOffset // bodyOrientation.act(jointModelOffset)
//            let rotatedJointTransform = bodyOrientation.act(jointPosition)
            guard let jointToUpdate = joints[jointName] else { continue }
            jointToUpdate.transform.translation = jointPosition
            guard let jointLabelToUpdate = customLabels[jointName] else { continue }
            let angle = calculateRespectedJointAngles(jointName: jointName, parentEntity: jointToUpdate, bodyEntity: bodyEntity)
            jointLabelToUpdate.model?.mesh = MeshResource.generateText("\(angle)")
        }
        updateCustomBones(bodyEntity: bodyEntity)
    }

    private func updateCustomBones(bodyEntity: ARBodyAnchor) {
        for customBone in Bones.allCases {
            guard let jointsBone = constructSkeletonBone(customBone: customBone, bodyEntity: bodyEntity),
                    let boneEntity = customBones[customBone.name] else { return }
            boneEntity.transform.translation = jointsBone.centerPoint
            boneEntity.look(at: jointsBone.toJoint.position, from: jointsBone.centerPoint, relativeTo: nil)
            /// Add joints to the dict as we afterwards also wants to update them according to the ARBodyAnchor
            customBones[customBone.name] = boneEntity
        }
    }
}
