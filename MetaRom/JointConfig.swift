//
//  JointConfig.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 6/25/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import GLKit
import SceneKit


enum Joint: String {
    case knee = "Knee"
    case elbow = "Elbow"
    case wrist = "Wrist"
    case forearm = "Forearm"
    case ankle = "Ankle"
    case neck = "Neck"
    case spine = "Spine"
    case shoulder = "Shoulder"
    case hip = "Hip"
}

enum Side: String {
    case left = "Left"
    case right = "Right"
    case none = "None"
    
    var displayName: String {
        switch self {
        case .none:
            return ""
        default:
            return "\(rawValue) "
        }
    }
}

enum Difficulty: Int, Comparable, Codable {
    case easy
    case normal
    
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .normal:
            return "Normal"
        }
    }
}


/// This in the form of POSITIVE/NEGATIVE
/// For example, a positive data value of a flexionExtension measurment
/// means the the joint is in flexion, and negative is extension
enum Measurement: String {
    case flexionExtension = "Flexion/Extension"
    case radialUlnar  = "Radial/Ulnar"
    case supinationPronation = "Supination/Pronation"
    case eversionInversion = "Eversion/Inversion"
    case rotation = "Left/Right Rotation"
    case abductionAdduction = "Abduction/Adduction"
    case lateralFlexion  = "Left/Right Lateral Flexion"
}

enum Type: String {
    case freeform = "Freeform"
    case exercise = "Exercise"
}

enum SensorColor: String {
    case blue = "Blue"
    case green = "Green"
    
    var color: UIColor {
        get {
            switch self {
            case .blue:
                return #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
            case .green:
                return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            }
        }
    }
}

/// This has the wonderful job of converting a quaternion to the various joint measurments
/// with the correct sign and range.  Note the quaternion provided represents the difference
/// between the upper and lower sensors, i.e. take the upper as our reference frame, then
/// the quaternion provided is what rotation is needed to align with the lower.
///
/// All these are not necessarily valid in all orientations due to gimble lock issues present
/// with euler angle type conversion.  We do however put the gimble lock axis perpendicular to
/// the measurment of interest, so under normal conditions all works well.
///
/// Good luck future humans messing with this
struct MeasurementProcessor {
    let measurement: Measurement
    let process: (GLKQuaternion) -> Float
    
    static let kneeFlexionExtension = MeasurementProcessor(measurement: .flexionExtension) { (quat) -> Float in
        let val = -setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .yzx).x.radiansToDegrees
        return val < -90 ? val + 360 : val
    }
    
    static let elbowFlexionExtension = MeasurementProcessor(measurement: .flexionExtension) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xzy).x.radiansToDegrees
        return val < -90 ? val + 360 : val
    }
    
    static let neckFlexionExtension = MeasurementProcessor(measurement: .flexionExtension) { (quat) -> Float in
        let val = -setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xzy).x.radiansToDegrees
        return val > 0 ? val - 180 : val + 180
    }
    
    static let spineFlexionExtension = MeasurementProcessor(measurement: .flexionExtension) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xzy).x.radiansToDegrees
        return -val
    }
    
    static let ankleFlexionExtension = MeasurementProcessor(measurement: .flexionExtension) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xzy).x.radiansToDegrees
        return val - 90
    }
    
    static let wristFlexionExtension = MeasurementProcessor(measurement: .flexionExtension) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xyz).x.radiansToDegrees
        return -val
    }
    
    static let shoulderFlexionExtension = MeasurementProcessor(measurement: .flexionExtension) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xzy).x.radiansToDegrees
        return val
    }
    
    static let hipFlexionExtension = MeasurementProcessor(measurement: .flexionExtension) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xzy).x.radiansToDegrees
        let flop = (val > 0 ? val - 180.0 : val + 180.0)
        return flop < -135 ? flop + 360 : flop
    }
    
    static let rightHipAbductionAdduction = MeasurementProcessor(measurement: .abductionAdduction) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .zyx).z.radiansToDegrees
        return val
    }
    
    static let leftHipAbductionAdduction = MeasurementProcessor(measurement: .abductionAdduction) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .zyx).z.radiansToDegrees
        return -val
    }
    
    static let rightRadialUlnar = MeasurementProcessor(measurement: .radialUlnar) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .zyx).z.radiansToDegrees
        return -val
    }
    
    static let leftRadialUlnar = MeasurementProcessor(measurement: .radialUlnar) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .zyx).z.radiansToDegrees
        return val
    }
    
    static let rightAnkleEversionInversion = MeasurementProcessor(measurement: .eversionInversion) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xyz).z.radiansToDegrees
        return val
    }
    
    static let leftAnkleEversionInversion = MeasurementProcessor(measurement: .eversionInversion) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xyz).z.radiansToDegrees
        return -val
    }
    
    static let rotation = MeasurementProcessor(measurement: .rotation) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .xzy).y.radiansToDegrees
        return val
    }
    
    static let lateralFlexion = MeasurementProcessor(measurement: .lateralFlexion) { (quat) -> Float in
        let val = -setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .yxz).z.radiansToDegrees
        return val > 0 ? val - 180 : val + 180
    }
    
    static let spineLateralFlexion = MeasurementProcessor(measurement: .lateralFlexion) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .yxz).z.radiansToDegrees
        return -val
    }
    
    static let rightAbductionAdduction = MeasurementProcessor(measurement: .abductionAdduction) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .zyx).z.radiansToDegrees
        return -val
    }
    
    static let leftAbductionAdduction = MeasurementProcessor(measurement: .abductionAdduction) { (quat) -> Float in
        let val = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .zyx).z.radiansToDegrees
        return val
    }
}

