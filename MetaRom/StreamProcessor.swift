//
//  StreamProcessor.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 8/24/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import SceneKit
import GLKit
import BoltsSwift
import MetaWear
import MetaWearCpp


protocol StreamProcessorDelegate: class {
    func didFinish(isUpper: Bool, error: Error?)
    func connecting(isUpper: Bool)
    func newSample(upper: SCNQuaternion, lower: SCNQuaternion, measurements: [(Measurement, Double)])
}

class StreamProcessor {
    static private var cache: [Patient: StreamProcessor] = [:]

    let upperStream: QuaternionStream
    let lowerStream: QuaternionStream
    let joint: JointConfig
    
    weak var delegate: StreamProcessorDelegate?

    var lowerCalibrationRemap: GLKQuaternion?
    var upperRawQuaternion: GLKQuaternion?
    var calibrateNextSample = false
    
    var allConnected: Bool {
        return upperStream.device.isConnectedAndSetup && lowerStream.device.isConnectedAndSetup
    }
    
    class func getOrCreate(patient: Patient, upper: MetaWear, lower: MetaWear, joint: JointConfig) -> (StreamProcessor, Bool) {
        var created = false
        var streamProcessor = StreamProcessor.cache[patient]
        // See if the cached processor matches
        if streamProcessor != nil {
            let isSame = streamProcessor!.joint == joint &&
                streamProcessor!.upperStream.device == upper &&
                streamProcessor!.lowerStream.device == lower
            if !isSame {
                streamProcessor = nil
            }
        }
        // Create a processor if needed
        if streamProcessor == nil {
            streamProcessor = StreamProcessor(
                upperStream: QuaternionStream(upper),
                lowerStream: QuaternionStream(lower),
                joint: joint)
            created = true
            StreamProcessor.cache[patient] = streamProcessor!
        }
        return (streamProcessor!, created)
    }
    
    class func stopAll() {
        cache.forEach { $0.value.stopStream() }
    }
    
    class func remove(patient: Patient) {
        let processor = StreamProcessor.cache.removeValue(forKey: patient)
        processor?.stopStream()
    }
    
    private init(upperStream: QuaternionStream, lowerStream: QuaternionStream, joint: JointConfig) {
        self.upperStream = upperStream
        self.lowerStream = lowerStream
        self.joint = joint
    }
    
    func startStream() {
        upperStream.delegate = self
        upperStream.startStream(upper: true)
        lowerStream.delegate = self
        lowerStream.startStream(upper: false)
    }
    
    func stopStream() {
        upperStream.stopStream()
        lowerStream.stopStream()
    }
    
    func newLowerSample(_ rawLower: GLKQuaternion) {
        guard let upper = upperRawQuaternion else {
            return
        }
        // Some joints require on body calibration, perform this here when requested
        if calibrateNextSample {
            calibrateNextSample = false
            lowerCalibrationRemap = joint.lower.measureRemapFunc?(rawLower)
        }
        let lower = lowerCalibrationRemap == nil ? rawLower : GLKQuaternionMultiply(rawLower, lowerCalibrationRemap!)
        
        let deltaQuat = GLKQuaternionMultiply(GLKQuaternionInvert(lower), upper)
        
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .xyz).dumpX()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .xzy).dumpX()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .zyx).dumpX()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .yzx).dumpX()

