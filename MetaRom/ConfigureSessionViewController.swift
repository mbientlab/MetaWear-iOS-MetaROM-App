//
//  StartSessionViewController.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 5/24/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import MetaWear
import RealmSwift

protocol ConfigureSessionDelegate: class {
    func didFinish(processor: StreamProcessor, exercise: ExerciseConfig?, alreadyCalibrated: Bool, calibrateOnTable: Bool)
    func notFoundStateDidChange(_ notFoundShown: Bool)
}

class ConfigureSessionViewController: UIViewController {
    @IBOutlet weak var jointField: UITextField!
    @IBOutlet weak var calibrationSelector: UISegmentedControl!
    @IBOutlet weak var sideSelector: UISegmentedControl!
    @IBOutlet weak var startSessionButton: UIButton!
    @IBOutlet var rssiIcon: [UIImageView]!
    @IBOutlet var deviceNameLabel: [UILabel]!
    @IBOutlet var deviceMacLabel: [UILabel]!
    @IBOutlet var deviceColorView: [UIView]!
    
    var patient: Patient!
    var sessionNumber: Int!
    weak var delegate: ConfigureSessionDelegate?
    
    let jointPickerView = UIPickerView()
    let joints = [
        ("", []),
        ("Knee", [JointConfig.leftKnee, JointConfig.rightKnee]),
        ("Elbow", [JointConfig.leftElbow, JointConfig.rightElbow]),
        ("Ankle", [JointConfig.leftAnkle, JointConfig.rightAnkle]),
        ("Wrist", [JointConfig.leftWrist, JointConfig.rightWrist]),
        ("Shoulder", [JointConfig.leftShoulder, JointConfig.rightShoulder]),
        ("Hip", [JointConfig.leftHip, JointConfig.rightHip]),
        ("Neck", [JointConfig.neck]),
        ("Spine", [JointConfig.spine]),
        ]
    let exercisePickerView = UIPickerView()
    
    var foundDevices: [MetaWear] = []
    var currentJoint: JointConfig?
    var currentExercise: ExerciseConfig?
    var candidateExercises: [(String, ExerciseConfig?)] = []
    var scannerModel: ScannerModel!
    var chosenDevices: [MetaWear] = []
    var isFreeform: Bool = true

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        jointPickerView.delegate = self
        jointPickerView.dataSource = self
        jointField.inputView = jointPickerView
        
