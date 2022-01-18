//
//  SingleSessionViewController.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 6/6/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import Charts

class SingleSessionViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var sessionLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet var measurementDetailViews: [MeasurementDetailView]!
    
    var session: Session!
    var sessionNumber: Int!
    var graphLoaded: Bool = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard !graphLoaded else {
            return
        }
        graphLoaded = true
        
        nameLabel.text = session.patient?.fullName
        sessionLabel.text = String(sessionNumber)

        var colors = graphLineColors.makeIterator()
        var details = measurementDetailViews.makeIterator()
        let started = session.started
        let ended = session.ended
        titleLabel.text = session.name
        dateLabel.text = DateFormatter.localizedString(from: started, dateStyle: .short, timeStyle: .none)
        startLabel.text = DateFormatter.localizedString(from: started, dateStyle: .none, timeStyle: .short)
        lengthLabel.text = started.differenceTo(ended)

        session.loadFromZip().continueWith(.mainThread) { t in
            guard t.error == nil else {
                self.showOkAlert(title: "Load Failed", message: "Please try again.\n\(t.error!.localizedDescription)")
                return
            }
            let sets: [LineChartDataSet] = t.result!.map { (sensor, data) -> LineChartDataSet in
                let peaksAndValleys = findPeaksAndValleys(samples: data)
                var it = peaksAndValleys.makeIterator()
                var currentPeakOrValley = it.next()
                let color = colors.next()!
                
                let detail = details.next()!
                detail.isHidden = false
                detail.backgroundColor = .clear
                detail.updateUI(color: color, name: sensor.name, max: sensor.max, min: sensor.min, peaksAndValleys: peaksAndValleys)
                
                let entries = data.map { value -> ChartDataEntry in
                    let currentTime = -started.timeIntervalSince(value.0)
                    var icon: UIImage? = nil
                    if currentPeakOrValley?.date == value.0 {
                        icon = UIImage.circle(color: color, radius: 9)
                        currentPeakOrValley = it.next()
                    }
                    return ChartDataEntry(x: currentTime, y: value.1, icon: icon)
                }
                return createSet(color: color, title: sensor.name, entries: entries)
            }
            self.session.thresholds.forEach { targetLine(lineChart: self.lineChart, value: $0) }
            chartSetup(self.lineChart, dataSets: sets)
        }
    }
    
    @IBAction func shareSessionPressed(_ sender: UIBarButtonItem) {
        let url = session.zipFileURL
        sender.isEnabled = false
        // The UIActivityViewController taks a long time to setup so we do this on a background thread
        DispatchQueue.global().async {
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            DispatchQueue.main.async {
                sender.isEnabled = true
                // Support display in iPad
                activity.popoverPresentationController?.barButtonItem = sender
                self.present(activity, animated: true)
            }
        }
    }
    
    @IBAction func deleteSessionPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this session?  This action cannot be undone.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.session.delete()
            let _ = DeleteOp.deleteAll()
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = deleteButton
        alert.popoverPresentationController?.sourceRect = deleteButton.bounds
        
        present(alert, animated: true)
    }
}

fileprivate func createSet(color: UIColor, title: String, entries: [ChartDataEntry] = [ChartDataEntry(x: 0, y: 0)]) -> LineChartDataSet {
    let set = LineChartDataSet(entries: entries, label: title)
    set.drawValuesEnabled = false
    set.drawCircleHoleEnabled = false
    set.drawCirclesEnabled = false
    set.drawIconsEnabled = true
    set.setColor(color)
    set.lineWidth = 2
    set.mode = .cubicBezier
    return set
}

fileprivate func chartSetup(_ lineChart: LineChartView, dataSets: [LineChartDataSet]) {
    lineChart.maxVisibleCount = 999999999
    lineChart.dragXEnabled = true
    lineChart.dragYEnabled = false
    lineChart.scaleXEnabled = true
    lineChart.scaleYEnabled = false
    lineChart.pinchZoomEnabled = false
    lineChart.doubleTapToZoomEnabled = true
    
    lineChart.highlightPerDragEnabled = false
    lineChart.highlightPerTapEnabled = false
    
    lineChart.xAxis.drawGridLinesEnabled = true
    lineChart.xAxis.drawAxisLineEnabled = false
    lineChart.xAxis.gridColor = .axisSilver
    lineChart.xAxis.gridLineWidth = 0.5
    lineChart.xAxis.labelPosition = .bottom
    lineChart.xAxis.labelTextColor = .steelGrey
    lineChart.xAxis.labelFont = UIFont.systemFont(ofSize: 14)
    
    lineChart.leftAxis.drawGridLinesEnabled = true
    lineChart.leftAxis.drawAxisLineEnabled = false
    lineChart.leftAxis.gridColor = .axisSilver
    lineChart.leftAxis.gridLineWidth = 0.5
    lineChart.leftAxis.labelTextColor = .steelGrey
    lineChart.leftAxis.labelFont = UIFont.systemFont(ofSize: 14)
    lineChart.leftAxis.valueFormatter = AlwaysPositiveAxisValueFormatter()
    
    lineChart.legend.form = .line
    lineChart.legend.formSize = 24
    lineChart.legend.formLineWidth = 2
    lineChart.legend.textColor = .steelGrey
    lineChart.legend.font = UIFont.systemFont(ofSize: 14)
    lineChart.legend.verticalAlignment = .top
    lineChart.legend.horizontalAlignment = .right
    
    lineChart.chartDescription?.text = nil
    lineChart.rightAxis.enabled = false
        
    // Add a fat zero line
    zeroLine(lineChart)
    
    let data = LineChartData(dataSets: dataSets)
    lineChart.data = data
}

fileprivate func zeroLine(_ lineChart: LineChartView) {
    let ll = ChartLimitLine(limit: 0.0)
    ll.lineColor = .steelGrey
    ll.lineWidth = 1
    lineChart.leftAxis.addLimitLine(ll)
}

fileprivate func targetLine(lineChart: LineChartView, value: Double) {
    let ll = ChartLimitLine(limit: value)
    let color: UIColor = .darkGray
    let lineDashPhase: CGFloat = 0.0
    let lineDashLengths: [CGFloat] = [6, 6]

    ll.lineColor = color
    ll.lineWidth = 1
    ll.lineDashPhase = lineDashPhase
    ll.lineDashLengths = lineDashLengths
    lineChart.leftAxis.addLimitLine(ll)
    lineChart.legend.extraEntries = [LegendEntry(label: "Target",
                                                form: Legend.Form.line,
                                                formSize: 24,
                                                formLineWidth: 2,
                                                formLineDashPhase: lineDashPhase,
                                                formLineDashLengths: lineDashLengths,
                                                formColor: color)]
}

public extension UIImage {
    static func circle(color: UIColor, radius: Int) -> UIImage {
        let size: CGSize = CGSize(width: radius, height: radius)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(color.cgColor)
            let rect = CGRect(origin: .zero, size: size)
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.drawPath(using: .fill)
        }
    }
}
