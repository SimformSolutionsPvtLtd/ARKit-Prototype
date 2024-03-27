//
//  JointAngles.swift
//  BodyDetection
//
//  Created by Dhruvil Vora on 13/03/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
enum AngleInBetween: String, CaseIterable {
    case left_upLeg_joint
    case left_leg_joint
    case right_upLeg_joint
    case right_leg_joint
    case left_arm_joint
    case left_forearm_joint
    case right_arm_joint
    case right_forearm_joint
    /// TODO :- Need to find an accurate way to get foot joint
    //    case left_foot_joint
    //    case right_foot_joint

    var angleFrom: String {
        switch self {
        case .left_upLeg_joint:
            "left_shoulder_1_joint"
        case .left_leg_joint: //knee
            "left_upLeg_joint"
        case .right_upLeg_joint:
            "right_shoulder_1_joint"
        case .right_leg_joint: //knee
            "right_upLeg_joint"
        case .left_arm_joint: // shoulder
            "left_forearm_joint"//"left_handMidEnd_joint"
        case .left_forearm_joint: // elbow
            "left_arm_joint"
        case .right_arm_joint: // shoulder
            "right_forearm_joint" // "right_handMidEnd_joint"
        case .right_forearm_joint: // elbow
            "right_arm_joint"
        /// TODO :- Need to find an accurate way to get foot joint
//        case .left_foot_joint:
//            "left_leg_joint"
//        case .right_foot_joint:
//            "right_leg_joint"//"right_upLeg_joint"
        }
    }

    var angleTo: String {
        switch self {
        case .left_upLeg_joint:
            "left_leg_joint"
        case .left_leg_joint: //knee
            "left_foot_joint"
        case .right_upLeg_joint:
            "right_leg_joint"
        case .right_leg_joint: //knee
            "right_foot_joint"
        case .left_arm_joint: // shoulder
            "left_upLeg_joint" //"left_arm_joint" //"spine_1_joint"
        case .left_forearm_joint: // elbow
            "left_hand_joint"
        case .right_arm_joint: // shoulder
            "right_upLeg_joint" //"right_arm_joint"  //"spine_1_joint"
        case .right_forearm_joint: // elbow
            "right_hand_joint"
    /// TODO :- Need to find an accurate way to get foot joint
//        case .left_foot_joint:
//            "left_toesEnd_joint"
//        case .right_foot_joint:
//            "right_toesEnd_joint"
        }
    }
}
