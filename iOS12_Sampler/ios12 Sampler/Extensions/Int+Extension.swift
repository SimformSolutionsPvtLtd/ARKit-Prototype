//
//  Int+Extension.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 04/03/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import UIKit

extension Int {
    /// Provides a array of UInt32 from the given count
    func returnArrCountInUInt32() -> [UInt32]{
        var arr = [UInt32]()
        for x in 0...(self-1) {
            arr.append(UInt32(x))
        }
        return arr
    }

    /// Provides a predefined colour based on detected angle from body posture
    func postureIntensityColor() -> UIColor{
        if self <= 70 {
            return .red.withAlphaComponent(0.7)
        } else if (self > 70 && self <= 110) {
            return .orange.withAlphaComponent(0.7)
        } else if self > 110 {
            return .green.withAlphaComponent(0.7)
        }
        return .black.withAlphaComponent(0.7)
    }
}
