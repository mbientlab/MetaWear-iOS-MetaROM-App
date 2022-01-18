//
//  RoutineConfig.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 7/9/19.
//  Copyright © 2019 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import RealmSwift

struct CompletedRep: Codable, Equatable {

}

struct CompletedSet: Codable, Equatable {
    var completedReps: [CompletedRep]
}

struct SetConfig: Codable, Equatable {
    var exerciseName: String
    var reps: Int
    var holdDuration: Seconds
    var restDuration: Seconds
    var points: Int
    var difficulty: Difficulty
    var completedSet: CompletedSet? = nil
    
    var estimatedDuration: Seconds {
        let estimatedRepDuration = ExerciseConfig.lookup[exerciseName]?.estimatedRepDuration ?? 10
        return (reps * (estimatedRepDuration + holdDuration)) + restDuration
    }
    var completedReps: Int {
        guard let completedSet = completedSet else {
            return 0
        }
        return completedSet.completedReps.count
    }
}

struct WorkoutConfig: Codable, Equatable {
    // Time when exercise should be performed 0 to 86,400 seconds valid range (24 hours)
    var dueTime: Int
    var sets: [SetConfig]
    var completionDate: Date?
    
    var estimatedDuration: Seconds {
        return sets.reduce(0) { $0 + $1.estimatedDuration }
    }
    var hardestDifficulty: Difficulty {
        return sets.map { $0.difficulty }.max() ?? .easy
    }
    var points: Int {
        return sets.reduce(0) { $0 + $1.points }
    }
}

struct DayConfig: Codable, Equatable {
    var workouts: [WorkoutConfig]
    
    var completion: Float {
        let bingo = workouts.reduce(into: (0, 0)) { (result, config) in
            result = config.sets.reduce(into: result, { (result, exercise) in
                result.0 += exercise.completedReps
                result.1 += exercise.reps
            })
        }
        return Float(bingo.0) / Float(bingo.1)
    }
    var estimatedDuration: Seconds {
        return workouts.reduce(0) { $0 + $1.estimatedDuration }
    }
    var hardestDifficulty: Difficulty {
        return workouts.map { $0.hardestDifficulty }.max() ?? .easy
    }
    var points: Int {
        return workouts.reduce(0) { $0 + $1.points }
    }
    var latestCompletion: Date? {
        return workouts.compactMap { $0.completionDate }.max()
    }
}

struct RoutineConfig: Codable, Equatable {
    var name: String
    var overview: String
    var start: Date?
    var days: [DayConfig]
    
    var difficulty: Difficulty {
        return days.map { $0.hardestDifficulty }.max() ?? .easy
    }
    var maxPointsInDay: Int {
        return days.map { $0.points }.max() ?? 1
    }
    var duration: String {
        if days.count % 7 == 0 {
            let weeks = days.count / 7
            return "\(weeks)week\(weeks > 1 ? "s" : "")"
        }
        return "\(days.count)day\(days.count > 1 ? "s" : "")"
    }
    var latestCompletion: Date? {
        return days.compactMap { $0.latestCompletion }.max()
    }
    var todayIdx: Int? {
        guard let start = start else {
            return nil
        }
        let diff = Date().interval(ofComponent: .day, fromDate: start)
        guard diff < days.count else {
            return nil
        }
        return diff
    }
    
    var allSets: [SetConfig] {
        var exercises: [String: SetConfig] = [:]
        for day in days {
            for workout in day.workouts {
                for set in workout.sets {
                    if exercises[set.exerciseName] == nil {
                        exercises[set.exerciseName] = set
                    }
                }
            }
        }
        return exercises.values.map { $0 }
    }
    
    static let wristROM: RoutineConfig = {
        let wristRadialDeviation = SetConfig(exerciseName: ExerciseConfig.wristRadialDeviation.name,
                                             reps: 4,
                                             holdDuration: 1,
                                             restDuration: 30,
                                             points: 1,
                                             difficulty: .easy,
                                             completedSet: nil)
        
        let wristUlnarDeviation = SetConfig(exerciseName: ExerciseConfig.wristUlnarDeviation.name,
                                            reps: 4,
                                            holdDuration: 1,
                                            restDuration: 30,
                                            points: 1,
                                            difficulty: .easy,
                                            completedSet: nil)
        
        let wristFlexion = SetConfig(exerciseName: ExerciseConfig.wristFlexion.name,
                                     reps: 4,
                                     holdDuration: 1,
                                     restDuration: 30,
                                     points: 1,
                                     difficulty: .easy,
                                     completedSet: nil)
        
        
        let wristExtension  = SetConfig(exerciseName: ExerciseConfig.wristExtension.name,
                                        reps: 4,
                                        holdDuration: 1,
                                        restDuration: 30,
                                        points: 1,
                                        difficulty: .easy,
                                        completedSet: nil)
        
        let workout = WorkoutConfig(
            dueTime: (12 + 8) * 60 * 60,
            sets: [wristRadialDeviation, wristUlnarDeviation, wristFlexion, wristExtension],
            completionDate: nil)
        
        let day = DayConfig(workouts: [workout])
        
        let routine = RoutineConfig(
            name: "Wrist ROM",
            overview: "Functional ranges of motion of the wrist joint.",
            start: nil,
            days: Array(repeating: day, count: 7 * 4))
        return routine
    }()
    
     static let all: [RoutineConfig] = [
        wristROM,
    ]
}
