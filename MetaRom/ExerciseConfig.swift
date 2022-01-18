//
//  ExerciseConfig.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 7/31/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit

public typealias Seconds = Int

struct ExerciseConfig {    
    let name: String
    let barRange: ClosedRange<Double>
    let thresholdNames: [String]
    let exerciseThreshold: ClosedRange<Double>
    let estimatedRepDuration: Seconds
    let repAtTop: Bool
    let joint: Joint
    let measurement: Measurement
    let icon: UIImage
    
    static let seatedKneeExtension = ExerciseConfig(
        name: "Seated Knee Extension",
        barRange: 0...180,
        thresholdNames: ["Extension", "Return"],
        exerciseThreshold: 30...75,
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .knee,
        measurement: .flexionExtension,
        icon: UIImage(named: "seatedKneeExtension")!)
    
    static let standingKneeFlexion = ExerciseConfig(
        name: "Standing Knee Flexion",
        barRange: 0...180,
        thresholdNames: ["Return", "Flexion"],
        exerciseThreshold: 25...60,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .knee,
        measurement: .flexionExtension,
        icon: UIImage(named: "standingKneeFlexion")!)
    
    static let shoulderAbduction = ExerciseConfig(
        name: "Shoulder Abduction",
        barRange: -180...180,
        thresholdNames: ["Return", "Abduction"],
        exerciseThreshold: 10...90,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .shoulder,
        measurement: .abductionAdduction,
        icon: UIImage(named: "shoulderAbduction")!)
    
    static let shoulderExtension = ExerciseConfig(
        name: "Shoulder Extension",
        barRange: -180...180,
        thresholdNames: ["Return", "Extension"],
        exerciseThreshold: 10...90,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .shoulder,
        measurement: .flexionExtension,
        icon: UIImage(named: "shoulderExtension")!)
    
    static let elbowExtension = ExerciseConfig(
        name: "Elbow Extension",
        barRange: 0...180,
        thresholdNames: ["Extension", "Return"],
        exerciseThreshold: 10...30,
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .elbow,
        measurement: .flexionExtension,
        icon: UIImage(named:  "elbowExtension")!)
    
    static let elbowFlexion = ExerciseConfig(
        name: "Elbow Flexion",
        barRange: 0...180,
        thresholdNames: ["Return", "Flexion"],
        exerciseThreshold: 20...120,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .elbow,
        measurement: .flexionExtension,
        icon: UIImage(named: "elbowFlexion")!)
    
    static let wristFlexion = ExerciseConfig(
        name: "Wrist Flexion",
        barRange: -90...90,
        thresholdNames: ["Return", "Flexion"],
        exerciseThreshold: 0...65,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .wrist,
        measurement: .flexionExtension,
        icon: UIImage(named: "wristFlexion")!)
    
    static let wristExtension = ExerciseConfig(
        name: "Wrist Extension",
        barRange: -90...90,
        thresholdNames: ["Extension", "Return"],
        exerciseThreshold: -65...0,
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .wrist,
        measurement: .flexionExtension,
        icon: UIImage(named: "wristFlexion")!)
    
    static let wristDeviation = ExerciseConfig(
        name: "Wrist Deviation",
        barRange: -90...90,
        thresholdNames: ["Ulnar", "Radial"],
        exerciseThreshold: -25...10,
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .wrist,
        measurement: .radialUlnar,
        icon: UIImage(named: "wristDeviation")!)
    
    static let wristRadialDeviation = ExerciseConfig(
        name: "Wrist Radial Deviation",
        barRange: -90...90,
        thresholdNames: ["Return", "Radial"],
        exerciseThreshold: 0...15,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .wrist,
        measurement: .radialUlnar,
        icon: UIImage(named: "wristDeviation")!)
    
    static let wristUlnarDeviation = ExerciseConfig(
        name: "Wrist Ulnar Deviation",
        barRange: -90...90,
        thresholdNames: ["Ulnar", "Return"],
        exerciseThreshold: -25...0,
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .wrist,
        measurement: .radialUlnar,
        icon: UIImage(named: "wristDeviation")!)
    
    static let ankleFlexion = ExerciseConfig(
        name: "Ankle Flexion",
        barRange: -90...90,
        thresholdNames: ["Extension", "Flexion"],
        exerciseThreshold: -30...20,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .ankle,
        measurement: .flexionExtension,
        icon: UIImage(named: "ankleFlexion")!)
    
    static let ankleInversion = ExerciseConfig(
        name: "Ankle Inversion",
        barRange: -45...45,
        thresholdNames: ["Inversion", "Return"],
        exerciseThreshold: -25...0,
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .ankle,
        measurement: .eversionInversion,
        icon: UIImage(named: "ankleInversionEversion")!)
    