        scannerModel = ScannerModel(delegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Double check everything is disconnected
        StreamProcessor.stopAll()
        MetaWearScanner.shared.deviceMap.forEach { $1.cancelConnection() }
        scannerModel.isScanning = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("reset")
        chosenDevices = []
        foundDevices = []
        
        rssiIcon.forEach { $0.image = #imageLiteral(resourceName: "signal6") }
        deviceNameLabel.forEach { $0.text = "N/A" }
        deviceMacLabel.forEach { $0.text = "SEARCHING" }
        
        // Reload the last used data
        if let lastJoint = patient.lastJoint, let idx = joints.firstIndex(where: { $0.0 == lastJoint }) {
            jointPickerView.selectRow(idx, inComponent: 0, animated: false)
            pickerView(jointPickerView, didSelectRow: idx, inComponent: 0)
        }
        if let lastSide = patient.lastSide.value {
            sideSelector.selectedSegmentIndex = lastSide
        }
        if let lastCalibration = patient.lastCalibration.value {
            calibrationSelector.selectedSegmentIndex = lastCalibration
        }
        
        updateCurrentConfig()
        updateUIForSessionType()
        updateDetectedSensors()
        
        // Double check everything is disconnected
        StreamProcessor.stopAll()
        MetaWearScanner.shared.deviceMap.forEach { $1.cancelConnection() }
        scannerModel.isScanning = true
        scannerModel.items.forEach {
            $0.stateDidChange = { [weak self] in
                self?.updateDetectedSensors()
            }
        }
    }
    
    func updateDetectedSensors() {
        DispatchQueue.main.async {
            let names = ["MetaWear", "MetaWear"]
            
            // Sort by RSSI
            let sortedDevices = self.scannerModel.items.compactMap({ (item) -> (Double, MetaWear)? in
                guard let rssi = item.device.averageRSSI() else {
                    return nil
                }
                return (rssi, item.device)
            }).sorted { $0.0 > $1.0 }
            
            names.enumerated().forEach { (offset, element) in
                let pair = sortedDevices.first { return $0.1.name == element }
                if let device = pair?.1 {
                    if !self.foundDevices.contains(device) {
                        self.foundDevices.append(device)
                    }
                }
            }
            
            for (offset, pair) in self.foundDevices.enumerated() {
                self.rssiIcon[offset].image  = pair.signalImage()
                self.deviceMacLabel[offset].text = pair.mac
                if offset == 0 {
                    self.deviceColorView[offset].backgroundColor = .green
                    self.deviceNameLabel[offset].text = "Setting Up Green Sensor"
                } else {
                    self.deviceColorView[offset].backgroundColor = .blue
                    self.deviceNameLabel[offset].text = "Setting Up Blue Sensor"
                }
            }

            self.chosenDevices = self.foundDevices.count == names.count ? self.foundDevices : []
            
            self.updateCurrentConfig()
            
            if !self.chosenDevices.isEmpty {
                self.scannerModel.isScanning = false
                print("got both devices")
                self.blinkGreen(device: self.chosenDevices[0])
                self.blinkBlue(device: self.chosenDevices[1])
            }
        }
    }
    
    func blinkGreen(device: MetaWear) {
        device.connectAndSetup().continueWith(.mainThread) { t in
            if let error = t.error {
                print(error.localizedDescription)
            } else {
                device.flashLED(color: .green, intensity: 0.75, _repeat: 0xFF, onTime: 200, period: 1500)
            }
        }.continueOnSuccessWith(.mainThread) {
            print("turn green lower led")
            self.rssiIcon[0].image = #imageLiteral(resourceName: "signal1")
            self.deviceNameLabel[0].text = "Green Sensor Ready"
        }
    }

    func blinkBlue(device: MetaWear) {
        device.connectAndSetup().continueWith(.mainThread) { t in
            if let error = t.error {
                print(error.localizedDescription)
            } else {
                device.flashLED(color: .blue, intensity: 0.75, _repeat: 0xFF, onTime: 200, period: 1500)
            }
        }.continueOnSuccessWith(.mainThread) {
            print("turn blue upper led")
            self.rssiIcon[1].image = #imageLiteral(resourceName: "signal1")
            self.deviceNameLabel[1].text = "Blue Sensor Ready"
            self.startSessionButton.isEnabled = true
        }
    }
    
    @IBAction func calibrationChanged(_ sender: Any) {
        updateCurrentConfig()
    }
    
    @IBAction func sideChanged(_ sender: Any) {
        updateCurrentConfig()
    }
    
    @IBAction func typeChanged(_ sender: Any) {
        updateCurrentConfig()
        UIView.animate(withDuration: 0.3) {
            self.updateUIForSessionType()
        }
    }
    
    func updateUIForSessionType() {
        view.layoutIfNeeded()
    }
    
    @IBAction func anywhereTapped(_ sender: Any) {
        view.endEditing(false)
    }
    
    func updateCurrentConfig() {
        let curJoint = joints[jointPickerView.selectedRow(inComponent: 0)]
        
        let idx = sideSelector.isEnabled ? sideSelector.selectedSegmentIndex : 0
        currentJoint = curJoint.1[safe: idx]
        currentExercise = isFreeform ? nil : candidateExercises[safe: exercisePickerView.selectedRow(inComponent: 0)]?.1
        
        if let currentJoint = currentJoint {
            calibrationSelector.isEnabled = currentJoint.canTableCalibrate
            if !currentJoint.canTableCalibrate {
                calibrationSelector.selectedSegmentIndex = 0
            }
        }
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        scannerModel.isScanning = false
        //notFoundWatchdog?.invalidate()
        
        // Only update if changed
        if patient.lastJoint != jointField.text ||
            patient.lastSide.value != sideSelector.selectedSegmentIndex ||
            patient.lastCalibration.value != calibrationSelector.selectedSegmentIndex {
            let realm = try! Realm()
            try! realm.write {
                patient.lastJoint = jointField.text
                patient.lastSide.value = sideSelector.selectedSegmentIndex
                patient.lastCalibration.value = calibrationSelector.selectedSegmentIndex
            }
        }
        // Send back a fully configured StreamProcessor
        let result = StreamProcessor.getOrCreate(patient: patient,
                                                 upper: chosenDevices[0],
                                                 lower: chosenDevices[1],
                                                 joint: currentJoint!)
        let calibrateOnTable = calibrationSelector.isEnabled ? calibrationSelector.selectedSegmentIndex == 1 : false

        delegate?.didFinish(processor: result.0,
                            exercise: currentExercise,
                            alreadyCalibrated: !result.1,
                            calibrateOnTable: calibrateOnTable)
    }
    
    @IBAction func unwindToStartSessionViewController(segue: UIStoryboardSegue) {
        if segue.source is PlacementCalibrateViewController {
            StreamProcessor.remove(patient: patient)
        }
    }
}

extension MetaWear {
    func signalImage() -> UIImage {
        if let movingAverage = averageRSSI() {
            if (movingAverage < -100.0) {
                return #imageLiteral(resourceName: "signal5")
            } else if movingAverage < -90.0 {
                return #imageLiteral(resourceName: "signal4")
            } else if movingAverage < -80.0 {
                return #imageLiteral(resourceName: "signal3")
            } else if movingAverage < -70.0 {
                return #imageLiteral(resourceName: "signal2")
            } else {
                return #imageLiteral(resourceName: "signal1")
            }
        } else {
            return #imageLiteral(resourceName: "signal6")
        }
    }
}

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension ConfigureSessionViewController: ScannerModelDelegate {
    func scannerModel(_ scannerModel: ScannerModel, didAddItemAt idx: Int) {
        scannerModel.items[idx].stateDidChange = { [weak self] in
            self?.updateDetectedSensors()
        }
    }
    func scannerModel(_ scannerModel: ScannerModel, confirmBlinkingItem item: ScannerModelItem, callback: @escaping (Bool) -> Void) {
    }
    func scannerModel(_ scannerModel: ScannerModel, errorDidOccur error: Error) {
    }
}


extension ConfigureSessionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView === jointPickerView ? joints.count : candidateExercises.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerView === jointPickerView ?
            (row < joints.count ? joints[row].0 : nil) :
            (row < candidateExercises.count ? candidateExercises[row].0 : nil)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === jointPickerView {
            jointField.text = joints[row].0
            sideSelector.isEnabled = joints[row].1.count > 1
        }
        updateCurrentConfig()
    }
}

