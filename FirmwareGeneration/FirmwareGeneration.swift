//
//  FirmwareGeneration.swift
//
//
//  Created by Stephen Schiffli on 7/18/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import BoltsSwift
import MetaWear
import MetaWearCpp
import CoreBluetooth
@testable import MetaClinic


/// Connect to a MetaWear close to the test host
func connectNearest() -> Task<MetaWear> {
    let source = TaskCompletionSource<MetaWear>()
    MetaWearScanner.shared.startScan(allowDuplicates: true) { (device) in
        if let rssi = device.averageRSSI(), rssi > -50 {
            MetaWearScanner.shared.stopScan()
            device.connectAndSetup().continueWith { t -> () in
                if let error = t.error {
                    source.trySet(error: error)
                } else {
                    source.trySet(result: device)
                }
            }
        }
    }
    return source.task
}

/// ID's of macro functions we may need to call
enum MacroID: UInt8 {
    case boot = 0
    case waitState = 1
    case streamState = 2
    case sleepOnButtonReleaseState = 3
    case pluggedInState = 4
}

let accelRange = MBL_MW_SENSOR_FUSION_ACC_RANGE_16G
let gyroRange = MBL_MW_SENSOR_FUSION_GYRO_RANGE_2000DPS
let sensorFusionMode = MBL_MW_SENSOR_FUSION_MODE_IMU_PLUS
let fusionSignal = MBL_MW_SENSOR_FUSION_DATA_QUATERNION

/// Objects that we create on boot and persist forever
struct FirmwareObjects {
    let timeoutTimer: OpaquePointer
    let powerToggleTimer: OpaquePointer
    let buttonPressed: OpaquePointer
    let buttonReleased: OpaquePointer
    let quaternionAverage: OpaquePointer!
    let powerSourcePresent: OpaquePointer
    let powerSourceAbsent: OpaquePointer
    let batteryCharging: OpaquePointer
    let batteryNotCharging: OpaquePointer
}

