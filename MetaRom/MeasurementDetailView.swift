//
//  MeasurementDetailView.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 1/17/19.
//  Copyright © 2019 MBIENTLAB, INC. All rights reserved.
//

import UIKit

@IBDesignable
class MeasurementDetailView: UIView, NibLoadable {
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var maxDeg: UILabel!
    @IBOutlet weak var minDeg: UILabel!
    @IBOutlet weak var numberOfPeaks: UILabel!
    @IBOutlet weak var averagePeak: UILabel!
    @IBOutlet weak var numberOfValleys: UILabel!
    @IBOutlet weak var averageValley: UILabel!
    @IBOutlet weak var maxDegLabel: UILabel!
    @IBOutlet weak var numberOfPeaksLabel: UILabel!
    @IBOutlet weak var averagePeakLabel: UILabel!
    @IBOutlet weak var minDegLabel: UILabel!
    @IBOutlet weak var numberOfValleysLabel: UILabel!
    @IBOutlet weak var averageValleyLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    func updateUI(color: UIColor, name: String, max: Double, min: Double, peaksAndValleys: [(isMax: Bool, date: Date, value: Double)]) {
        topBar.backgroundColor = color
        
        maxDegLabel.textColor = color
        numberOfPeaksLabel.textColor = color
        averagePeakLabel.textColor = color
        minDegLabel.textColor = color
        numberOfValleysLabel.textColor = color
        averageValleyLabel.textColor = color
        
        title.text = name
        let peaks = peaksAndValleys.filter{ $0.isMax }.map{ $0.value }
        maxDeg.text = String(format: "%.0f°", max)
        numberOfPeaks.text = "\(peaks.count)"
        averagePeak.text = String(format: "%.0f°", peaks.count > 0 ? peaks.average : 0.0)
        let valleys = peaksAndValleys.filter { !$0.isMax }.map{ $0.value }
        minDeg.text = String(format: "%.0f°", min)
        numberOfValleys.text = "\(valleys.count)"
        averageValley.text = String(format: "%.0f°", valleys.count > 0 ? valleys.average : 0.0)
    }
}
