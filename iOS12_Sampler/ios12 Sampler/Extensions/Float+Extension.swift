//
//  Float+Extension.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 04/03/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import Foundation

extension Float {
    /// A boolean value indicating whether a number is negative or not
    var isNegative: Bool {
        return self < 0
    }

    var toDegree : Float {
        get {
            self * 180 / .pi
        }
    }
}