/// Create the FirmwareObjects
func createGlobalObjects(_ device: MetaWear) -> Task<FirmwareObjects> {
    var timeoutTimer: OpaquePointer!
    var powerToggleTimer: OpaquePointer!
    var buttonPressed: OpaquePointer!
    var buttonReleased: OpaquePointer!
    var quaternionAverage: OpaquePointer!
    var powerSourcePresent: OpaquePointer!
    var powerSourceAbsent: OpaquePointer!
    var batteryCharging: OpaquePointer!
    var batteryNotCharging: OpaquePointer!
    
    let button = mbl_mw_switch_get_state_data_signal(device.board)!
    let powerStatus = mbl_mw_settings_get_power_status_data_signal(device.board)!
    let chargerStatus = mbl_mw_settings_get_charge_status_data_signal(device.board)!
    
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<OpaquePointer> in
        return device.timerCreate(period: 10*60*1000, repetitions: 1, immediateFire: false)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { timer -> Task<OpaquePointer> in
        timeoutTimer = timer
        return device.timerCreate(period: 600, repetitions: 1, immediateFire: false)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { timer -> Task<OpaquePointer> in
        powerToggleTimer = timer
        // Couple dummy filters to keep quaternion filter at ID 2
        return button.passthroughCreate(mode: MBL_MW_PASSTHROUGH_MODE_CONDITIONAL, count: 0)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { dummyFilter -> Task<OpaquePointer> in
        return button.passthroughCreate(mode: MBL_MW_PASSTHROUGH_MODE_CONDITIONAL, count: 0)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { dummyFilter -> Task<OpaquePointer> in
        let signal = mbl_mw_sensor_fusion_get_data_signal(device.board, fusionSignal)!
        let filterId: UInt8 = device.info?.firmwareRevision == "1.4.97" ? 18 : 26
        return signal.quaternionAverageCreate(2, filterId)
    }.continueOnSuccessWith(device.apiAccessExecutor) { filter -> FirmwareObjects in
        quaternionAverage = filter
        
        mbl_mw_sensor_fusion_set_acc_range(device.board, accelRange)
        mbl_mw_sensor_fusion_set_gyro_range(device.board, gyroRange)
        mbl_mw_sensor_fusion_set_mode(device.board, sensorFusionMode)
        mbl_mw_sensor_fusion_write_config(device.board)
        
        buttonPressed = mbl_mw_make_id_data_signal(device.board, button, 1)
        buttonReleased = mbl_mw_make_id_data_signal(device.board, button, 0)
        powerSourcePresent = mbl_mw_make_id_data_signal(device.board, powerStatus, 1)
        powerSourceAbsent = mbl_mw_make_id_data_signal(device.board, powerStatus, 0)
        batteryCharging = mbl_mw_make_id_data_signal(device.board, chargerStatus, 1)
        batteryNotCharging = mbl_mw_make_id_data_signal(device.board, chargerStatus, 0)
        
        return FirmwareObjects(timeoutTimer: timeoutTimer,
                               powerToggleTimer: powerToggleTimer,
                               buttonPressed: buttonPressed,
                               buttonReleased: buttonReleased,
                               quaternionAverage: quaternionAverage,
                               powerSourcePresent: powerSourcePresent,
                               powerSourceAbsent: powerSourceAbsent,
                               batteryCharging: batteryCharging,
                               batteryNotCharging: batteryNotCharging)
    }
}

func ledDuringWaitState(_ device: MetaWear) {
    device.flashLED(color: .blue, intensity: 0.5, _repeat: 0xFF, onTime: 200, period: 1000)
}

func ledDuringDelayedPowerDown(_ device: MetaWear) {
    var pattern = MblMwLedPattern(high_intensity: UInt8(round(31.0 * 0.8)),
                                  low_intensity: 0,
                                  rise_time_ms: 0,
                                  high_time_ms: 2000,
                                  fall_time_ms: 0,
                                  pulse_duration_ms: 2000,
                                  delay_time_ms: 0,
                                  repeat_count: 0xFF)
    mbl_mw_led_stop_and_clear(device.board)
    mbl_mw_led_write_pattern(device.board, &pattern, MBL_MW_LED_COLOR_BLUE)
    mbl_mw_led_play(device.board)
}

func ledDuringStreaming(_ device: MetaWear) {
    device.flashLED(color: .green, intensity: 0.75, _repeat: 0xFF, onTime: 200, period: 3000)
}

func ledDuringCharging(_ device: MetaWear) {
    let orange = UIColor(red: 0.4, green: 0.6, blue: 0.0, alpha: 1.0)
    device.flashLED(color: orange, intensity: 0.6, _repeat: 0xFF, onTime: 200, period: 2500)
}

func ledDuringCharged(_ device: MetaWear) {
    var pattern = MblMwLedPattern(high_intensity: UInt8(round(31.0 * 0.6)),
                                  low_intensity: 0,
                                  rise_time_ms: 0,
                                  high_time_ms: 2000,
                                  fall_time_ms: 0,
                                  pulse_duration_ms: 2000,
                                  delay_time_ms: 0,
                                  repeat_count: 0xFF)
    mbl_mw_led_stop_and_clear(device.board)
    mbl_mw_led_write_pattern(device.board, &pattern, MBL_MW_LED_COLOR_GREEN)
    mbl_mw_led_play(device.board)
}

func goToSleepIfButtonHeld(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.buttonPressed)
        mbl_mw_timer_start(objs.powerToggleTimer)
        return objs.buttonPressed.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.buttonReleased)
        mbl_mw_timer_stop(objs.powerToggleTimer)
        return objs.buttonReleased.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.powerToggleTimer)
        mbl_mw_macro_execute(device.board, MacroID.sleepOnButtonReleaseState.rawValue)
        return objs.powerToggleTimer.eventEndRecord()
    }
}

