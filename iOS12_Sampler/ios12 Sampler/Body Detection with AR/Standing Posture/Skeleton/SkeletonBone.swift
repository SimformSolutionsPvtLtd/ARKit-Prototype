//
//  SkeletonBone.swift
//  BodyDetection
//
//  Created by Dhruvil Vora on 08/03/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import RealityKit

struct SkeletonBone {
    var fromJoint: SkeletonJoint
    var toJoint: SkeletonJoint

    var centerPoint: SIMD3<Float> {
        [((fromJoint.position.x + toJoint.position.x) / 2), ((fromJoint.position.y + toJoint.position.y) / 2), 
         ((fromJoint.position.z + toJoint.position.z) / 2)]
    }

    var length: Float {
        simd_distance(fromJoint.position, toJoint.position)
    }
}
