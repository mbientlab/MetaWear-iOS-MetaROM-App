//
//  BlueSensorSessionViewController.swift
//  MetaRom
//
//  Created by Laura Kassovic on 1/26/21.
//  Copyright © 2021 MBIENTLAB, INC. All rights reserved.
//

import Foundation
import UIKit
import BoltsSwift
import MetaWear
import MetaWearCpp
import CoreBluetooth
import RealmSwift

protocol BlueSensorSessionDelegate: class {
    func didFinish(upper: MetaWear)
}

class BlueSensorSessionViewController: UIViewController {
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var searchingLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    weak var delegate: BlueSensorSessionDelegate?
    var scannerModel: ScannerModel!
    var chosenDevice: MetaWear?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        scannerModel = ScannerModel(delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        chosenDevice = nil
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
            let sortedDevices = self.scannerModel.items.compactMap({ (item) -> (Double, MetaWear)? in
                guard let rssi = item.device.averageRSSI() else {
                    return nil
                }
                return (rssi, item.device)
            }).sorted { $0.0 > $1.0 }
            
            if sortedDevices.count > 0 && self.chosenDevice == nil {
                self.chosenDevice = sortedDevices.first?.1
                self.chosenDevice!.connectAndSetup().continueWith(.mainThread) { t in
                    if let error = t.error {
                        print(error.localizedDescription)
                    } else {
                        print("turn blue upper led")
                        self.chosenDevice!.flashLED(color: .blue, intensity: 0.75, _repeat: 0xFF, onTime: 200, period: 1500)
                    }
                }.continueOnSuccessWith(.mainThread) { t in
                    if self.chosenDevice != nil {
                        self.searchingLabel.text = "FOUND SENSOR."
                        self.resetButton.isEnabled = true
                        self.nextButton.isEnabled = true
                        self.scannerModel.isScanning = false
                        self.activityIndicator.stopAnimating()
                    }
                }
            }

        }
    }
    
    func updateUIForSessionType() {
        view.layoutIfNeeded()
        searchingLabel.text = "SEARCHING..."
        activityIndicator.startAnimating()
    }
    
    @IBAction func resetPressed(_ sender: Any) {
        // Update UI
        updateUIForSessionType()
        // Turn off scanner
        scannerModel.isScanning = false
        // Turn off next Button
        self.nextButton.isEnabled = false
        // Turn off led on metasesnor
        if self.chosenDevice != nil {
            self.chosenDevice!.connectAndSetup().continueWith { t -> () in
                if let error = t.error {
                    print(error.localizedDescription)
                } else {
                    mbl_mw_debug_reset(self.chosenDevice!.board)
                    print("turn off led")
                }
            }.continueOnSuccessWith { t in
                // Remove found devices
                self.chosenDevice = nil
            }
        }
        // Delay
        do {
            sleep(2)
        }
        // Double check everything is disconnected and restart
        StreamProcessor.stopAll()
        MetaWearScanner.shared.deviceMap.forEach { $1.cancelConnection() }
        scannerModel.isScanning = true
        scannerModel.items.forEach {
            $0.stateDidChange = { [weak self] in
                self?.updateDetectedSensors()
            }
        }
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        self.resetButton.isEnabled = false
        activityIndicator.stopAnimating()
        scannerModel.isScanning = false
        self.nextButton.isEnabled = false
        self.delegate?.didFinish(upper: self.chosenDevice!)
    }
    
}

extension BlueSensorSessionViewController: ScannerModelDelegate {
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
