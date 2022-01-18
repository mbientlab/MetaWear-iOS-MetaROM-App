//
//  SessionSetupViewController.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 11/7/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import RMessage
import MetaWear
import CoreBluetooth

class SessionSetupViewController: UIViewController {
    @IBOutlet weak var pageTitleLabel: UILabel!
    
    let rControl = RMController()
    let spec: RMessageSpec = {
        var result = errorSpec
        result.durationType = .tapSwipe
        return result
    }()

    var patient: Patient!
    var sessionNumber: Int!
    var streamProcessor: StreamProcessor!
    var exercise: ExerciseConfig?
    var calibrateOnTable: Bool = false
    
    var pages: [(UIViewController, String)]!
    var pageController: UIPageViewController!
    //var configureController: ConfigureSessionViewController!
    //var greenSensorController: GreenSensorSessionViewController!
    
    enum Page: Int {
        case noSensors  = 0
        //case blueSensor = 1
        //case greenSensor = 2
        case configure = 1
        case placement = 2
        case calibrate = 3
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let noSensorsController = storyboard!.instantiateViewController(withIdentifier: "noSensorsFound")

        //let blueSensorController = (storyboard!.instantiateViewController(withIdentifier: "blueSensor") as! BlueSensorSessionViewController)
        //blueSensorController.delegate = self
        
        //greenSensorController = (storyboard!.instantiateViewController(withIdentifier: "greenSensor") as! GreenSensorSessionViewController)
        //greenSensorController.delegate = self
        
        let configureController = (storyboard!.instantiateViewController(withIdentifier: "configureSession") as! ConfigureSessionViewController)
        configureController.patient = patient
        configureController.sessionNumber = sessionNumber
        configureController.delegate = self
        
        let placementController = (storyboard!.instantiateViewController(withIdentifier: "placementAndCalibrate") as! PlacementCalibrateViewController)
        placementController.isPlacement = true
        placementController.delegate = self
        
        let calibrateController = (storyboard!.instantiateViewController(withIdentifier: "placementAndCalibrate") as! PlacementCalibrateViewController)
        calibrateController.isPlacement = false
        calibrateController.delegate = self

        pages = [
            (noSensorsController, "Turn On Sensors"),
            (configureController, "Configure Your Session"),
            (placementController, "Place Sensors On Patient As Shown"),
            (calibrateController, "Calibrate When Ready")
        ]
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        willEnterForeground()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func willEnterForeground() {
        MetaWearScanner.shared.didUpdateState = { [weak self] central in
            DispatchQueue.main.async {
                self?.showBluetoothErrors(central)
            }
        }
    }
    
    func showBluetoothErrors(_ central: CBCentralManager) {
        switch central.state {
        case .unsupported:
            rControl.showMessage(
                withSpec: spec,
                title: "Bluetooth Error",
                body: "Device doesn't support the Bluetooth Low Energy."
            )
        case .unauthorized:
            rControl.showMessage(
                withSpec: spec,
                title: "Bluetooth Error",
                body: "The application is not authorized to use the Bluetooth Low Energy."
            )
        case .poweredOff:
            rControl.showMessage(
                withSpec: spec,
                title: "Bluetooth Error",
                body: "Bluetooth is currently powered off.  Please enable it in settings."
            )
        case .poweredOn:
            rControl.cancelPendingDisplayMessages()
            let _ = rControl.dismissOnScreenMessage()
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //streamProcessor = nil
        //self.chosenDevices = []
        //greenSensorController.alreadyChosenDevice = nil
        //showController(.blueSensor, direction: .forward, animated: false)
        showController(.configure, direction: .forward, animated: false)
    }
    
    func showController(_ page: Page, direction: UIPageViewController.NavigationDirection, animated: Bool = true) {
        let pair = pages[page.rawValue]
        if let controller = pair.0 as? PlacementCalibrateViewController {
            controller.streamProcessor = streamProcessor
            controller.calibrateOnTable = calibrateOnTable
        }
        pageController.setViewControllers([pair.0], direction: direction, animated: animated) { _ in
            self.pageTitleLabel.text = pair.1
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UIPageViewController {
            pageController = destination
        } else if let destination = segue.destination as? SessionViewController {
            destination.streamProcessor = streamProcessor
            //destination.exercise = exercise
            destination.patient = patient
            destination.sessionNumber = sessionNumber
        }
    }
}

/*extension SessionSetupViewController: BlueSensorSessionDelegate {
    func didFinish(upper: MetaWear) {
        self.chosenDevices.append(upper)
        print(self.chosenDevices)
        greenSensorController.alreadyChosenDevice = upper
        showController(.greenSensor, direction: .forward)
    }
}

extension SessionSetupViewController: GreenSensorSessionDelegate {
    func didFinish(lower: MetaWear) {
        self.chosenDevices.append(lower)
        print(self.chosenDevices)
        configureController.chosenDevices = self.chosenDevices
        showController(.configure, direction: .forward)
    }
}*/

extension SessionSetupViewController: ConfigureSessionDelegate {
    func didFinish(processor: StreamProcessor, exercise: ExerciseConfig?, alreadyCalibrated: Bool, calibrateOnTable: Bool) {
        self.streamProcessor = processor
        self.exercise = exercise
        self.calibrateOnTable = calibrateOnTable
        showController(calibrateOnTable ? .calibrate: .placement, direction: .forward)
    }
    
    func notFoundStateDidChange(_ notFoundShown: Bool) {
        if notFoundShown {
            showController(.noSensors, direction: .reverse)
        } else {
            showController(.configure, direction: .forward)
        }
    }
}

extension SessionSetupViewController: PlacementCalibrateDelegate {
    func hidesBackButton(_ value: Bool) {
        navigationItem.hidesBackButton = value
    }
    
    func didFinish(_ controller: PlacementCalibrateViewController) {
        if controller.isPlacement && !calibrateOnTable {
            showController(.calibrate, direction: .forward)
        } else if !controller.isPlacement && calibrateOnTable {
            showController(.placement, direction: .forward)
        } else {
            performSegue(withIdentifier: "showSession", sender: nil)
        }
    }
}
