//
//  QuaternionStream.swift
//  RangeOfMotion
//
//  Created by Stephen Schiffli on 1/5/18.
//  Copyright © 2018 Stephen Schiffli. All rights reserved.
//

import MetaWear
import MetaWearCpp
import BoltsSwift
import CoreBluetooth
import GLKit
import SceneKit


protocol QuaternionStreamDelegate: class {
    func didFinish(_ dataCapture: QuaternionStream, error: Error?)
    func newSample(_ dataCapture: QuaternionStream, quat: GLKQuaternion)
    func connecting(_ dataCapture: QuaternionStream)
}

fileprivate let accelRange = MBL_MW_SENSOR_FUSION_ACC_RANGE_16G
fileprivate let gyroRange = MBL_MW_SENSOR_FUSION_GYRO_RANGE_2000DPS
fileprivate let sensorFusionMode = MBL_MW_SENSOR_FUSION_MODE_IMU_PLUS
fileprivate let fusionSignal = MBL_MW_SENSOR_FUSION_DATA_QUATERNION
fileprivate typealias FusionType = MblMwQuaternion

extension MetaWear {
    var scanResponsePayload: UInt8? {
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if manufacturerData.count >= 3 {
                if manufacturerData[0] == 0x7E &&
                    manufacturerData[1] == 0x06 &&
                    manufacturerData[2] == 0x04 {
                    return manufacturerData[3]
                }
            }
        }
        return nil
    }
}

class QuaternionStream {
    let device: MetaWear
    var started: Bool = false
    var abort: Bool = false
    weak var delegate: QuaternionStreamDelegate?
    
    init(_ device: MetaWear) {
        let deviceId = device.scanResponsePayload ?? 0
        if deviceId == 2 {
            device.deserialize(Globals.state1_5_0)
        } else if deviceId == 1  {
            device.deserialize(Globals.state1_4_4)
        } else {
            device.deserialize(Globals.state1_4_97)
        }
        self.device = device
    }
    
//    deinit {
//        if let signal = mbl_mw_dataprocessor_lookup_id(device.board, Globals.quaternionAverageId) {
//            mbl_mw_datasignal_unsubscribe(signal)
//        }
//    }
//
    
    /// Flash LED blue
    func ledBlueDuringStreaming(_ device: MetaWear) {
        device.flashLED(color: .blue, intensity: 0.75, _repeat: 0xFF, onTime: 200, period: 3000)
    }
    
    /// Flash LED green
    func ledGreenDuringStreaming(_ device: MetaWear) {
        device.flashLED(color: .green, intensity: 0.75, _repeat: 0xFF, onTime: 200, period: 3000)
    }
    
    func setupQuicky(device: MetaWear) {
        device.connectAndSetup().continueOnSuccessWithTask(.mainThread) { t -> Task<Void> in
            //print("SETUP QUICKLY")
            self.ledBlueDuringStreaming(device)
            return Task<Void>.withDelay(1.0)
        }.continueWith(.mainThread) { t -> Task<OpaquePointer> in
            // Get the sensor fusion signal
            //print("SETUP AVERAGER PROC")
            let signal = mbl_mw_sensor_fusion_get_data_signal(device.board, fusionSignal)!
            let filterId: UInt8 = 26 //quaternion averager
            // Create a quaternion averager
            return signal.quaternionAverageCreate(2, filterId)
        }.continueOnSuccessWith(device.apiAccessExecutor) { filter in
            //print("SETUP SENSOR FUSION")
            // Set up the sensor for sensor fusion
            mbl_mw_sensor_fusion_set_acc_range(device.board, accelRange)
            mbl_mw_sensor_fusion_set_gyro_range(device.board, gyroRange)
            mbl_mw_sensor_fusion_set_mode(device.board, sensorFusionMode)
            mbl_mw_sensor_fusion_write_config(device.board)
        }.continueWith(.mainThread) { t in
            
        }
    }
    
    func stopStream() {
        started = false
        abort = true
        device.turnOffLed()
        device.clearAndReset()
        print("reset board")
        //device.cancelConnection()
    }
    
