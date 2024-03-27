//
//  Simd3+Extension.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 04/03/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import Foundation
import SceneKit

extension SIMD3<Float> {

    static var getSemiCircleMesh: [SIMD3<Float>] {
        [
            [0.8, 0.1, 0], [0.79, 0.18, 0], [0.78, 0.26, 0], [0.75, 0.43, 0], [0.725, 0.53, 0],
            [0.7, 0.6, 0], [0.65, 0.7, 0], [0.6, 0.78, 0], [0.55, 0.83, 0], [0.45, 0.9, 0],
            [0.4, 0.92, 0], [0.3, 0.95, 0], [0.2, 0.98, 0], [0.1, 1, 0], [0, 1, 0],
            [-0.1, 1, 0], [-0.2, 0.98, 0], [-0.3, 0.95, 0], [-0.4, 0.92, 0], [-0.45, 0.9, 0],
            [-0.55, 0.83, 0], [-0.6, 0.78, 0], [-0.65, 0.7, 0], [-0.7, 0.6, 0], [-0.725, 0.53, 0],
            [-0.75, 0.43, 0], [-0.78, 0.26, 0], [-0.79, 0.18, 0], [-0.8, 0.1, 0]
        ]
    }

    var length:Float {
        get {
            return sqrtf(x*x + y*y + z*z)
        }
    }

    static func dotProduct(v1: SIMD3<Float>, v2: SIMD3<Float>) -> Float{
        return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
    }

    static func angleBetween(v1: SIMD3<Float>, v2: SIMD3<Float>) -> Float{
        let cosinus = dotProduct(v1: v1, v2: v2) / v1.length / v2.length
        let angle = acos(cosinus)
        return angle
    }

    // Return the angle between this vector and the specified vector v
    func angle(v: SIMD3<Float>) -> Float
    {
        // angle between 3d vectors P and Q is equal to the arc cos of their dot products over the product of
        // their magnitudes (lengths).
        //    theta = arccos( (P • Q) / (|P||Q|) )
        let dp = dot(v) // dot product
        let magProduct = length * v.length // product of lengths (magnitudes)
        return acos(dp / magProduct) // DONE
    }

    func dot(_ vec: SIMD3<Float>) -> Float {
        return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
    }

    static func angleForArms(v1: SIMD3<Float>, v2: SIMD3<Float>) -> Float{
        let vectorFromShoulderToElbow = (v2 - v1)
        // We can perform further calculations to get the angle from this vector
        // For example, we can also use atan2 or acos to get the angle in radians or degrees
        let angleInRadians = atan2(vectorFromShoulderToElbow.x, vectorFromShoulderToElbow.y)
        let angleInDegrees = abs(angleInRadians.toDegree)
        print("NEw angle :- ",angleInDegrees)
        return angleInDegrees
    }

    static func getAngleBetween(fromAngle: SIMD3<Float>, toAngle: SIMD3<Float>, forAngle: SIMD3<Float>) -> Float {
        let vector_a = (fromAngle - forAngle)
        let vector_b = (toAngle - forAngle)
        let degres = SIMD3<Float>.angle(vector1: vector_a, vector2: vector_b)
        return degres
    }

    /// Calculates the **angles** between two vectors.
    static func angle(vector1: SIMD3<Float>, vector2: SIMD3<Float>) -> Float{
        /// In order to find the angle between two vectors we can use the formula of dot product
        ///
        /// Step 1:- Now we need to find the magniotudes of both the vecitors
        let mag_vector1 = powf(vector1.x, 2) + powf(vector1.y, 2) + powf(vector1.z, 2) // a^2 + b^2 + c^2 (helpful to calculate magnitude)
        let mag_vector2 = powf(vector2.x, 2) + powf(vector2.y, 2) + powf(vector2.z, 2)  // a^2 + b^2 + c^2 (helpful to calculate magnitude)
        let magnitudeForVectors = sqrtf(mag_vector1) * sqrtf(mag_vector2) // Magnitude calculations
        /// Step 2:-  Need to find dot product on basis of two vectors
        let dot_product = (vector1.x * vector2.x) + (vector1.y * vector2.y) + (vector1.z * vector2.z) // Dot product
        /// Step 3:- Calculating the cosine rule for dot and magnitude
        return acosf(dot_product / magnitudeForVectors).toDegree
    }

}

