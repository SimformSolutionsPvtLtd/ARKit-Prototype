//
//  MeshResource+Extension.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 04/03/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import Foundation
import RealityKit

extension MeshResource {
    static func createSemiCircleMeshForAngle(angle: Float, isFacingLeft: Bool = false) -> MeshResource? {
        guard angle > 15.0 else { return nil }
        let angleCount = Int(angle/6)
        var fixedAngleCount = 0
        var fixedPostitions: [SIMD3<Float>] = []
        var positions: [SIMD3<Float>] = SIMD3<Float>.getSemiCircleMesh

        if isFacingLeft {
            let removalPosCount = 29 - angleCount
            positions.remove(atOffsets: IndexSet(0...(removalPosCount-1)))
            fixedPostitions.append(contentsOf: positions)
        } else {
            fixedPostitions.append(contentsOf: positions[0...(angleCount-1)])
        }

        fixedPostitions.append(.zero)
        fixedAngleCount = fixedPostitions.count

        let counts: [UInt8] = [UInt8(fixedAngleCount)]
        let indices: [UInt32] = fixedAngleCount.returnArrCountInUInt32()

        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = .init(fixedPostitions)
        meshDescriptor.primitives = .polygons(counts, indices)
        return try! MeshResource.generate(from: [meshDescriptor])
    }
}
