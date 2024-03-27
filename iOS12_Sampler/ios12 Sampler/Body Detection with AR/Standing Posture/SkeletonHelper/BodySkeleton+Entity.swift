//
//  BodySkeleton+Entity.swift
//  BodyDetection
//
//  Created by Dhruvil Vora on 14/03/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import ARKit
import RealityKit

// Use to create Joints and Bones
extension BodySkeleton {

    func constructSkeletonBone(customBone: Bones, bodyEntity: ARBodyAnchor) -> SkeletonBone? {
        let hipPosition = Transform(matrix: bodyEntity.transform).translation
        let fromBone = customBone.jointFromName
        let toBone = customBone.jointToName

        guard let fromJointModelTransform = bodyEntity.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: fromBone)),
              let toJointModelTransform = bodyEntity.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: toBone)) else { return nil }
        let fromJointOffset = Transform(matrix: fromJointModelTransform).translation + hipPosition
        let toJointOffset = Transform(matrix: toJointModelTransform).translation + hipPosition
        return SkeletonBone(fromJoint: SkeletonJoint(name: fromBone, position: fromJointOffset),
                            toJoint: SkeletonJoint(name: toBone, position: toJointOffset))
    }

    func makeSphereEntity(radius: Float, color: UIColor, position: SIMD3<Float>, showAngle: Bool, jointName: String, bodyEntity: ARBodyAnchor) -> ModelEntity {
        let sphereEntity = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
//        material.baseColor = try! .texture(TextureResource.load(named: "texture.png"))
        let dummyEntity = ModelEntity(mesh: sphereEntity, materials: [material])
        dummyEntity.transform.translation = position
        if showAngle {
            addLabelEntityToJoints(jointName: jointName, parentEntity: dummyEntity, bodyEntity: bodyEntity)
        }
        return dummyEntity
    }

    func makeBoneEntity(skeletonBone: SkeletonBone, diameter: Float = 0.04, color: UIColor = .white) -> ModelEntity {
        let cylinderEntity = MeshResource.generateBox(width: diameter, height: diameter, depth: skeletonBone.length, cornerRadius: diameter)
        let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
        let entity = ModelEntity(mesh: cylinderEntity, materials: [material])
        return entity
    }

    private func addLabelEntityToJoints(jointName: String, parentEntity: Entity, bodyEntity: ARBodyAnchor) {
        let angle = calculateRespectedJointAngles(jointName: jointName, parentEntity: parentEntity, bodyEntity: bodyEntity)
        let labelEntity = makeLabelEntity(parentEntity: parentEntity, text: "\(angle)")
        parentEntity.addChild(labelEntity)
        customLabels[jointName] = labelEntity
    }

    private func makeLabelEntity(parentEntity: Entity, text: String = "Data", color: UIColor = .red) -> ModelEntity {
        let labelEntity = MeshResource.generateText(text)
        let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
        let entity = ModelEntity(mesh: labelEntity, materials: [material])
        entity.setPosition(parentEntity.position, relativeTo: nil)
        entity.setScale([0.01, 0.01, 0.01], relativeTo: nil)
        return entity
    }

    func setMeshEntityAccordingToJoints(jointName: String, jointRadius: Float) -> (radius: Float, color: UIColor){
        var updatedJointRadius: Float = 0.03
        var updatedJointColor: UIColor = .green
        switch jointName {
        case "neck_1_joint", "neck_2_joint", "neck_3_joint", "neck_4_joint", "head_joint", "left_shoulder_1_joint", "right_shoulder_1_joint" :
            updatedJointRadius *= 0.5
        case "jaw_joint", "chin_joint", "left_eye_joint", "left_eyeLowerLid_joint", "left_eyeUpperLid_joint", "left_eyeball_joint", "nose_joint", "right_eye_joint", "right_eyeLowerLid_joint", "right_eyeUpperLid_joint", "right_eyeball_joint" :
            updatedJointRadius *= 0.2
            updatedJointColor = .yellow
        case _ where jointName.hasPrefix("spine_"):
            updatedJointRadius *= 0.75
        case _ where jointName.hasPrefix("left_hand") || jointName.hasPrefix("right_hand"):
            updatedJointRadius *= 0.5
            updatedJointColor = .yellow
        case _ where jointName.hasPrefix("left_toes") || jointName.hasPrefix("right_toes"):
            updatedJointRadius *= 0.25
            updatedJointColor = .yellow
        case "left_hand_joint", "right_hand_joint":
            updatedJointRadius *= 1
            updatedJointColor = .green
        default:
            break
        }
        return (updatedJointRadius, updatedJointColor)
    }
}