func goToSleepIfTimeout(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.timeoutTimer)
        mbl_mw_debug_enable_power_save(device.board)
        mbl_mw_debug_reset(device.board)
        return objs.timeoutTimer.eventEndRecord()
    }.continueOnSuccessWith { _ in
        mbl_mw_timer_start(objs.timeoutTimer)
    }
}

func goToWaitOnDisconnect(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        let event = mbl_mw_settings_get_disconnect_event(device.board)!
        mbl_mw_event_record_commands(event)
        mbl_mw_macro_execute(device.board, MacroID.waitState.rawValue)
        return event.eventEndRecord()
    }
}

func goToWaitIfButtonHeld(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) {
        mbl_mw_event_record_commands(objs.buttonReleased)
        mbl_mw_debug_enable_power_save(device.board)
        mbl_mw_debug_reset(device.board)
        return objs.buttonReleased.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) {
        mbl_mw_event_record_commands(objs.powerToggleTimer)
        mbl_mw_macro_execute(device.board, MacroID.waitState.rawValue)
        return objs.powerToggleTimer.eventEndRecord()
    }.continueOnSuccessWith(device.apiAccessExecutor) {
        mbl_mw_timer_start(objs.powerToggleTimer)
    }
}

func goToPluggedInStateIfNeeded(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) {
        mbl_mw_event_record_commands(objs.powerSourcePresent)
        mbl_mw_macro_execute(device.board, MacroID.pluggedInState.rawValue)
        return objs.powerSourcePresent.eventEndRecord()
    }
}

func updateLedWhilePluggedIn(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    let chargeStatusRead = mbl_mw_settings_get_charger_status_read_data_signal(device.board)!
    let notChargingRead = mbl_mw_make_id_data_signal(device.board, chargeStatusRead, 0)!
    let chargingRead = mbl_mw_make_id_data_signal(device.board, chargeStatusRead, 1)!
    
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.batteryCharging)
        ledDuringCharging(device)
        return objs.batteryCharging.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.batteryNotCharging)
        ledDuringCharged(device)
        return objs.batteryNotCharging.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        // Let the read spoof a notification
        mbl_mw_event_record_commands(notChargingRead)
        var cmd: [UInt8] = [0x11, 0x12, 0x00, 0x00]
        mbl_mw_debug_spoof_notification(device.board, &cmd, UInt8(cmd.count))
        return notChargingRead.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        // Let the read spoof a notification
        mbl_mw_event_record_commands(chargingRead)
        var cmd: [UInt8] = [0x11, 0x12, 0x00, 0x01]
        mbl_mw_debug_spoof_notification(device.board, &cmd, UInt8(cmd.count))
        return chargingRead.eventEndRecord()
    }.continueOnSuccessWith(device.apiAccessExecutor) {
        mbl_mw_datasignal_read(chargeStatusRead)
    }
}

func generateIsPluggedInMacro(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        Macro.reset()
        // Get rid of the bootup macro events
        mbl_mw_event_remove_all(device.board)
        // Disconnect and stop advertising
        mbl_mw_settings_stop_advertising(device.board)
        mbl_mw_debug_disconnect(device.board)
        // Handle the LED while plugged in
        return updateLedWhilePluggedIn(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        // Reset on unplug
        mbl_mw_event_record_commands(objs.powerSourceAbsent)
        mbl_mw_debug_reset(device.board)
        return objs.powerSourceAbsent.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        // Dont allow LED state to oscillate, must be last thing in macro
        mbl_mw_event_record_commands(objs.batteryNotCharging)
        mbl_mw_event_erase_commands(objs.batteryCharging)
        return objs.batteryNotCharging.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return Task<Void>.withDelay(0.2)
    }.continueOnSuccessWith(device.apiAccessExecutor) { _ in
        Macro.finish(comment: "Go to plugged in state", isBoot: false)
    }
}

