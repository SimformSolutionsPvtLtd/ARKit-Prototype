//
//  Bones.swift
//  BodyDetection
//
//  Created by Dhruvil Vora on 08/03/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

enum Bones: CaseIterable {

    case neck1ToNeck2
    case neck2ToNeck3
    case neck3ToNeck4
    case neck4ToHead
    case headToNose
    case headToRightEye
    case headToLeftEye

    case neckToLeftShoulder
    case leftShoulderToLeftArm
    case leftArmToLeftForeArm
    case leftForeArmToLeftHand

    case neckToRightShoulder
    case rightShoulderToLeftArm
    case rightArmToLeftForeArm
    case rightForeArmToLeftHand

    case neckToSpine7
    case spine7ToSpine6
    case spine6ToSpine5
    case spine5ToSpine4
    case spine4ToSpine3
    case spine3ToSpine2
    case spine2ToSpine1

    case spineToleftUpLeg
    case spineToRightUpLeg

    case leftUpLegToLeftLegJoint
    case leftLegJointToLeftFootJoint
    case leftFootJointToLeftToesJoint
    case leftToesJointToLeftToesEndJoint

    case rightUpLegToLeftLegJoint
    case rightLegJointToLeftFootJoint
    case rightFootJointToLeftToesJoint
    case rightToesJointToLeftToesEndJoint

    var name: String {
        return "\(jointFromName)-\(jointToName)"
    }

    var jointFromName: String {
        switch self {
        case .neck1ToNeck2:
            return "neck_1_joint"
        case .neck2ToNeck3:
            return "neck_2_joint"
        case .neck3ToNeck4:
            return "neck_3_joint"
        case .neck4ToHead:
            return "neck_4_joint"
        case .headToNose:
            return "head_joint"
        case .headToRightEye:
            return "head_joint"
        case .headToLeftEye:
            return "head_joint"

        case .neckToLeftShoulder:
            return "neck_1_joint"
        case .leftShoulderToLeftArm:
            return "left_shoulder_1_joint"
        case .leftArmToLeftForeArm:
            return "left_arm_joint"
        case .leftForeArmToLeftHand:
            return "left_forearm_joint"

        case .neckToRightShoulder:
            return "neck_1_joint"
        case .rightShoulderToLeftArm:
            return "right_shoulder_1_joint"
        case .rightArmToLeftForeArm:
            return "right_arm_joint"
        case .rightForeArmToLeftHand:
            return "right_forearm_joint"

        case .neckToSpine7:
            return "neck_1_joint"
        case .spine7ToSpine6:
            return "spine_7_joint"
        case .spine6ToSpine5:
            return "spine_6_joint"
        case .spine5ToSpine4:
            return "spine_5_joint"
        case .spine4ToSpine3:
            return "spine_4_joint"
        case .spine3ToSpine2:
            return "spine_3_joint"
        case .spine2ToSpine1:
            return "spine_2_joint"

        case .spineToleftUpLeg:
            return "spine_1_joint"
        case .spineToRightUpLeg:
            return "spine_1_joint"

        case .leftUpLegToLeftLegJoint:
            return "left_upLeg_joint"
        case .leftLegJointToLeftFootJoint:
            return "left_leg_joint"
        case .leftFootJointToLeftToesJoint:
            return "left_foot_joint"
        case .leftToesJointToLeftToesEndJoint:
            return "left_toes_joint"
        case .rightUpLegToLeftLegJoint:
            return "right_upLeg_joint"
        case .rightLegJointToLeftFootJoint:
            return "right_leg_joint"
        case .rightFootJointToLeftToesJoint:
            return "right_foot_joint"
        case .rightToesJointToLeftToesEndJoint:
            return "right_toes_joint"
        }
    }

    var jointToName: String {
        switch self {
        case .neck1ToNeck2:
            return "neck_2_joint"
        case .neck2ToNeck3:
            return "neck_3_joint"
        case .neck3ToNeck4:
            return "neck_4_joint"
        case .neck4ToHead:
            return "head_joint"
        case .headToNose:
            return "nose_joint"
        case .headToRightEye:
            return "right_eye_joint"
        case .headToLeftEye:
            return "left_eye_joint"


        case .neckToLeftShoulder:
            return "left_shoulder_1_joint"
        case .leftShoulderToLeftArm:
            return "left_arm_joint"
        case .leftArmToLeftForeArm:
            return "left_forearm_joint"
        case .leftForeArmToLeftHand:
            return "left_hand_joint"

        case .neckToRightShoulder:
            return "right_shoulder_1_joint"
        case .rightShoulderToLeftArm:
            return "right_arm_joint"
        case .rightArmToLeftForeArm:
            return "right_forearm_joint"
        case .rightForeArmToLeftHand:
            return "right_hand_joint"

        case .neckToSpine7:
            return "spine_7_joint"
        case .spine7ToSpine6:
            return "spine_6_joint"
        case .spine6ToSpine5:
            return "spine_5_joint"
        case .spine5ToSpine4:
            return "spine_4_joint"
        case .spine4ToSpine3:
            return "spine_3_joint"
        case .spine3ToSpine2:
            return "spine_2_joint"
        case .spine2ToSpine1:
            return "spine_1_joint"

        case .spineToleftUpLeg:
            return "left_upLeg_joint"
        case .spineToRightUpLeg:
            return "right_upLeg_joint"

        case .leftUpLegToLeftLegJoint:
            return "left_leg_joint"
        case .leftLegJointToLeftFootJoint:
            return "left_foot_joint"
        case .leftFootJointToLeftToesJoint:
            return "left_toes_joint"
        case .leftToesJointToLeftToesEndJoint:
            return "left_toesEnd_joint"
        case .rightUpLegToLeftLegJoint:
            return "right_leg_joint"
        case .rightLegJointToLeftFootJoint:
            return "right_foot_joint"
        case .rightFootJointToLeftToesJoint:
            return "right_toes_joint"
        case .rightToesJointToLeftToesEndJoint:
            return "right_toesEnd_joint"
        }
    }
}
