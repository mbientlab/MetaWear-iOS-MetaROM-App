//
//  AddPatientViewController.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 6/1/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
//import Parse
import RealmSwift

protocol AddEditPatientDelegate: class {
    func controller(_ controller: AddEditPatientViewController, didAddPatient patient: Patient)
    func controller(_ controller: AddEditPatientViewController, didEditPatient patient: Patient)
    func controllerDidCancel(_ controller: AddEditPatientViewController)
}

class AddEditPatientViewController: UIViewController {
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet var allTextFields: [UITextField]!
    
    weak var delegate: AddEditPatientDelegate?
    var patient: Patient?
    
    // TO DO
    //var doctor: PFUser!
    var activeField: UITextField = UITextField()
    let requiredTextFields = [0, 1, 2]
    let datePicker: UIDatePicker = {
        let tmp = UIDatePicker()
        if #available(iOS 14, *) {
            tmp.preferredDatePickerStyle = .wheels
            tmp.sizeToFit()
        }
        tmp.maximumDate = Date()
        tmp.addTarget(self, action: #selector(handleDatePicker(sender:)), for: UIControl.Event.valueChanged)
        tmp.datePickerMode = .date
        return tmp
    }()
    let genderPickerView = UIPickerView()
    let genders = [
        "",
        "Male",
        "Female",
        "Other"
    ]
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        
        allTextFields[3].inputView = genderPickerView
        allTextFields[4].inputView = datePicker
        allTextFields.forEach { $0.delegate = self }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // TO DO
        //guard let cur = PFUser.current() else {
        //    delegate?.controllerDidCancel(self)
        //    return
        //}
        //doctor = cur
        
        if let patient = patient {
            allTextFields[0].text = patient.firstName
            allTextFields[1].text = patient.lastName
            allTextFields[2].text = patient.patientID
            allTextFields[3].text = patient.gender
            if let dob = patient.dateOfBirth {
                datePicker.date = dob
                handleDatePicker(sender: datePicker)
            }
            allTextFields[5].text = patient.phoneNumber
            allTextFields[6].text = patient.email
            allTextFields[7].text = patient.address
            allTextFields[8].text = patient.heightCm.value != nil ? String(patient.heightCm.value!) : ""
            allTextFields[9].text = patient.weightKg.value != nil ? String(patient.weightKg.value!) : ""
            allTextFields[10].text = patient.injury
            textFieldDidEndEditing(allTextFields[0])
        }
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        let didAdd = self.patient == nil
        let patient = self.patient ?? Patient()
        
        let realm = try! Realm()
        try! realm.write {
            patient.firstName = allTextFields[0].text!
            patient.lastName = allTextFields[1].text!
            patient.patientID = allTextFields[2].text!
            
            if let value = allTextFields[3].text, !value.isEmpty {
                patient.gender = value
            } else {
                patient.gender = nil
            }
            if let value = allTextFields[4].text, !value.isEmpty {
                patient.dateOfBirth = datePicker.date
            } else {
                patient.dateOfBirth = nil
            }
            if let value = allTextFields[5].text, !value.isEmpty {
                patient.phoneNumber = value
            } else {
                patient.phoneNumber = nil
            }
            if let value = allTextFields[6].text, !value.isEmpty {
                patient.email = value
            } else {
                patient.email = nil
            }
            if let value = allTextFields[7].text, !value.isEmpty {
                patient.address = value
            } else {
                patient.address = nil
            }
            if let value = allTextFields[8].text, !value.isEmpty, let heightCm = Float(value) {
                patient.heightCm.value = heightCm
            } else {
                patient.heightCm.value = nil
            }
            if let value = allTextFields[9].text, !value.isEmpty, let weightKg = Float(value) {
                patient.weightKg.value = weightKg
            } else {
                patient.weightKg.value = nil
            }
            if let value = allTextFields[10].text, !value.isEmpty {
                patient.injury = value
            } else {
                patient.injury = nil
            }
            
            if didAdd {
                realm.add(patient)
            }
        }
        if didAdd {
            self.delegate?.controller(self, didAddPatient: patient)
        } else {
            self.delegate?.controller(self, didEditPatient: patient)
        }
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        delegate?.controllerDidCancel(self)
    }
    
    @IBAction func anywhereTapped(_ sender: Any) {
        view.endEditing(false)
    }
    
    @objc func handleDatePicker(sender: UIDatePicker) {
        allTextFields[4].text = DateFormatter.localizedString(from: datePicker.date, dateStyle: .short, timeStyle: .none)
    }
    
    func nextTextField() {
        if let next = view.viewWithTag(activeField.tag + 1) {
            next.becomeFirstResponder()
        } else {
            activeField.resignFirstResponder()
        }
    }
}

extension AddEditPatientViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        let notReady = requiredTextFields.contains { allTextFields[$0].text! == "" }
        submitButton.isEnabled = !notReady
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextTextField()
        return false
    }
}


extension AddEditPatientViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genders.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genders[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        allTextFields[3].text = genders[row]
    }
}