//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .yxz).dumpY()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .zxy).dumpY()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .xzy).dumpY()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .yzx).dumpY()
//
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .xyz).dumpZ()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .yxz).dumpZ()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .zxy).dumpZ()
//        setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(deltaQuat), order: .zyx).dumpZ()
//        print("")
        delegate?.newSample(upper: SCNQuaternion(joint.upper.convertToModelSpace(upper)),
                            lower: SCNQuaternion(joint.lower.convertToModelSpace(lower)),
                            measurements: joint.measurements.map { ($0.measurement, Double($0.process(deltaQuat))) })
    }
    
    func doCalibration() -> Task<Void> {
        var tasks: [Task<MetaWear>] = []
        tasks.append(upperStream.device.connectAndSetup().continueOnSuccessWithTask() {
            mbl_mw_debug_reset(self.upperStream.device.board)
            return $0
        })
        tasks.append(lowerStream.device.connectAndSetup().continueOnSuccessWithTask() {
            mbl_mw_debug_reset(self.lowerStream.device.board)
            return $0
        })
        return Task.whenAll(tasks).continueWithTask { t in
            var tasks: [Task<Task<MetaWear>>] = []
            tasks.append(self.upperStream.device.connectAndSetup())
            tasks.append(self.lowerStream.device.connectAndSetup())
            self.calibrateNextSample = true
            return Task.whenAll(tasks)
        }
    }
}


extension StreamProcessor: QuaternionStreamDelegate {
    func connecting(_ dataCapture: QuaternionStream) {
        self.delegate?.connecting(isUpper: dataCapture === upperStream)
    }
    
    func didFinish(_ dataCapture: QuaternionStream, error: Error?) {
        self.delegate?.didFinish(isUpper: dataCapture === upperStream, error: error)
    }
    
    func newSample(_ dataCapture: QuaternionStream, quat: GLKQuaternion) {
        if dataCapture === upperStream {
            upperRawQuaternion = quat
        } else if dataCapture === lowerStream {
            self.newLowerSample(quat)
        }
    }
}


func simpleAverage(_ quats: [GLKQuaternion]) -> GLKQuaternion {
    let first = quats.first!
    let sum: GLKQuaternion = quats.reduce(GLKQuaternionMake(0, 0, 0, 0)) { (result, cur) in
        let a = GLKQuaternionAreClose(first, cur) ? cur : GLKQuaternionInvertSign(cur)
        return GLKQuaternionAdd(result, a)
    }
    return GLKQuaternionNormalize(sum)
}


func GLKQuaternionAreClose(_ a: GLKQuaternion, _ b: GLKQuaternion) -> Bool {
    let dot = GLKVector4DotProduct(GLKVector4Make(a.x, a.y, a.z, a.w), GLKVector4Make(b.x, b.y, b.z, b.w))
    return !(dot < 0.0)
}

func GLKQuaternionInvertSign(_ a: GLKQuaternion) -> GLKQuaternion {
    return GLKQuaternionMake(-a.x, -a.y, -a.z, -a.w)
}

func GLKQuaternionIsOutOfDelta(_ a: GLKQuaternion, _ b: GLKQuaternion, _ delta: Float = 0.05) -> Bool {
    return delta < abs(a.x - b.x) ||
        delta < abs(a.y - b.y) ||
        delta < abs(a.z - b.z) ||
        delta < abs(a.w - b.w)
}

//func fancyLASwiftAverageQuat(buffer: [GLKQuaternion]) {
//    let doubles = buffer.map { [Double($0.x), Double($0.y), Double($0.z), Double($0.w)] }
//
//    let m1 = transpose(Matrix(doubles))
//    let q = (1.0 / Double(buffer.count)) .* m1
//    let thing = q * transpose(q)
//    let e1 = eig(thing)
//    var idx = 0
//    var largest = -Double.infinity
//    max(e1.D).enumerated().forEach {
//        if $0.element > largest {
//            largest = $0.element
//            idx = $0.offset
//        }
//    }
//    let baller = e1.V[col: idx]
//    let eigInitial = GLKQuaternionMake(Float(baller[0]), Float(baller[1]), Float(baller[2]), Float(baller[3]))
//
//    let avgSol = simpleAverage(buffer)
//
//    let eigSol = GLKQuaternionAreClose(eigInitial, avgSol) ? eigInitial : GLKQuaternionInvertSign(eigInitial)
//
//    eigSol.dump()
//    avgSol.dump()
//
//    if GLKQuaternionIsOutOfDelta(eigSol, avgSol) {
//        print("DIFFERENT")
//        buffer.forEach { $0.dump() }
//        print("")
//    }
//    print("")
//}
