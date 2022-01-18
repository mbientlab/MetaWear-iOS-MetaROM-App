//
//  BirdyConversion.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 10/8/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import GLKit

///////////////////////////////
// Quaternion to Euler
///////////////////////////////
enum BirdyOrder {
    case zyx
    case zyz
    case zxy
    case zxz
    case yxz
    case yxy
    case yzx
    case yzy
    case xyz
    case xyx
    case xzy
    case xzx
}

func twoaxisrot(_ r11: Float, _ r12: Float, _ r21: Float, _ r31: Float, _ r32: Float) -> [Float] {
    return [
        atan2(r11, r12),
        acos(r21),
        atan2(r31, r32),
    ]
}

func threeaxisrot(_ r11: Float, _ r12: Float, _ r21: Float, _ r31: Float, _ r32: Float) -> [Float] {
    return [
        atan2(r31, r32),
        asin(r21),
        atan2(r11, r12),
    ]
}

// note:
// return values of res[] depends on rotSeq.
// i.e.
// for rotSeq zyx,
// x = res[0], y = res[1], z = res[2]
// for rotSeq xyz
// z = res[0], y = res[1], x = res[2]
// ...
func quaternion2Euler(_ q: GLKQuaternion, rotSeq: BirdyOrder) -> GLKVector3
{
    switch rotSeq {
    case .zyx:
        let res = threeaxisrot( 2*(q.x*q.y + q.w*q.z),
                      q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z,
                      -2*(q.x*q.z - q.w*q.y),
                      2*(q.y*q.z + q.w*q.x),
                      q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z)
        return GLKVector3Make(res[0], res[1], res[2])
    case .zyz:
         let res = twoaxisrot( 2*(q.y*q.z - q.w*q.x),
                    2*(q.x*q.z + q.w*q.y),
                    q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z,
                    2*(q.y*q.z + q.w*q.x),
                    -2*(q.x*q.z - q.w*q.y))
        return GLKVector3Make(res[2], res[1], res[0])
    case .zxy:
         let res = threeaxisrot( -2*(q.x*q.y - q.w*q.z),
                      q.w*q.w - q.x*q.x + q.y*q.y - q.z*q.z,
                      2*(q.y*q.z + q.w*q.x),
                      -2*(q.x*q.z - q.w*q.y),
                      q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z)
        return GLKVector3Make(res[1], res[0], res[2])
    case .zxz:
         let res = twoaxisrot( 2*(q.x*q.z + q.w*q.y),
                    -2*(q.y*q.z - q.w*q.x),
                    q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z,
                    2*(q.x*q.z - q.w*q.y),
                    2*(q.y*q.z + q.w*q.x))
        return GLKVector3Make(res[1], res[2], res[0])
    case .yxz:
         let res = threeaxisrot( 2*(q.x*q.z + q.w*q.y),
                      q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z,
                      -2*(q.y*q.z - q.w*q.x),
                      2*(q.x*q.y + q.w*q.z),
                      q.w*q.w - q.x*q.x + q.y*q.y - q.z*q.z)
        return GLKVector3Make(res[1], res[2], res[0])
    case .yxy:
         let res = twoaxisrot( 2*(q.x*q.y - q.w*q.z),
                    2*(q.y*q.z + q.w*q.x),
                    q.w*q.w - q.x*q.x + q.y*q.y - q.z*q.z,
                    2*(q.x*q.y + q.w*q.z),
                    -2*(q.y*q.z - q.w*q.x))
        return GLKVector3Make(res[1], res[0], res[2])
    case .yzx:
         let res = threeaxisrot( -2*(q.x*q.z - q.w*q.y),
                      q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z,
                      2*(q.x*q.y + q.w*q.z),
                      -2*(q.y*q.z - q.w*q.x),
                      q.w*q.w - q.x*q.x + q.y*q.y - q.z*q.z)
        return GLKVector3Make(res[0], res[2], res[1])
    case .yzy:
         let res = twoaxisrot( 2*(q.y*q.z + q.w*q.x),
                    -2*(q.x*q.y - q.w*q.z),
                    q.w*q.w - q.x*q.x + q.y*q.y - q.z*q.z,
                    2*(q.y*q.z - q.w*q.x),
                    2*(q.x*q.y + q.w*q.z))
        return GLKVector3Make(res[2], res[0], res[1])
    case .xyz:
         let res = threeaxisrot( -2*(q.y*q.z - q.w*q.x),
                      q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z,
                      2*(q.x*q.z + q.w*q.y),
                      -2*(q.x*q.y - q.w*q.z),
                      q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z)
        return GLKVector3Make(res[2], res[1], res[0])
    case .xyx:
         let res = twoaxisrot( 2*(q.x*q.y + q.w*q.z),
                    -2*(q.x*q.z - q.w*q.y),
                    q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z,
                    2*(q.x*q.y - q.w*q.z),
                    2*(q.x*q.z + q.w*q.y))
        return GLKVector3Make(res[0], res[1], res[2])
    case .xzy:
         let res = threeaxisrot( 2*(q.y*q.z + q.w*q.x),
                      q.w*q.w - q.x*q.x + q.y*q.y - q.z*q.z,
                      -2*(q.x*q.y - q.w*q.z),
                      2*(q.x*q.z + q.w*q.y),
                      q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z)
        return GLKVector3Make(res[2], res[0], res[1])
    case .xzx:
         let res = twoaxisrot( 2*(q.x*q.z - q.w*q.y),
                    2*(q.x*q.y + q.w*q.z),
                    q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z,
                    2*(q.x*q.z + q.w*q.y),
                    -2*(q.x*q.y - q.w*q.z))
        return GLKVector3Make(res[0], res[2], res[1])
    }
}

//        quaternion2Euler(deltaQuat, rotSeq: .zyx).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .zyz).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .zxy).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .zxz).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .yxz).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .yxy).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .yzx).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .yzy).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .xyz).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .xyx).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .xzy).dumpX()
//        quaternion2Euler(deltaQuat, rotSeq: .xzx).dumpX()
