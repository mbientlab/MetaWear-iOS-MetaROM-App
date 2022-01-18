//
//  SessionHistoryCollectionReusableView.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 5/30/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import Charts

class SessionHistoryCollectionReusableView: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lineChart: LineChartView!
    var allSessions: [Session]!
    
    func updateUI() {
        lineChart.clear()
        
        let sessionMap: [JointConfig: [Session]] = allSessions.reduce(into: [:]) { (result, session) in
            var array = result[session.sensors.first!.config] ?? []
            array.append(session)
            result[session.sensors.first!.config] = array
        }
        let dataSets: [LineChartDataSet] = sessionMap.map {
            let data = $0.value.map { $0.sensors.first!.max - $0.sensors.first!.min }
            let title = "\($0.key.side.displayName)\($0.key.joint.rawValue)"
            return createSet(data: data, title: title, color: $0.key.color)
        }
        guard dataSets.count > 0 else {
            return
        }
        romGraphSetup(lineChart, dataSets: dataSets)
    }
}

fileprivate func romGraphSetup(_ lineChart: LineChartView, dataSets: [LineChartDataSet]) {
    lineChart.dragEnabled = true
    lineChart.setScaleEnabled(false)
    lineChart.pinchZoomEnabled = false
    lineChart.doubleTapToZoomEnabled = false
    
    lineChart.highlightPerDragEnabled = false
    lineChart.highlightPerTapEnabled = false
    
    lineChart.xAxis.drawGridLinesEnabled = true
    lineChart.xAxis.drawAxisLineEnabled = false
    lineChart.xAxis.labelPosition = .bottom
    lineChart.xAxis.labelTextColor = .steelGrey
    lineChart.xAxis.gridColor = .axisSilver
    lineChart.xAxis.labelFont = UIFont.systemFont(ofSize: 14)
    lineChart.xAxis.setLabelCount(14, force: false)
    let maxValueCount = max(dataSets.max { $0.entries.count < $1.entries.count }!.entries.count, 12)
    lineChart.xAxis.axisMinimum = Double(maxValueCount - 11)
    lineChart.xAxis.axisMaximum = Double(maxValueCount)
    lineChart.xAxis.labelCount = 12
    lineChart.xAxis.granularity = 1.0
    
    lineChart.leftAxis.drawAxisLineEnabled = false
    lineChart.leftAxis.labelTextColor = .steelGrey
    lineChart.leftAxis.gridColor = .axisSilver
    lineChart.leftAxis.gridLineWidth = 1.0
    lineChart.leftAxis.labelFont = UIFont.systemFont(ofSize: 14)
    
    lineChart.legend.form = .line
    lineChart.legend.formSize = 24
    lineChart.legend.formLineWidth = 2
    lineChart.legend.textColor = .steelGrey
    lineChart.legend.font = UIFont.systemFont(ofSize: 14)
    lineChart.legend.verticalAlignment = .top
    lineChart.legend.horizontalAlignment = .right
    
    lineChart.chartDescription?.text = nil
    lineChart.rightAxis.enabled = false
    
    let data = LineChartData(dataSets: dataSets)
    lineChart.data = data
}

fileprivate func createSet(data: [Double], title: String, color: UIColor) -> LineChartDataSet {
    var entries = data.enumerated().map { ChartDataEntry(x: Double($0.offset + 1), y: $0.element) }
    if entries.count == 1 {
        entries.append(ChartDataEntry(x: 1.5, y: entries.first!.y))
    }
    let set = LineChartDataSet(entries: entries, label: title)
    set.drawValuesEnabled = false
    set.drawCircleHoleEnabled = false
    set.drawCirclesEnabled = false
    set.setColor(color)
    set.lineWidth = 2
    set.mode = .cubicBezier
    return set
}