    func startStream(upper: Bool) {
        guard !started else {
            return
        }
        abort = false
        started = true
        delegate?.connecting(self)
        device.connectAndSetup().continueWith(.mainThread) { t in
            guard !t.faulted && !t.cancelled else {
                self.started = false
                self.delegate?.didFinish(self, error: t.error)
                return
            }
            let board = self.device.board
            // Pop out if no sensor fusion
            guard mbl_mw_metawearboard_lookup_module(board, MBL_MW_MODULE_SENSOR_FUSION) != MBL_MW_MODULE_TYPE_NA else {
                self.started = false
                self.delegate?.didFinish(self, error: MetaWearError.operationFailed(message: "No sensor fusion module"))
                return
            }
            if upper {
                self.device.flashLED(color: .green, intensity: 0.75, _repeat: 0xFF, onTime: 200, period: 1500)
            } else {
                self.device.flashLED(color: .blue, intensity: 0.75, _repeat: 0xFF, onTime: 200, period: 1500)
            }
            // Reconnect if not told to abort
        }.continueOnSuccessWithTask(device.apiAccessExecutor) { t -> Task<OpaquePointer> in
            let board = self.device.board
            // Create quaternion averager signal
            let signal = mbl_mw_sensor_fusion_get_data_signal(board, fusionSignal)!
            let filterId: UInt8 = 26
            return signal.quaternionAverageCreate(2, filterId)
        }.continueOnSuccessWith(device.apiAccessExecutor) { filter in
            print(filter)
            let board = self.device.board
            // Setup up sensor fusion sensots
            mbl_mw_sensor_fusion_set_acc_range(board, accelRange)
            mbl_mw_sensor_fusion_set_gyro_range(board, gyroRange)
            mbl_mw_sensor_fusion_set_mode(board, sensorFusionMode)
            mbl_mw_sensor_fusion_write_config(board)
            // Subscribe to the averaged quaternion signal
            mbl_mw_datasignal_subscribe(filter, bridge(obj: self)) { (contextPtr, dataPtr) in
            //mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (contextPtr, dataPtr) in
                let _self: QuaternionStream = bridge(ptr: contextPtr!)
                let quat = GLKQuaternion((dataPtr!.pointee.valueAs() as FusionType))
                DispatchQueue.main.async {
                    _self.delegate?.newSample(_self, quat: quat)
                }
            }
            //mbl_mw_macro_execute(board, Globals.streamStateId)
            mbl_mw_sensor_fusion_enable_data(board, fusionSignal)
            mbl_mw_sensor_fusion_start(board)
        }.continueOnSuccessWith(.mainThread) { t in
            // Inform the delegate we have finished setup
            self.delegate?.didFinish(self, error: nil)
        }
    }
    
    func didAbsoluteCalibration() {
        guard device.isConnectedAndSetup else {
            return
        }
        mbl_mw_debug_set_key_register(device.board, 0xCAFEBABE)
    }
    
    func getBatteryCharge() -> Task<UInt8> {
        guard device.isConnectedAndSetup else {
            return Task<UInt8>(error: MetaWearError.operationFailed(message: "not connected"))
        }
        guard let battery = mbl_mw_settings_get_battery_state_data_signal(device.board) else {
            return Task<UInt8>(error: MetaWearError.operationFailed(message: "no battery signal"))
        }
        return battery.read().continueOnSuccessWith { raw in
            let state: MblMwBatteryState = raw.valueAs()
            return state.charge
        }
    }
    
    func isAbsoluteCalibrated() -> Task<Bool> {
        guard device.isConnectedAndSetup else {
            return Task<Bool>(error: MetaWearError.operationFailed(message: "not connected"))
        }
        return mbl_mw_debug_get_key_register_data_signal(device.board).read().continueOnSuccessWith { result in
            let value: UInt32 = result.valueAs()
            return value == 0xCAFEBABE
        }
    }
    
    func getAccuracy() -> Task<MblMwCalibrationState> {
        guard device.isConnectedAndSetup else {
            return Task<MblMwCalibrationState>(error: MetaWearError.operationFailed(message: "not connected"))
        }
        return mbl_mw_sensor_fusion_calibration_state_data_signal(device.board).read().continueOnSuccessWith { result in
            let state: MblMwCalibrationState = result.valueAs()
            return state
        }
    }
}

extension GLKQuaternion {
    init(_ quat: MblMwQuaternion) {
        let tempy = GLKVector3Make(quat.x,quat.y,quat.z)
        //self.init(__Unnamed_struct___Anonymous_field1(x: quat.x, y: quat.y, z: quat.z, w: quat.w))
        self.init(__Unnamed_struct___Anonymous_field1(v: tempy, s: quat.w))
    }
}

extension OpaquePointer {
    public func quaternionAverageCreate(_ depth: UInt8, _ filterId: UInt8) -> Task<OpaquePointer> {
        let source = TaskCompletionSource<OpaquePointer>()
        mbl_mw_dataprocessor_quaternion_average_create(self, depth, filterId, bridgeRetained(obj: source)) { (context, counter) in
            let source: TaskCompletionSource<OpaquePointer> = bridgeTransfer(ptr: context!)
            if let counter = counter {
                source.trySet(result: counter)
            } else {
                source.trySet(error: MetaWearError.operationFailed(message: "could not create quaternion average"))
            }
        }
        return source.task
    }
}

//            self.device.logDelegate = ConsoleLogger.shared
//            let minGyro: Float = -32768 / 16.4
//            let maxGyro: Float = 32767 / 16.4
//            let gyro = mbl_mw_gyro_bmi160_get_rotation_data_signal(board)!
//            for i in 0...2 {
//                let gyroX = mbl_mw_datasignal_get_component(gyro, UInt8(i))!
//                gyroX.comparatorCreate(op: MBL_MW_COMPARATOR_OP_EQ, mode: MBL_MW_COMPARATOR_MODE_BINARY, references: [minGyro, maxGyro]).continueWith { t in
//                    self.device.logDelegate = nil
//
//                    if let filter = t.result {
//                        mbl_mw_datasignal_subscribe(filter, nil, { (ctx, data) in
//                            let ef: UInt32 = data!.pointee.valueAs()
//                            if ef != 0 {
//                                print("maxd")
//                            }
//                        })
//                    }
//                }
//            }
