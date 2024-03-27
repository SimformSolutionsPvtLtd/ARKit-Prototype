//
//  String+Extension.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 26/03/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import Foundation

extension String {
    var isJointFromLegOrhand: Bool {
        ( 
            self == "left_upLeg_joint" || self == "left_leg_joint" ||
          self == "right_upLeg_joint" || self == "right_leg_joint" ||
          self == "left_arm_joint" || self == "left_forearm_joint" ||
          self == "right_arm_joint" || self == "right_forearm_joint" 
        /// TODO :- Need to find an accurate way to get foot joint
//        || self == "left_foot_joint" || self == "right_foot_joint"
        )
    }
}
