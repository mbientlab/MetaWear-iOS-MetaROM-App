//
//  TheragoniTests.swift
//  TheragoniTests
//
//  Created by Stephen Schiffli on 4/25/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import XCTest
@testable import Theragonio
import Parse
import Fakery

class TheragoniTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let user = try! PFUser.logIn(withUsername: "stephen@mbientlab.com", password: "stephen")
        let patient = ParsePatient.from(doctor: user)
        patient.firstName = "Ryan"
        patient.lastName = "Jones"
        patient.dateOfBirth = Calendar.current.date(from: DateComponents(year: 1950, month: 9, day: 10))!
        patient.gender = "Female"
        patient.patientID = "455764323"
        patient.phoneNumber = "1-867-352-5555"
        patient.email = "bigjman@yahoo.com"
        patient.address = "Classy Suburb, EFE 54443"
        patient.heightCm = 187
        patient.weightKg = 122
        patient.injury = "Dislocated Left Shoulder"
        try! patient.save()
    }
    
    func testCreateLotsOfPatients() {
        let user = try! PFUser.logIn(withUsername: "sschiffli@gmail.com", password: "stephen")
        let faker = Faker()
        for _ in 0...2000 {
            let patient = ParsePatient.from(doctor: user)
            patient.firstName = faker.name.firstName()
            patient.lastName = faker.name.lastName()
            patient.dateOfBirth = Calendar.current.date(from: DateComponents(year: 1950, month: 9, day: 10))!
            patient.gender = faker.gender.binaryType()
            patient.patientID = faker.internet.password(minimumLength: 8, maximumLength: 8)
            patient.phoneNumber = faker.phoneNumber.phoneNumber()
            patient.email = faker.internet.email()
            let state = faker.address.stateAbbreviation()
            patient.address = "\(faker.address.streetAddress()), \(state) \(faker.address.postcode(stateAbbreviation: state))"
            patient.heightCm = faker.number.randomInt(min: 50, max: 240) as NSNumber
            patient.weightKg = faker.number.randomInt(min: 20, max: 180) as NSNumber
            patient.injury = faker.company.bs()
            try! patient.save()
        }
    }
    
    
    func testSignUp() {
        let user = PFUser()
        user.username = "demo@mbientlab.com"
        user.email = "demo@mbientlab.com"
        user.password = "mbient123"
        try! user.signUp()
    }
    
    func testSaveIllegal() {
        let user = try! PFUser.logIn(withUsername: "stephen@mbientlab.com", password: "stephen")
        
        user.setValue(44, forKey: "patientsMax")
        try! user.save()
    }
    
    func testBigUpload() {
        let wait = expectation(description: "wait")
        
        let user = try! PFUser.become("r:xxxxxxx")
        try! user.fetchIfNeeded()
        let patient = ParsePatient(withoutDataWithObjectId: "xxxxxx")
        try! patient.fetchIfNeeded()
        let totalEntries = 12000
        let measurements: [MetaClinic.Measurement] = [.flexionExtension, .radialUlnar]
        let streamStart = Date()
        let sensors = measurements.map { meas -> [String : AnyObject] in
            let data = (0...totalEntries).map { _ in return [Date(),  Double.random(in: -180.0...180.0)] }
            return ["data": data as AnyObject,
                    "name": meas.rawValue as AnyObject,
                    "joint": Joint.wrist.rawValue as AnyObject,
                    "side": Side.left.rawValue as AnyObject]
        }
        let session = ParseSession.from(patient: patient,
                                   sensors: sensors,
                                   started: streamStart)
        let methodStart = Date()
        Parse.setLogLevel(.debug)
        session.saveEventually() { (success, error) in
            print(success, error ?? "N/A");
            let methodFinish = Date()
            let executionTime = methodFinish.timeIntervalSince(methodStart)
            print("Execution time: \(executionTime)")
            if success {
                session.deleteInBackground { (success, error) in
                    wait.fulfill()
                }
            } else {
                wait.fulfill()
            }
        }

        waitForExpectations(timeout: 60000, handler: nil)
    }
}
