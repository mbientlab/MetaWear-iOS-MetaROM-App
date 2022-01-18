//
//  PeakFinding.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 1/16/19.
//  Copyright © 2019 MBIENTLAB, INC. All rights reserved.
//

import Foundation

func findPeaksAndValleys(samples: [(Date, Double)],
                         depth: Int = 14,
                         thresholdSigma: Double = 0.0,
                         finalPointSigma: Double = 1.5) -> [(isMax: Bool, date: Date, value: Double)] {
    assert(depth > 0)
    guard samples.count > depth else {
        return []
    }
    let values = samples.map { $0.1 }
    let average = values.average
    let stdev = values.stdev
    var lookingForMax: Bool? = nil
    var currentMax = samples[0..<depth].max { $0.1 < $1.1 }!
    var currentMin = samples[0..<depth].min { $0.1 < $1.1 }!
    var peaksAndValleys: [(isMax: Bool, date: Date, value: Double)] = []
    for i in 0..<samples.count-depth {
        let max = samples[i..<i+depth].max { $0.1 < $1.1 }!
        if lookingForMax ?? true {
            if max.1 >= currentMax.1 {
                currentMax = max
            } else if currentMax.1 > (average + (stdev * thresholdSigma))  {
                peaksAndValleys.append((true, currentMax.0, currentMax.1))
                lookingForMax = false
                currentMin = currentMax
            }
        }
        if !(lookingForMax ?? false) {
            let min = samples[i..<i+depth].min { $0.1 < $1.1 }!
            if min.1 <= currentMin.1 {
                currentMin = min
            } else if currentMin.1 < (average - (stdev * thresholdSigma)) {
                peaksAndValleys.append((false, currentMin.0, currentMin.1))
                lookingForMax = true
                currentMax = currentMin
            }
        }
    }
    if let lookingForMax = lookingForMax {
        if lookingForMax {
            let peaks = peaksAndValleys.filter{ $0.isMax }.map{ $0.value }
            if peaks.count > 1 {
                let average = peaks.average
                let stdev = peaks.stdev
                if abs(currentMax.1 - average) < (stdev * finalPointSigma) {
                    peaksAndValleys.append((true, currentMax.0, currentMax.1))
                }
            }
        } else {
            let valleys = peaksAndValleys.filter { !$0.isMax }.map{ $0.value }
            if valleys.count > 1 {
                let average = valleys.average
                let stdev = valleys.stdev
                if abs(currentMin.1 - average) < (stdev * finalPointSigma) {
                    peaksAndValleys.append((false, currentMin.0, currentMin.1))
                }
            }
        }
    }
    return peaksAndValleys
}
