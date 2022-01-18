//
//  ThreeJS.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 6/25/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import GLKit


extension Float {
    var degreesToRadians: Float { return GLKMathDegreesToRadians(self) }
    var radiansToDegrees: Float { return GLKMathRadiansToDegrees(self) }
}

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

enum Order {
    case xyz
    case yxz
    case zxy
    case zyx
    case yzx
    case xzy
}

// Ported from three.js
// https://github.com/mrdoob/three.js/blob/c0a34483fc23cde27f1206ef457bb5d67f9f6877/src/math/Quaternion.js#L197
func setFromEuler(_ euler: GLKVector3, order: Order = .xyz) -> GLKQuaternion {
    // http://www.mathworks.com/matlabcentral/fileexchange/
    //     20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
    //    content/SpinCalc.m
    let c1 = cos(euler.x / 2)
    let c2 = cos(euler.y / 2)
    let c3 = cos(euler.z / 2)
    
    let s1 = sin(euler.x / 2)
    let s2 = sin(euler.y / 2)
    let s3 = sin(euler.z / 2)
    
    let x, y, z, w: Float
    
    switch order {
        
    case .xyz:
        x = s1 * c2 * c3 + c1 * s2 * s3
        y = c1 * s2 * c3 - s1 * c2 * s3
        z = c1 * c2 * s3 + s1 * s2 * c3
        w = c1 * c2 * c3 - s1 * s2 * s3
    case .yxz:
        x = s1 * c2 * c3 + c1 * s2 * s3
        y = c1 * s2 * c3 - s1 * c2 * s3
        z = c1 * c2 * s3 - s1 * s2 * c3
        w = c1 * c2 * c3 + s1 * s2 * s3
    case .zxy:
        x = s1 * c2 * c3 - c1 * s2 * s3
        y = c1 * s2 * c3 + s1 * c2 * s3
        z = c1 * c2 * s3 + s1 * s2 * c3
        w = c1 * c2 * c3 - s1 * s2 * s3
    case .zyx:
        x = s1 * c2 * c3 - c1 * s2 * s3
        y = c1 * s2 * c3 + s1 * c2 * s3
        z = c1 * c2 * s3 - s1 * s2 * c3
        w = c1 * c2 * c3 + s1 * s2 * s3
    case .yzx:
        x = s1 * c2 * c3 + c1 * s2 * s3
        y = c1 * s2 * c3 + s1 * c2 * s3
        z = c1 * c2 * s3 - s1 * s2 * c3
        w = c1 * c2 * c3 - s1 * s2 * s3
    case .xzy:
        x = s1 * c2 * c3 - c1 * s2 * s3
        y = c1 * s2 * c3 - s1 * c2 * s3
        z = c1 * c2 * s3 + s1 * s2 * c3
        w = c1 * c2 * c3 + s1 * s2 * s3
    }
    return GLKQuaternionMake(x, y, z, w)
}

// Ported from three.js
// https://github.com/mrdoob/three.js/blob/c0a34483fc23cde27f1206ef457bb5d67f9f6877/src/math/Quaternion.js#L291
func setFromRotationMatrix(_ matrix: GLKMatrix4, order: Order = .xyz) -> GLKVector3 {
    // assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
    let m11 = matrix[0], m12 = matrix[4], m13 = matrix[8]
    let m21 = matrix[1], m22 = matrix[5], m23 = matrix[9]
    let m31 = matrix[2], m32 = matrix[6], m33 = matrix[10]

    let x, y, z: Float

    switch order {
    case .xyz:
        y = asin((-1.0...1.0).clamp(m13))
        if (abs( m13 ) < 0.99999) {
            x = atan2(-m23, m33)
            z = atan2(-m12, m11)
        } else {
            x = atan2(m32, m22)
            z = 0
        }
    case .yxz:
        x = asin(-(-1.0...1.0).clamp(m23))
        if (abs( m23 ) < 0.99999) {
            y = atan2(m13, m33)
            z = atan2(m21, m22)
        } else {
            y = atan2(-m31, m11)
            z = 0
        }
    case .zxy:
        x = asin((-1.0...1.0).clamp(m32))
        if (abs( m32 ) < 0.99999) {
            y = atan2(-m31, m33)
            z = atan2(-m12, m22)
        } else {
            y = 0
            z = atan2(m21, m11)
        }
    case .zyx:
        y = asin(-(-1.0...1.0).clamp(m31))
        if (abs(m31) < 0.99999) {
            x = atan2(m32, m33)
            z = atan2(m21, m11)
        } else {
            x = 0
            z = atan2(-m12, m22)
        }
    case .yzx:
        z = asin((-1.0...1.0).clamp(m21))
        if (abs( m21 ) < 0.99999) {
            x = atan2(-m23, m22)
            y = atan2(-m31, m11)
        } else {
            x = 0
            y = atan2(m13, m33)
        }
    case .xzy:
        z = asin(-(-1.0...1.0).clamp(m12))
        if (abs(m12) < 0.99999) {
            x = atan2(m32, m22)
            y = atan2(m13, m11)
        } else {
            x = atan2(-m23, m33)
            y = 0
        }
    }
    return GLKVector3Make(x, y ,z)
}