/// This is a logical representation of single segment of the robot model
/// It defines constants on how to map the MetaWear reference frame (in it's
/// expected mounting posistion) to the models reference frame.
///
/// Good luck future humans messing with this, but slightly easier than MeasurementProcessor
struct ModelInfo {
    let nodeName: String
    let sensorColor: SensorColor
    let modelRemap: GLKQuaternion
    let modelZero: GLKQuaternion
    let measureRemapFunc: ((GLKQuaternion) -> (GLKQuaternion))?
    
    func convertToModelSpace(_ quat: GLKQuaternion) -> GLKQuaternion {
        // Remap the axis and directions based on the model
        let remap = GLKQuaternionMultiply(quat, modelRemap)
        // Remap the zero posistion based on the model
        return GLKQuaternionMultiply(modelZero, remap)
    }
    
    static func leftThigh(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "thigh.L",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func leftShin(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "shin.L",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    
    static func rightThigh(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "thigh.R",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func rightShin(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "shin.R",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    
    static func leftTriceps (_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "upper_arm.L",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 1, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func leftBiceps (_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "upper_arm.L",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func leftForearm(_ sensorColor: SensorColor) -> ModelInfo {
        return  ModelInfo(nodeName: "forearm.L",
                          sensorColor: sensorColor,
                          modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1),
                          modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                          measureRemapFunc: nil)
    }
    
    static func rightTriceps(_ sensorColor: SensorColor) -> ModelInfo {
        return  ModelInfo(nodeName: "upper_arm.R",
                          sensorColor: sensorColor,
                          modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 1, 0),
                          modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                          measureRemapFunc: nil)
    }
    
    static func rightBiceps(_ sensorColor: SensorColor) -> ModelInfo {
        return  ModelInfo(nodeName: "upper_arm.R",
                          sensorColor: sensorColor,
                          modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1),
                          modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                          measureRemapFunc: nil)
    }
    
    
    static func rightForearm(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "forearm.R",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func leftFoot(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "foot.L",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(Float(-163.901).degreesToRadians, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(Float(-90.0).degreesToRadians, 1, 0, 0),
                         measureRemapFunc: { quat in
                            var a = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .zxy)
                            a.x = 0
                            a.y = 0
                            let goal = setFromEuler(a, order: .zxy)
                            return GLKQuaternionMultiply(GLKQuaternionInvert(quat), goal)
                         })
    }
    
    static func rightFoot(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "foot.R",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(Float(-163.901).degreesToRadians, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(Float(-90.0).degreesToRadians, 1, 0, 0),
                         measureRemapFunc: { quat in
                            var a = setFromRotationMatrix(GLKMatrix4MakeWithQuaternion(quat), order: .zxy)
                            a.x = 0
                            a.y = 0
                            let goal = setFromEuler(a, order: .zxy)
                            return GLKQuaternionMultiply(GLKQuaternionInvert(quat), goal)
                         })
    }
    
    static func leftHand(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "hand.L",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func rightHand(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "hand.R",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func leftWrist(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "forearm.L",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    
    static func rightWrist(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "forearm.R",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func upperBack(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "chest",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func abdomen(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "abdomen2",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func lowerBack(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "hips",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func head(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "head",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionIdentity,
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: { quat in
                            let goal = GLKQuaternionMakeWithAngleAndAxis(.pi/2, 1, 0, 0)
                            return GLKQuaternionMultiply(GLKQuaternionInvert(quat), goal)
                         })
    }
    static func leftWristForearm(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "forearm.L",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
    
    static func rightWristForearm(_ sensorColor: SensorColor) -> ModelInfo {
        return ModelInfo(nodeName: "forearm.R",
                         sensorColor: sensorColor,
                         modelRemap: GLKQuaternionMakeWithAngleAndAxis(.pi, 1, 0, 0),
                         modelZero: GLKQuaternionMakeWithAngleAndAxis(-.pi/2, 1, 0, 0),
                         measureRemapFunc: nil)
    }
}

struct CameraPosition {
    let fieldOfView: CGFloat
    let position: SCNVector3
    let orientation: SCNQuaternion
}

/// Culmination of all things needed to define and process an individual joint
struct JointConfig: Hashable {
    static func == (lhs: JointConfig, rhs: JointConfig) -> Bool {
        return lhs.joint == rhs.joint && lhs.side == rhs.side
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(joint)
        hasher.combine(side)
    }
    
    let joint: Joint
    let side: Side
    let color: UIColor
    let icon: UIImage
    let placementImage: UIImage
    let calibrateMessage: String
    let upper: ModelInfo
    let lower: ModelInfo
    let measurements : [MeasurementProcessor]
    let handPosition: [String: GLKQuaternion]
    let palmPosition: [String: GLKQuaternion]
    let defaultCamera: CameraPosition
    
    var canTableCalibrate: Bool {
        return upper.measureRemapFunc == nil && lower.measureRemapFunc == nil
    }
    
    static let leftKnee = JointConfig(joint: .knee,
                                      side: .left,
                                      color: .leftKnee,
                                      icon: UIImage(named: "kneeFreeform")!,
                                      placementImage: UIImage(named: "leftKneePlacement")!,
                                      calibrateMessage: "Once the sensors are attached correctly, you may calibrate in any position.",
                                      upper: ModelInfo.leftThigh(.green),
                                      lower: ModelInfo.leftShin(.blue),
                                      measurements: [.kneeFlexionExtension],
                                      handPosition: handFlat,
                                      palmPosition: palmUpElbowBent,
                                      //defaultCamera: CameraPosition(
                                      //  fieldOfView: 49.87247085571289,
                                      //  position: SCNVector3(4.3143954, 2.2754114, 3.1166797),
                                      //  orientation: SCNQuaternion(-0.0011206875, 0.55944216, 0.018824596, 0.8286554)))
                                      defaultCamera: CameraPosition(
                                        fieldOfView: 58.108497619628906,
                                        position: SCNVector3(4.316896, 2.9871533, 3.0668705),
                                        orientation: SCNQuaternion(-0.001120683, 0.5594422, 0.018824609, 0.8286548)))
    
    static let rightKnee = JointConfig(joint: .knee,
                                       side: .right,
                                       color: .rightKnee,
                                       icon: UIImage(named: "kneeFreeform")!,
                                       placementImage: UIImage(named: "rightKneePlacement")!,
                                       calibrateMessage: "Once the sensors are attached correctly, you may calibrate in any position.",
                                       upper: ModelInfo.rightThigh(.green),
                                       lower: ModelInfo.rightShin(.blue),
                                       measurements: [.kneeFlexionExtension],
                                       handPosition: handFlat,
                                       palmPosition: palmUpElbowBent,
                                       //defaultCamera: CameraPosition(
                                       // fieldOfView: 46.824920654296875,
                                       // position: SCNVector3(-4.8134656, 2.9802449, 1.6041354),
                                       // orientation: SCNQuaternion(-0.062821604, -0.6589542, -0.048904326, 0.747958)))
                                       defaultCamera: CameraPosition(
                                        fieldOfView: 60.757511138916016,
                                        position: SCNVector3(-4.316896, 2.9871533, 3.0668705),
                                        orientation: SCNQuaternion(-0.002343482, -0.55185524, -0.020067018, 0.91972524)))
    
    static let leftElbow = JointConfig(joint: .elbow,
                                       side: .left,
                                       color: .leftElbow,
                                       icon: UIImage(named: "elbowFreeform")!,
                                       placementImage: UIImage(named: "leftElbowPlacement")!,
                                       calibrateMessage: "Once the sensors are attached correctly, you may calibrate in any position.",
                                       upper: ModelInfo.leftBiceps(.green),
                                       lower: ModelInfo.leftForearm(.blue),
                                       measurements: [.elbowFlexionExtension],
                                       handPosition: handFlat,
                                       palmPosition: palmUpElbowBent,
                                       //defaultCamera: CameraPosition(
                                       // fieldOfView: 45.84538650512695,
                                       // position: SCNVector3(4.094024, 5.195616, 2.84524),
                                       // orientation: SCNQuaternion(-0.1022786, 0.4718051, 0.055211827, 0.8740084)))
                                       defaultCamera: CameraPosition(
                                        fieldOfView: 38.889015197753906,
                                        position: SCNVector3(4.0064163, 5.346501, 2.9134667),
                                        orientation: SCNQuaternion(-0.10227859, 0.4718051, 0.055211823, 0.8740084)))
    
    static let rightElbow = JointConfig(joint: .elbow,
                                        side: .right,
                                        color: .rightElbow,
                                        icon: UIImage(named: "elbowFreeform")!,
                                        placementImage: UIImage(named: "rightElbowPlacement")!,
                                        calibrateMessage: "Once the sensors are attached correctly, you may calibrate in any position.",
                                        upper: ModelInfo.rightBiceps(.green),
                                        lower: ModelInfo.rightForearm(.blue),
                                        measurements: [.elbowFlexionExtension],
                                        handPosition: handFlat,
                                        palmPosition: palmUpElbowBent,
                                        //defaultCamera: CameraPosition(
                                        //    fieldOfView: 45.2827033996582,
                                        //    position: SCNVector3(-4.427582, 4.751155, 2.5261765),
                                        //    orientation: SCNQuaternion(-0.04574767, -0.5149195, -0.027532877, 0.855574)))
                                        defaultCamera: CameraPosition(
                                            fieldOfView: 42.24189758300781,
                                            position: SCNVector3(-4.0075834, 5.344015, 2.9158186),
                                            orientation: SCNQuaternion(-0.102247664, -0.4749195, -0.055232876, 0.875574)))
    
    static let leftAnkle = JointConfig(joint: .ankle,
                                       side: .left,
                                       color: .leftAnkle,
                                       icon: UIImage(named: "ankleFlexion")!,
                                       placementImage: UIImage(named: "leftAnklePlacement")!,
                                       calibrateMessage: "Once the sensors are attached correctly, keep foot flat on floor during calibration.",
                                       upper: ModelInfo.leftShin(.green),
                                       lower: ModelInfo.leftFoot(.blue),
                                       measurements: [.ankleFlexionExtension, .leftAnkleEversionInversion],
                                       handPosition: handFlat,
                                       palmPosition: palmUpElbowBent,
                                       //defaultCamera: CameraPosition(
                                       // fieldOfView: 21.2653865814209,
                                       // position: SCNVector3(2.625165, 3.5865273, 5.2120605),
                                       // orientation: SCNQuaternion(-0.22151478, 0.20855443, 0.048559967, 0.95135593)))
                                       defaultCamera: CameraPosition(
                                        fieldOfView: 13.92540454864502,
                                        position: SCNVector3(2.4069598, 3.275443, 5.481194),
                                        orientation: SCNQuaternion(-0.22151478, 0.2085544, 0.048559967, 0.95135593)))
    
    static let rightAnkle = JointConfig(joint: .ankle,
                                        side: .right,
                                        color: .rightAnkle,
                                        icon: UIImage(named: "ankleFlexion")!,
                                        placementImage: UIImage(named: "rightAnklePlacement")!,
                                        calibrateMessage: "Once the sensors are attached correctly, keep foot flat on floor during calibration.",
                                        upper: ModelInfo.rightShin(.green),
                                        lower: ModelInfo.rightFoot(.blue),
                                        measurements: [.ankleFlexionExtension, .rightAnkleEversionInversion],
                                        handPosition: handFlat,
                                        palmPosition: palmUpElbowBent,
                                        //defaultCamera: CameraPosition(
                                        //    fieldOfView: 27.610374450683594,
                                        //    position: SCNVector3(-2.5881476, 3.059045, 5.189742),
                                        //    orientation: SCNQuaternion(-0.14926834, -0.24384156, -0.038013216, 0.9575047)))
                                        defaultCamera: CameraPosition(
                                            fieldOfView: 14.295616149902344,
                                            position: SCNVector3(-3.6718557, 2.2619731, 6.256153),
                                            orientation: SCNQuaternion(-0.11149455, -0.26701632, -0.038798228, 0.9564337)))
    
    static let leftWrist = JointConfig(joint: .wrist,
                                       side: .left,
                                       color: .leftWrist,
                                       icon: UIImage(named: "wristFlexion")!,
                                       placementImage: UIImage(named: "leftWristPlacement")!,
                                       calibrateMessage: "Once the sensors are attached correctly, keep wrist straight during calibration.",
                                       upper: ModelInfo.leftWrist(.green),
                                       lower: ModelInfo.leftHand(.blue),
                                       measurements: [.wristFlexionExtension, .leftRadialUlnar],
                                       handPosition: handFlat,
                                       palmPosition: palmDownElbowBent,
                                       //defaultCamera: CameraPosition(
                                       // fieldOfView: 33.12105941772461,
                                       // position: SCNVector3(2.9393492, 5.2543344, 4.112467),
                                       // orientation: SCNQuaternion(-0.13730897, 0.33623242, 0.049621735, 0.93039334)))
                                       defaultCamera: CameraPosition(
                                        fieldOfView: 21.382535934448242,
                                        position: SCNVector3(3.0043373, 5.1205397, 4.2058487),
                                        orientation: SCNQuaternion(-0.111709476, 0.30568624, 0.036140647, 0.9448655)))
    
    static let rightWrist = JointConfig(joint: .wrist,
                                        side: .right,
                                        color: .rightWrist,
                                        icon: UIImage(named: "wristFlexion")!,
                                        placementImage: UIImage(named: "rightWristPlacement")!,
                                        calibrateMessage: "Once the sensors are attached correctly, keep wrist straight during calibration.",
                                        upper: ModelInfo.rightWrist(.green),
                                        lower: ModelInfo.rightHand(.blue),
                                        measurements: [.wristFlexionExtension, .rightRadialUlnar],
                                        handPosition: handFlat,
                                        palmPosition: palmDownElbowBent,
                                        //defaultCamera: CameraPosition(
                                        //fieldOfView: 34.85178756713867,
                                        //position: SCNVector3(-3.0860724, 5.7708774, 3.5667162),
                                        //orientation: SCNQuaternion(-0.18521315, -0.37984058, -0.07791157, 0.90296566)))
                                        defaultCamera: CameraPosition(
                                            fieldOfView: 20.947280883789062,
                                            position: SCNVector3(-2.728323, 5.699911, 3.967744),
                                            orientation: SCNQuaternion(-0.18594378, -0.29507038, -0.058657512, 0.9353703)))
    
    static let leftShoulder = JointConfig(joint: .shoulder,
                                          side: .left,
                                          color: .leftShoulder,
                                          icon: UIImage(named: "shoulderAbduction")!,
                                          placementImage: UIImage(named: "leftShoulderPlacement")!,
                                          calibrateMessage: "Once the sensors are attached, keep arm at side with palm facing forward during calibration.",
                                          upper: ModelInfo.upperBack(.green),
                                          lower: ModelInfo.leftTriceps(.blue),
                                          measurements: [.shoulderFlexionExtension, .leftAbductionAdduction],
                                          handPosition: handFlat,
                                          palmPosition: palmDownElbowStraight,
                                          //defaultCamera: CameraPosition(
                                          //  fieldOfView: 49.2843132019043,
                                          //  position: SCNVector3(0.08792614, 4.9827213, 5.3895617),
                                          //  orientation: SCNQuaternion(-0.08095897, -0.012726146, -0.0010337736, 0.9966356)))
                                          defaultCamera: CameraPosition(
                                            fieldOfView: 49.13054275512695,
                                            position: SCNVector3(-0.18922174, 5.7250814, 5.3227806),
                                            orientation: SCNQuaternion(-0.07827478, -0.109822325, -0.008675909, 0.9908263)))
    
    static let rightShoulder = JointConfig(joint: .shoulder,
                                           side: .right,
                                           color: .rightShoulder,
                                           icon: UIImage(named: "shoulderAbduction")!,
                                           placementImage: UIImage(named: "rightShoulderPlacement")!,
                                           calibrateMessage: "Once the sensors are attached, keep arm at side with palm facing forward during calibration.",
                                           upper: ModelInfo.upperBack(.green),
                                           lower: ModelInfo.rightTriceps(.blue),
                                           measurements: [.shoulderFlexionExtension, .rightAbductionAdduction],
                                           handPosition: handFlat,
                                           palmPosition: palmDownElbowStraight,
                                           //defaultCamera: CameraPosition(
                                           // fieldOfView: 49.210205078125,
                                           // position: SCNVector3(-0.21399418, 5.263331, 5.26759),
                                           // orientation: SCNQuaternion(-0.11068854, -0.016987886, -0.0018923121, 0.99370813)))
                                           defaultCamera: CameraPosition(
                                            fieldOfView: 49.13054275512695,
                                            position: SCNVector3(-0.18922174, 5.7250814, 5.3227806),
                                            orientation: SCNQuaternion(-0.11010192, 0.109629995, -0.008675909, 0.9921902)))
    
    static let rightHip = JointConfig(joint: .hip,
                                      side: .right,
                                      color: .rightHip,
                                      icon: UIImage(named: "hipAbduction")!,
                                      placementImage: UIImage(named: "rightHipPlacement")!,
                                      calibrateMessage: "Once the sensors are attached correctly, you may calibrate in any position.",
                                      upper: ModelInfo.lowerBack(.green),
                                      lower: ModelInfo.rightThigh(.blue),
                                      measurements: [.hipFlexionExtension, .rightHipAbductionAdduction],
                                      handPosition: handFlat,
                                      palmPosition: palmDownElbowStraight,
                                      //defaultCamera: CameraPosition(
                                      //  fieldOfView: 50.56605911254883,
                                      //  position: SCNVector3(-2.9883027, 3.217298, 4.685836),
                                      //  orientation: SCNQuaternion(-0.052022394, -0.3015021, -0.01647743, 0.9519027)))
                                      defaultCamera: CameraPosition(
                                        fieldOfView: 67.72817993164062,
                                        position: SCNVector3(-3.013229, 3.409077, 4.6571226),
                                        orientation: SCNQuaternion(-0.053758707, -0.27729285, -0.007659575, 0.9592497)))
    
    static let leftHip = JointConfig(joint: .hip,
                                     side: .left,
                                     color: .leftHip,
                                     icon: UIImage(named: "hipAbduction")!,
                                     placementImage: UIImage(named: "leftHipPlacement")!,
                                     calibrateMessage: "Once the sensors are attached correctly, you may calibrate in any position.",
                                     upper: ModelInfo.lowerBack(.green),
                                     lower: ModelInfo.leftThigh(.blue),
                                     measurements: [.hipFlexionExtension, .leftHipAbductionAdduction],
                                     handPosition: handFlat,
                                     palmPosition: palmDownElbowStraight,
                                     //defaultCamera: CameraPosition(
                                     //   fieldOfView: 49.210205078125,
                                     //   position: SCNVector3(2.311909, 2.445241, 5.0425),
                                     //   orientation: SCNQuaternion(0.0070589595, 0.25370038, -0.0018515441, 0.96725535)))
                                     defaultCamera: CameraPosition(
                                        fieldOfView: 67.72817993164062,
                                        position: SCNVector3(1.5270519, 2.5895963, 5.3325787),
                                        orientation: SCNQuaternion(0.048004407, 0.1441052, -0.020149471, 0.9881917)))
    
    static let neck = JointConfig(joint: .neck,
                                  side: .none,
                                  color: .neck,
                                  icon: UIImage(named: "neckFlexion")!,
                                  placementImage: UIImage(named: "neckPlacement")!,
                                  calibrateMessage: "Once the sensors are attached correctly, keep head straight in all directions during calibration.",
                                  upper: ModelInfo.upperBack(.green),
                                  lower: ModelInfo.head(.blue),
                                  measurements: [.neckFlexionExtension, .rotation, .lateralFlexion],
                                  handPosition: handFlat,
                                  palmPosition: palmDownElbowStraight,
                                  //defaultCamera: CameraPosition(
                                  //  fieldOfView: 22.15599822998047,
                                  //  position: SCNVector3(-0.15039995, 5.350732, 5.5530424),
                                  //  orientation: SCNQuaternion(-0.02279445, -0.01599192, -0.00036466884, 0.99961215)))
                                  defaultCamera: CameraPosition(
                                    fieldOfView: 20.50242805480957,
                                    position: SCNVector3(-0.5483658, 6.0205536, 5.364479),
                                    orientation: SCNQuaternion(-0.046462793, -0.05197546, -0.0024208245, 0.997564)))
    
    static let spine = JointConfig(joint: .spine,
                                   side: .none,
                                   color: .spine,
                                   icon: UIImage(named: "spineExtension")!,
                                   placementImage: UIImage(named: "spinePlacement")!,
                                   calibrateMessage: "Once the sensors are attached correctly, make sure body has no twist during calibration.",
                                   upper: ModelInfo.lowerBack(.green),
                                   lower: ModelInfo.abdomen(.blue),
                                   measurements: [.spineFlexionExtension, .rotation, .spineLateralFlexion],
                                   handPosition: handFlat,
                                   palmPosition: palmDownElbowStraight,
                                   //defaultCamera: CameraPosition(
                                   // fieldOfView: 58.844322204589844,
                                   // position: SCNVector3(-4.459581, 3.4092145, 1.4243606),
                                   // orientation: SCNQuaternion(0.013506851, -0.6215149, 0.010718354, 0.7832126)))
                                   defaultCamera: CameraPosition(
                                    fieldOfView: 52.70718765258789,
                                    position: SCNVector3(0.39731306, 5.35863, -4.156118),
                                    orientation: SCNQuaternion(0.027040487, 0.994103, 0.09974287, 0.03282767)))
    
    static let lookup: [Joint : [Side: JointConfig]] = [
        .knee: [.left : .leftKnee, .right : .rightKnee],
        .elbow: [.left : .leftElbow, .right : .rightElbow],
        .ankle: [.left : .leftAnkle, .right : .rightAnkle],
        .wrist: [.left : .leftWrist, .right : .rightWrist],
        .shoulder: [.left : .leftShoulder, .right : .rightShoulder],
        .hip: [.left : .leftHip, .right : .rightHip],
        .neck: [.none : .neck],
        .spine: [.none : .spine],
    ]
}


fileprivate let palmUpElbowBent = [
    "forearm.R": GLKQuaternionMake(sqrt(2)/2, 0.0, 0.0, sqrt(2)/2),
    "forearm.L": GLKQuaternionMake(sqrt(2)/2, 0.0, 0.0, sqrt(2)/2),
]

fileprivate let palmDownElbowBent = [
    "forearm.R": GLKQuaternionMake(0.0, sqrt(2)/2, sqrt(2)/2, 0.0),
    "forearm.L": GLKQuaternionMake(0.0, sqrt(2)/2, sqrt(2)/2, 0.0),
]

fileprivate let palmDownElbowStraight = [
    "forearm.R": GLKQuaternionMake(0.0, 1, 0.0, 0.0),
    "forearm.L": GLKQuaternionMake(0.0, 1, 0.0, 0.0),
]

// Orientation of hand joints that produces a fist
fileprivate let handFist = [
    "f_index.01.L": GLKQuaternionMake(0.741522, 0.0944884, -0.0468865, 0.662585),
    "f_index.02.L": GLKQuaternionMake(0.654952, 0.000336068, -0.000292684, 0.75567),
    "f_index.03.L": GLKQuaternionMake(-0.0053583, -0.0010715, -0.000163912, 0.999985),
    "thumb.01.L": GLKQuaternionMake(-0.0158111, 0.42842, 0.333483, 0.83964),
    "thumb.02.L": GLKQuaternionMake(0.195869, 0.206207, -0.133154, 0.949412),
    "thumb.03.L": GLKQuaternionMake(0.249708, 0.0161965, -0.0464654, 0.96707),
    "f_middle.01.L": GLKQuaternionMake(0.763118, 0.0381359, 0.0269593, 0.64457),
    "f_middle.02.L": GLKQuaternionMake(0.640538, -0.00106183, 0.000886884, 0.767925),
    "f_middle.03.L": GLKQuaternionMake(-0.0438118, -0.00309399, -0.000617596, 0.999035),
    "f_ring.01.L": GLKQuaternionMake(0.766734, 0.0114098, 0.100653, 0.633922),
    "f_ring.02.L": GLKQuaternionMake(0.635196, -0.000193005, 0.000159111, 0.772351),
    "f_ring.03.L": GLKQuaternionMake(-0.0238974, -0.00044937, 0.00713947, 0.999689),
    "f_pinky.01.L": GLKQuaternionMake(0.727327, -0.0456201, 0.163547, 0.664957),
    "f_pinky.02.L": GLKQuaternionMake(0.682681, -0.000128577, 0.000121528, 0.730717),
    "f_pinky.03.L": GLKQuaternionMake(-0.0667922, -0.00136547, 0.0147125, 0.997658),
    "f_index.01.R": GLKQuaternionMake(0.741522, -0.0944884, 0.0468865, 0.662585),
    "f_index.02.R": GLKQuaternionMake(0.654952, -0.000333728, 0.000293561, 0.75567),
    "f_index.03.R": GLKQuaternionMake(-0.0053583, 0.00106566, 0.000160236, 0.999985),
    "thumb.01.R": GLKQuaternionMake(-0.0158111, -0.42842, -0.333483, 0.83964),
    "thumb.02.R": GLKQuaternionMake(0.195869, -0.206207, 0.133154, 0.949412),
    "thumb.03.R": GLKQuaternionMake(0.249708, -0.0161965, 0.0464654, 0.96707),
    "f_middle.01.R": GLKQuaternionMake(0.763119, -0.0381193, -0.0270017, 0.644568),
    "f_middle.02.R": GLKQuaternionMake(0.640538, 0.00106281, -0.000886506, 0.767925),
    "f_middle.03.R": GLKQuaternionMake(-0.0438118, 0.00309399, 0.000617596, 0.999035),
    "f_ring.01.R": GLKQuaternionMake(0.766734, -0.0114098, -0.100653, 0.633922),
    "f_ring.02.R": GLKQuaternionMake(0.635196, 0.000193088, -0.000158799, 0.772351),
    "f_ring.03.R": GLKQuaternionMake(-0.0239002, 0.00044939, -0.00713947, 0.999689),
    "f_pinky.01.R": GLKQuaternionMake(0.727327, 0.0456201, -0.163547, 0.664957),
    "f_pinky.02.R": GLKQuaternionMake(0.682681, 0.000128971, -0.000120493, 0.730717),
    "f_pinky.03.R": GLKQuaternionMake(-0.066791, 0.00136545, -0.0147125, 0.997658),
]

// Orientation of hand joints that produces a flat, open hand
fileprivate let handFlat = [
    "f_index.01.L": GLKQuaternionMake(-0.0392024, 0.0962252, 0.0431593, 0.99365),
    "f_index.02.L": GLKQuaternionMake(0.0, 0.0004455, 0.0, 1.0),
    "f_index.03.L": GLKQuaternionMake(-0.0748382, -0.00105195, -0.000233906, 0.997195),
    "thumb.01.L": GLKQuaternionMake(-0.048714, 0.572325, 0.350899, 0.739555),
    "thumb.02.L": GLKQuaternionMake(0.0, -0.0185062, 0.0, 0.999829),
    "thumb.03.L": GLKQuaternionMake(-0.087747, 0.0297791, -0.0412372, 0.994843),
    "f_middle.01.L": GLKQuaternionMake(-0.0349691, 0.00233748, 0.0466552, 0.998296),
    "f_middle.02.L": GLKQuaternionMake(0.0, -0.001383, 0.0, 0.999999),
    "f_middle.03.L": GLKQuaternionMake(-0.0438118, -0.00309399, -0.000617596, 0.999035),
    "f_ring.01.L": GLKQuaternionMake(-0.0291288, -0.117259, 0.0505079, 0.991388),
    "f_ring.02.L": GLKQuaternionMake(0.0, -0.00025, 0.0, 1.0),
    "f_ring.03.L": GLKQuaternionMake(-0.0239002, -0.00044939, 0.00713947, 0.999689),
    "f_pinky.01.L": GLKQuaternionMake(-0.0253989, -0.188667, 0.0524827, 0.980309),
    "f_pinky.02.L": GLKQuaternionMake(0.0, -0.0001765, 0.0, 1.0),
    "f_pinky.03.L": GLKQuaternionMake(-0.066791, -0.00136545, 0.0147125, 0.997658),
    "f_index.01.R": GLKQuaternionMake(-0.0392024, -0.0962252, -0.0431593, 0.99365),
    "f_index.02.R": GLKQuaternionMake(0.0, -0.0004455, 0.0, 1.0),
    "f_index.03.R": GLKQuaternionMake(-0.0748382, 0.00105195, 0.000233906, 0.997195),
    "thumb.01.R": GLKQuaternionMake(-0.0487141, -0.572325, -0.350898, 0.739555),
    "thumb.02.R": GLKQuaternionMake(0.0, 0.0185062, 0.0, 0.999829),
    "thumb.03.R": GLKQuaternionMake(-0.0878598, -0.0303677, 0.0416615, 0.994798),
    "f_middle.01.R": GLKQuaternionMake(-0.0349691, -0.00233748, -0.0466552, 0.998296),
    "f_middle.02.R": GLKQuaternionMake(0.0, 0.001384, 0.0, 0.999999),
    "f_middle.03.R": GLKQuaternionMake(-0.0438118, 0.00309399, 0.000617596, 0.999035),
    "f_ring.01.R": GLKQuaternionMake(-0.0291288, 0.117259, -0.0505079, 0.991388),
    "f_ring.02.R": GLKQuaternionMake(0.0, 0.00025, 0.0, 1.0),
    "f_ring.03.R": GLKQuaternionMake(-0.0239002, 0.00044939, -0.00713947, 0.999689),
    "f_pinky.01.R": GLKQuaternionMake(-0.0253989, 0.188667, -0.0524827, 0.980309),
    "f_pinky.02.R": GLKQuaternionMake(0.0, 0.0001765, 0.0, 1.0),
    "f_pinky.03.R": GLKQuaternionMake(-0.066791, 0.00136545, -0.0147125, 0.997658),
]
