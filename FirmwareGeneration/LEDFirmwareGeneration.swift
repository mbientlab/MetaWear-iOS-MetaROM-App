//
//  LEDFirmwareGeneration.swift
//  MetaClinicTests
//
//  Created by Stephen Schiffli on 12/11/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import XCTest
import BoltsSwift
import MetaWear
import MetaWearCpp
import CoreBluetooth
@testable import MetaClinic

/// Objects that we create on boot and persist forever
struct LEDFirmwareObjects {
    let powerSourcePresent: OpaquePointer
    let powerSourceAbsent: OpaquePointer
    let chargerStatusPassthrough: OpaquePointer!
    let batteryCharging: OpaquePointer
    let batteryNotCharging: OpaquePointer
}

/// Create the LEDFirmwareObjects
func createLEDGlobalObjects(_ device: MetaWear) -> Task<LEDFirmwareObjects> {
    var powerSourcePresent: OpaquePointer!
    var powerSourceAbsent: OpaquePointer!
    var chargerStatusPassthrough: OpaquePointer!
    var batteryCharging: OpaquePointer!
    var batteryNotCharging: OpaquePointer!
    
    let powerStatus = mbl_mw_settings_get_power_status_data_signal(device.board)!
    let chargerStatus = mbl_mw_settings_get_charge_status_data_signal(device.board)!
    
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<OpaquePointer> in
        return chargerStatus.passthroughCreate(mode: MBL_MW_PASSTHROUGH_MODE_CONDITIONAL, count: 1)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { filter -> Task<OpaquePointer> in
        chargerStatusPassthrough = filter
        return chargerStatusPassthrough.comparatorCreate(op: MBL_MW_COMPARATOR_OP_EQ, mode: MBL_MW_COMPARATOR_MODE_ABSOLUTE, references: [0])
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { filter -> Task<OpaquePointer> in
        batteryNotCharging = filter
        return chargerStatusPassthrough.comparatorCreate(op: MBL_MW_COMPARATOR_OP_EQ, mode: MBL_MW_COMPARATOR_MODE_ABSOLUTE, references: [1])
    }.continueOnSuccessWith(device.apiAccessExecutor) { filter -> LEDFirmwareObjects in
        batteryCharging = filter
        
        powerSourcePresent = mbl_mw_make_id_data_signal(device.board, powerStatus, 1)
        powerSourceAbsent = mbl_mw_make_id_data_signal(device.board, powerStatus, 0)
        
        return LEDFirmwareObjects(powerSourcePresent: powerSourcePresent,
                               powerSourceAbsent: powerSourceAbsent,
                               chargerStatusPassthrough: chargerStatusPassthrough,
                               batteryCharging: batteryCharging,
                               batteryNotCharging: batteryNotCharging)
    }
}

func ledDuringLEDCharging(_ device: MetaWear) {
    let orange = UIColor(red: 0.4, green: 0.6, blue: 0.0, alpha: 1.0)
    device.flashLED(color: orange, intensity: 0.6, _repeat: 0xFF, onTime: 200, period: 2500)
}

func ledDuringLEDCharged(_ device: MetaWear) {
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

func updateLedWhileLEDPluggedIn(_ device: MetaWear, objs: LEDFirmwareObjects) -> Task<Void> {
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.powerSourceAbsent)
        mbl_mw_dataprocessor_passthrough_modify(objs.chargerStatusPassthrough, MBL_MW_PASSTHROUGH_MODE_CONDITIONAL, 0)
        mbl_mw_led_stop_and_clear(device.board)
        return objs.powerSourceAbsent.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.powerSourcePresent)
        mbl_mw_dataprocessor_passthrough_modify(objs.chargerStatusPassthrough, MBL_MW_PASSTHROUGH_MODE_CONDITIONAL, 1)
        return objs.powerSourcePresent.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.batteryNotCharging)
        mbl_mw_dataprocessor_passthrough_modify(objs.chargerStatusPassthrough, MBL_MW_PASSTHROUGH_MODE_CONDITIONAL, 0)
        ledDuringLEDCharged(device)
        return objs.batteryNotCharging.eventEndRecord()
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        mbl_mw_event_record_commands(objs.batteryCharging)
        ledDuringLEDCharging(device)
        return objs.batteryCharging.eventEndRecord()
    }
}


func generateLEDBootMacro(_ device: MetaWear) -> Task<LEDFirmwareObjects> {
    var objs: LEDFirmwareObjects!
    
    return Task<Void>(()).continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<LEDFirmwareObjects> in
        Macro.reset()
        return createLEDGlobalObjects(device)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { result -> Task<Void> in
        objs = result
        return updateLedWhileLEDPluggedIn(device, objs: objs)
    }.continueOnSuccessWithTask(device.apiAccessExecutor) { _ -> Task<Void> in
        return Task<Void>.withDelay(0.2)
    }.continueOnSuccessWith(device.apiAccessExecutor) { _ -> LEDFirmwareObjects in
        Macro.finish(comment: "Flash orange when charging, green when charged, nothing when unplugged", isBoot: true)
        return objs
    }
}

class LEDFirmwareGeneration: XCTestCase {
    func testQuicky() {
        let connectExpectation = XCTestExpectation(description: "connecting")
        connectNearest().continueOnSuccessWithTask { device -> Task<Void> in
//            device.clearAndReset()
//            return Task<Void>.withDelay(2.0)
//        }.continueOnSuccessWithTask { device -> Task<MetaWear> in
//            return connectNearest()
//        }.continueOnSuccessWithTask { device -> Task<Void> in
        return createLEDGlobalObjects(device).continueOnSuccessWithTask { objs -> Task<Void> in
            updateLedWhileLEDPluggedIn(device, objs: objs)
            
            let powerStatus = mbl_mw_settings_get_power_status_data_signal(device.board)!
            mbl_mw_datasignal_subscribe(powerStatus, nil, { (ctx, data) in
                let val: UInt32 = data!.pointee.valueAs()
                print("powerStatus \(val)")
            })
            let chargerStatus = mbl_mw_settings_get_charge_status_data_signal(device.board)!
            mbl_mw_datasignal_subscribe(chargerStatus, nil, { (ctx, data) in
                let val: UInt32 = data!.pointee.valueAs()
                print("chargerStatus \(val)")
            })
            return Task<Void>.withDelay(50.0)
        }
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
    
    func testGenerateStaticMacros() {
        let connectExpectation = XCTestExpectation(description: "connecting")
        let info = DeviceInformation(manufacturer: "MbientLab Inc",
                                     modelNumber: "5",
                                     serialNumber: "02B998",
                                     firmwareRevision: "1.4.97",
                                     hardwareRevision: "0.3")
        let device = MetaWear.spoof(name: "MetaWear", id: "CC5CEEF1-C8B9-47BF-9B5D-E7329CED353D", mac: "F9:EB:86:41:FC:9C", info: info)
        device.logDelegate = CMacroLogger.shared
        device.connectAndSetup().continueOnSuccessWithTask { _ -> Task<LEDFirmwareObjects> in
            return generateLEDBootMacro(device)
        }.continueWith { t in
            if let error = t.error {
                print(error.localizedDescription)
            } else {
                print("success")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                Macro.dumpFile(comment: "")
                connectExpectation.fulfill()
            }
        }
        wait(for: [connectExpectation], timeout: 600000)
    }
}
