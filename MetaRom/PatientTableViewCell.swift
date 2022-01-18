//
//  PatientTableViewCell.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 5/24/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit

class PatientTableViewCell: UITableViewCell {
    @IBOutlet weak var patientId: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var lastSession: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