    static let neckFlexion = ExerciseConfig(
        name: "Neck Flexion",
        barRange: -90...90,
        thresholdNames: ["Extension", "Flexion"],
        exerciseThreshold: -30...30,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .neck,
        measurement: .flexionExtension,
        icon: UIImage(named: "neckFlexion")!)
    
    static let neckLateralFlexion = ExerciseConfig(
        name: "Neck Lateral Flexion",
        barRange: -90...90,
        thresholdNames: ["Left Flexion", "Right Flexion"],
        exerciseThreshold: -30...30,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .neck,
        measurement: .lateralFlexion,
        icon: UIImage(named: "neckLateralFlexion")!)
    
    static let neckRotation = ExerciseConfig(
        name: "Neck Rotation",
        barRange: -90...90,
        thresholdNames: ["Left Rotation", "Right Rotation"],
        exerciseThreshold: -30...30,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .neck,
        measurement: .rotation,
        icon: UIImage(named: "neckRotation")!)
    
    static let spineExtension = ExerciseConfig(
        name: "Spine Extension",
        barRange: -90...90,
        thresholdNames: ["Extension", "Return"],
        exerciseThreshold: (-25)...(-10),
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .spine,
        measurement: .flexionExtension,
        icon: UIImage(named: "spineExtension")!)
    
    static let spineFlexion = ExerciseConfig(
        name: "Spine Flexion",
        barRange: -90...90,
        thresholdNames: ["Extension", "Flexion"],
        exerciseThreshold: -15...15,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .spine,
        measurement: .flexionExtension,
        icon: UIImage(named: "spineFlexion")!)
    
    static let urbanFreerunGame = ExerciseConfig(
        name: "Urban Freerun",
        barRange: 0...180,
        thresholdNames: ["Extension", "Return"],
        exerciseThreshold: 30...75,
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .knee,
        measurement: .flexionExtension,
        icon: UIImage(named: "seatedKneeExtension")!)

    static let castleDefenseGame = ExerciseConfig(
        name: "Castle Defense Game",
        barRange: -90...90,
        thresholdNames: ["Extension", "Return"],
        exerciseThreshold: -65...0,
        estimatedRepDuration: 10,
        repAtTop: false,
        joint: .wrist,
        measurement: .flexionExtension,
        icon: UIImage(named: "wristFlexion")!)

    static let lockPickGame = ExerciseConfig(
        name: "Survival Training",
        barRange: 0...180,
        thresholdNames: ["Extension", "Flexion"],
        exerciseThreshold: 20...120,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .elbow,
        measurement: .flexionExtension,
        icon: UIImage(named: "elbowFlexion")!)

    static let dangerRoomGame = ExerciseConfig(
        name: "Danger Room Game",
        barRange: -90...90,
        thresholdNames: ["Extension", "Flexion"],
        exerciseThreshold: -30...20,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .ankle,
        measurement: .flexionExtension,
        icon: UIImage(named: "ankleFlexion")!)
    
    static let fightingPracticeGame = ExerciseConfig(
        name: "Fighting Practice",
        barRange: -90...90,
        thresholdNames: ["Extension", "Flexion"],
        exerciseThreshold: -30...30,
        estimatedRepDuration: 10,
        repAtTop: true,
        joint: .neck,
        measurement: .flexionExtension,
        icon: UIImage(named: "neckFlexion")!)
    
    static let lookup: [String: ExerciseConfig] = [
        fightingPracticeGame.name: fightingPracticeGame,
        dangerRoomGame.name: dangerRoomGame,
        lockPickGame.name: lockPickGame,
        castleDefenseGame.name: castleDefenseGame,
        urbanFreerunGame.name: urbanFreerunGame,
        
        seatedKneeExtension.name: seatedKneeExtension,
        standingKneeFlexion.name: standingKneeFlexion,
        shoulderAbduction.name: shoulderAbduction,
        shoulderExtension.name: shoulderExtension,
        elbowExtension.name: elbowExtension,
        elbowFlexion.name: elbowFlexion,
        wristFlexion.name: wristFlexion,
        wristExtension.name: wristExtension,
        wristDeviation.name: wristDeviation,
        wristRadialDeviation.name: wristRadialDeviation,
        wristUlnarDeviation.name: wristUlnarDeviation,
        ankleFlexion.name: ankleFlexion,
        ankleInversion.name: ankleInversion,
        neckFlexion.name: neckFlexion,
        neckLateralFlexion.name: neckLateralFlexion,
        neckRotation.name: neckRotation,
        spineExtension.name: spineExtension,
        spineFlexion.name: spineFlexion,
        ]
}
