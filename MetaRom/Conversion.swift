//
//  Conversion.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 6/25/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import GLKit
import SceneKit

extension GLKQuaternion {
    init(_ quat: SCNQuaternion) {
        let tempy = GLKVector3Make(quat.x,quat.y,quat.z)
        //self.init(__Unnamed_struct___Anonymous_field1(x: quat.x, y: quat.y, z: quat.z, w: quat.w))
        self.init(__Unnamed_struct___Anonymous_field1(v: tempy, s: quat.w))
    }
    var asEuler: GLKVector3 {
        return setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(self))
    }
    var desc: String {
        return "GLKQuaternionMake(\(x), \(y), \(z), \(w))"
    }
    func dump() {
        print(desc)
    }
}
extension SCNQuaternion {
    init(_ quat: GLKQuaternion) {
        self.init(quat.x, quat.y, quat.z, quat.w)
    }
    var desc: String {
        return "SCNQuaternion(\(x), \(y), \(z), \(w))"
    }
    func dump() {
        print(desc)
    }
}
extension SCNVector3 {
    var glkVector: GLKVector3 {
        return SCNVector3ToGLKVector3(self)
    }
    var desc: String {
        return "SCNVector3(\(x), \(y), \(z))"
    }
    func dump() {
        print(desc)
    }
    var degrees: String {
        return "\(x.radiansToDegrees), \(y.radiansToDegrees), \(z.radiansToDegrees)"
    }
}
extension GLKVector3 {
    var scnVector: SCNVector3 {
        return SCNVector3FromGLKVector3(self)
    }
    var asQuaternion: GLKQuaternion {
        return setFromEuler(self)
    }
    func dump() {
        print("GLKVector3(\(x), \(y), \(z))")
    }
    func degDump() {
        print(degrees)
    }
    var degrees: String {
        return "\(x.radiansToDegrees), \(y.radiansToDegrees), \(z.radiansToDegrees)"
    }
    func dumpX(_ flop: Bool = false) {
        let val = flop ? (x > 0 ? x - .pi : x + .pi) : x
        print("\(val.radiansToDegrees)")
    }
    func dumpY(_ flop: Bool = false) {
        let val = flop ? (y > 0 ? y - .pi : y + .pi) : y
        print("\(val.radiansToDegrees)")
    }
    func dumpZ(_ flop: Bool = false) {
        let val = flop ? (z > 0 ? z - .pi : z + .pi) : z
        print("\(val.radiansToDegrees)")
    }
}