func generateBootMacro(_ device: MetaWear) -> Task<FirmwareObjects> {
    var objs: FirmwareObjects!
    
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<FirmwareObjects> in
        Macro.reset()
        return createGlobalObjects(device)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { result -> Task<Void> in
        objs = result
        // No ad while waking up
        mbl_mw_settings_stop_advertising(device.board)
        return goToPluggedInStateIfNeeded(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return goToWaitIfButtonHeld(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return Task<Void>.withDelay(0.2)
    }.continueOnSuccessWith(device.apiAccessExecutor) { _ -> FirmwareObjects in
        Macro.finish(comment: "Call wait state if button held for N seconds on boot", isBoot: false)
        return objs
    }
}

func generateWaitStateMacro(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        Macro.reset()
        // Get rid of the bootup macro events
        mbl_mw_event_remove_all(device.board)
        ledDuringWaitState(device)
        // And finally start adv
        mbl_mw_settings_set_tx_power(device.board, 4)
        mbl_mw_settings_set_ad_interval(device.board, 20, 0)
        let deviceId: UInt8 = device.info?.firmwareRevision == "1.5.0" ? 2 : device.info?.firmwareRevision == "1.4.4" ? 1 : 0
        let response = Data([5, 0xFF, 0x7E, 0x06, 0x4, deviceId])
        mbl_mw_settings_set_scan_response(device.board, [UInt8](response), UInt8(response.count))
        mbl_mw_settings_start_advertising(device.board)
        
        return goToPluggedInStateIfNeeded(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return goToSleepIfButtonHeld(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return goToSleepIfTimeout(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return goToWaitOnDisconnect(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return Task<Void>.withDelay(0.2)
    }.continueOnSuccessWith(device.apiAccessExecutor) { _ in
        Macro.finish(comment: "Go into wait state", isBoot: false)
    }
}

func generateStreamStateMacro(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        Macro.reset()
        // Get rid of the bootup macro events
        mbl_mw_event_remove_all(device.board)
        // Green flash while connected streaming
        ledDuringStreaming(device)
        // Start the sensor fusion
        mbl_mw_sensor_fusion_enable_data(device.board, fusionSignal)
        mbl_mw_sensor_fusion_start(device.board)
        
        return goToPluggedInStateIfNeeded(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return goToWaitOnDisconnect(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return goToSleepIfButtonHeld(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return Task<Void>.withDelay(0.2)
    }.continueOnSuccessWith(device.apiAccessExecutor) { _ in
        Macro.finish(comment: "Go into stream state", isBoot: false)
    }
}

func generateSleepOnButtonReleaseMacro(_ device: MetaWear, objs: FirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        Macro.reset()
        // Get rid of the bootup macro events
        mbl_mw_event_remove_all(device.board)
        // Update the LED
        ledDuringDelayedPowerDown(device)
        // Sleep on button released
        mbl_mw_event_record_commands(objs.buttonReleased)
        mbl_mw_debug_enable_power_save(device.board)
        mbl_mw_debug_reset(device.board)
        return objs.buttonReleased.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return Task<Void>.withDelay(0.2)
    }.continueOnSuccessWith(device.apiAccessExecutor) { _ in
        Macro.finish(comment: "Go into sleep state", isBoot: false)
    }
}

class FirmwareGeneration: XCTestCase {
    func testQuicky() {
        let connectExpectation = XCTestExpectation(description: "connecting")
        connectNearest().continueOnSuccessWithTask { device -> Task<Void> in
//            device.clearAndReset()
//            return Task<Void>.withDelay(2.0)
//        }.continueOnSuccessWithTask { device -> Task<MetaWear> in
//            return connectNearest()
//        }.continueOnSuccessWithTask { device -> Task<Void> in
//            return createGlobalObjects(device).continueOnSuccessWithTask { objs -> Task<Void> in\
            ledDuringCharged(device)
            return Task<Void>.withDelay(50.0)
        }.continueWith { t in
            if let error = t.error {
                print(error.localizedDescription)
            } else {
                print("success")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 50) {
                Macro.dumpFile(comment: "")
                connectExpectation.fulfill()
            }
        }
        wait(for: [connectExpectation], timeout: 120)
    }
    
    func testGenerate1_5_0Macros() {
        let connectExpectation = XCTestExpectation(description: "connecting")
        genMacroData(fw: "1.5.0", hw: "0.4").continueWith { t in
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 600000)
    }
    
    func testGenerate1_4_4Macros() {
        let connectExpectation = XCTestExpectation(description: "connecting")
        genMacroData(fw: "1.4.4", hw: "0.4").continueWith { t in
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 600000)
    }
    
    func testGenerate1_4_97Macros() {
        let connectExpectation = XCTestExpectation(description: "connecting")
        genMacroData(fw: "1.4.97", hw: "0.3").continueWith { t in
            connectExpectation.fulfill()
        }
        wait(for: [connectExpectation], timeout: 600000)
    }
    
    func genMacroData(fw: String, hw: String) -> Task<Void> {
        let info = DeviceInformation(manufacturer: "MbientLab Inc",
                                     modelNumber: "5",
                                     serialNumber: "0478BC",
                                     //serialNumber: "02B998",
                                     firmwareRevision: fw,
                                     hardwareRevision: hw)
        let device = MetaWear.spoof(name: "MetaWear", id: "CC5CEEF1-C8B9-47BF-9B5D-E7329CED353D", mac: "EA:D5:0F:84:19:EC", info: info)
        //let device = MetaWear.spoof(name: "MetaWear", id: "CC5CEEF1-C8B9-47BF-9B5D-E7329CED353D", mac: "F9:EB:86:41:FC:9C", info: info)
        var savedObjs: FirmwareObjects?
        device.logDelegate = SwiftMacroLogger.shared
        return device.connectAndSetup().continueOnSuccessWithTask { _ -> Task<Void> in
            return generateBootMacro(device).continueOnSuccessWithTask(device.apiAccessExecutor) { objs in
                savedObjs = objs
                return generateWaitStateMacro(device, objs: objs).continueOnSuccessWithTask(device.apiAccessExecutor) { _ in
                    return generateStreamStateMacro(device, objs: objs)
                }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ in
                   return generateSleepOnButtonReleaseMacro(device, objs: objs)
                }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ in
                    return generateIsPluggedInMacro(device, objs: objs)
                }
            }
        }.continueWithTask { t in
            if let error = t.error {
                print(error.localizedDescription)
            } else {
                print("success")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("\n\n")
                print("static let streamStateId: UInt8 = \(MacroID.streamState.rawValue)")
                if let filter = savedObjs?.quaternionAverage {
                    print("static let quaternionAverageId: UInt8 = \(mbl_mw_dataprocessor_get_id(filter))")
                }
                print("")
                let comment = fw.replacingOccurrences(of: ".", with: "_")
                print("static let state\(comment) = \"\(device.serialize().hexa)\".hexaBytes")
                print("\n\n")
                
                Macro.dumpFile(comment: comment)
            }
            return Task<Void>.withDelay(5.0)
        }
    }
}


extension OpaquePointer {
    public func counterCreate() -> Task<OpaquePointer> {
        let source = TaskCompletionSource<OpaquePointer>()
        mbl_mw_dataprocessor_counter_create(self, bridgeRetained(obj: source)) { (context, counter) in
            let source: TaskCompletionSource<OpaquePointer> = bridgeTransfer(ptr: context!)
            if let counter = counter {
                source.trySet(result: counter)
            } else {
                source.trySet(error: MetaWearError.operationFailed(message: "could not create counter"))
            }
        }
        return source.task
    }
    
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
