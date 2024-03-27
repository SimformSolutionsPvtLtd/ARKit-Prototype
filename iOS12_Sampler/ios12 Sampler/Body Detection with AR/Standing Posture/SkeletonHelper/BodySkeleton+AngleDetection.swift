//
//  BodySkeleton+AngleDetection.swift
//  BodyDetection
//
//  Created by Dhruvil Vora on 22/03/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import RealityKit
import ARKit

extension BodySkeleton {

    func calculateRespectedJointAngles(jointName: String, parentEntity: Entity, bodyEntity: ARBodyAnchor) -> Int {
        guard let name = AngleInBetween(rawValue: jointName) else { return 0 }
        guard let (fromAngle, toAngle, angleToName) = getJointsTransform(bodyEntity: bodyEntity, angleFromName: name.angleFrom, angleToName: name.angleTo, angleForJoint: jointName) else { return 0 }
        return getAngleBetweenTwoVectors(with: fromAngle, to: toAngle, for: (name, angleToName))
    }

    func getAngleBetweenTwoVectors(with fromAngle: SIMD3<Float>, to toAngle: SIMD3<Float>, for forAngle: (AngleInBetween, SIMD3<Float>)) -> Int {
        var angle : Float = 0.0
//        if forAngle.0 == .left_arm_joint || forAngle.0 == .right_arm_joint {
//            angle = SIMD3<Float>.angleForArms(v1: fromAngle, v2: toAngle)
//        } else {
            angle = SIMD3<Float>.getAngleBetween(fromAngle: fromAngle, toAngle: toAngle, forAngle: forAngle.1)
//        }
        return angle.isNaN ? 0 : Int(angle)
    }

    static func getBodyJointsTransform(from vector1: SIMD4<Float>, to vector2: SIMD4<Float>) -> Float {
        /// In order to find the anglke between two vectors we can use the formula of dot product
        ///
        /// Step 1:-  Need to find dot product on basis of two vectors
        let dotProduct = (vector1.x * vector2.x) + (vector1.x * vector2.x) + (vector1.x * vector2.x)

        /// Now we need to find the magniotudes of both the vecitors
        let magForVector1 = sqrtf(powf(vector1.x, 2) + powf(vector1.y, 2) + powf(vector1.z, 2))
        let magForVector2 = sqrtf(powf(vector1.x, 2) + powf(vector1.y, 2) + powf(vector1.z, 2))

        /// calculating the cosine rule for dot and magnitude
        let angleInRadian = acosf(dotProduct / (magForVector1 * magForVector2))
        return angleInRadian * (180 / .pi)
    }

    private func getJointsTransform(bodyEntity: ARBodyAnchor, angleFromName: String, angleToName: String, angleForJoint: String) -> (angleFromTransform: SIMD3<Float>, angleMidTransform: SIMD3<Float>, angleToTransform: SIMD3<Float>)?{
        guard let fromJointModelTransform = bodyEntity.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: angleFromName)),
              let toJointModelTransform = bodyEntity.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: angleToName)),
              let midJointModelTransform = bodyEntity.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: angleForJoint))
        else { return nil }
        let fromJointOffset = Transform(matrix: fromJointModelTransform).translation
        let toJointOffset = Transform(matrix: toJointModelTransform).translation
        let midJointOffset = Transform(matrix: midJointModelTransform).translation
        return ((fromJointOffset), (toJointOffset), (midJointOffset))
    }
}
