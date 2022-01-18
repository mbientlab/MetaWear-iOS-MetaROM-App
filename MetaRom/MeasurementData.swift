//
//  MeasurementData.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 5/6/19.
//  Copyright © 2019 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import Charts

class MeasurementData {
    let measurement: Measurement
    var degreeLabel: UILabel?
    var lineChartDataSet: LineChartDataSet?
    
    var averageBuffer: [Double] = []
    var sessionData: [(Date, Double)] = []
    
    init(measurement: Measurement, degreeLabel: UILabel? = nil, lineChartDataSet: LineChartDataSet? = nil) {
        self.measurement = measurement
        self.degreeLabel = degreeLabel
        self.lineChartDataSet = lineChartDataSet
    }
}
