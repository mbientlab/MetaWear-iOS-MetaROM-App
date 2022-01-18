//
//  SessionCollectionViewCell.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 8/1/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import RealmSwift

class SessionCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var exerciseImage: UIImageView!
    @IBOutlet weak var dateTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var lengthTitleLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var topBar: UIView!
    
    override var isSelected: Bool {
        didSet {
            background.layer.borderWidth = isSelected ? 4 : 0
        }
    }
    
    var session: Session!
    var token : NotificationToken?
    var sessionNumber: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        background.layer.borderColor = UIColor.turquoiseBlue.cgColor
        background.layer.cornerRadius = 4
        isSelected = false
    }
    
    //func updateSyncIcon() {
    //    syncImage.image = UIImage(named: session.parseObjectId == nil ? "notSync" : "sync")
    //}
    
    func updateUI() {
        //if Globals.cloudSyncMode {
        //    token = session.observe { [unowned self] change in
        //        switch change {
        //        case .change(let object, _):
        //            let tempSession = object as! Session
        //            if tempSession.name == "parseObjectId" {
        //                self.updateSyncIcon()
        //            }
        //            //if object.contains(where: { $0.name == "parseObjectId" }) {
        //            //    self.updateSyncIcon()
        //            //}
        //        default:
        //            break
        //        }
        //    }
        //    updateSyncIcon()
        //} else {
        //    syncImage.image = UIImage(named: "doNotSync")
        //}
        if let sensor = session.sensors.first {
            titleLabel.text = session.name
            dateLabel.text = DateFormatter.localizedString(from: session.started, dateStyle: .short, timeStyle: .none)
            topBar.backgroundColor = sensor.config.color
            lengthTitleLabel.textColor = sensor.config.color
            dateTitleLabel.textColor = sensor.config.color
            //if let exercise = session.exercise {
            //    subtitleLabel.text = "EXERCISE MODE - SESSION \(String(sessionNumber))"
            //    exerciseImage.image = exercise.icon
            //    lengthTitleLabel.text = "Reps"
            //    lengthLabel.text = String(session.reps.value!)
            //    updateMinMax(sensor: sensor, isOnlySensor: true)
            //} else {
                subtitleLabel.text = "SESSION \(String(sessionNumber))"
                exerciseImage.image = sensor.config.icon
                lengthTitleLabel.text = "Length"
                lengthLabel.text = DateFormatter.localizedString(from: session.started, dateStyle: .none, timeStyle: .short)
                lengthLabel.text = session.started.differenceTo(session.ended)
                //updateMinMax(sensor: sensor, isOnlySensor: session.sensors.count == 1)
            //}
        }
    }
    
    /*func updateMinMax(sensor: Sensor, isOnlySensor: Bool) {
        if isOnlySensor {
            minLabel.text = String(format: "%.0f°/", sensor.min)
            maxLabel.text = String(format: "%.0f°", sensor.max)
        }
        minLabel.isHidden = !isOnlySensor
        maxLabel.isHidden = !isOnlySensor
        //seeDetailsLabel.isHidden = isOnlySensor
    }*/
}
