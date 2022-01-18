//
//  Patient.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 5/24/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

//import Parse
import BoltsSwift
import RealmSwift
import MetaWear


class Patient: Object {    
    @objc dynamic var parseObjectId: String?
    @objc dynamic var firstName: String = ""
    @objc dynamic var lastName: String = ""
    @objc dynamic var dateOfBirth: Date?
    @objc dynamic var gender: String?
    @objc dynamic var patientID: String = ""
    @objc dynamic var phoneNumber: String?
    @objc dynamic var email: String?
    @objc dynamic var address: String?
    let heightCm = RealmOptional<Float>()
    let weightKg = RealmOptional<Float>()
    @objc dynamic var injury: String?
    @objc dynamic var lastSession: Date?
    @objc dynamic var lastJoint: String?
    let lastSide = RealmOptional<Int>()
    let lastType = RealmOptional<Int>()
    let lastCalibration = RealmOptional<Int>()
    @objc dynamic var lastExercise: String?
    
    @objc dynamic var exerciseThresholdsBackingData: Data? = nil
    var exerciseThresholds: [String: ClosedRange<Double>] {
        get {
            if let data = exerciseThresholdsBackingData {
                return try! JSONDecoder().decode([String: ClosedRange<Double>].self, from: data)
            }
            return [:]
        }
        set {
            exerciseThresholdsBackingData = try! JSONEncoder().encode(newValue)
        }
    }
    
    @objc dynamic var routineBackingData: Data? = nil
    var routines: [RoutineConfig] {
        get {
            if let data = routineBackingData {
                return try! JSONDecoder().decode([RoutineConfig].self, from: data)
            }
            return []
        }
        set {
            routineBackingData = try! JSONEncoder().encode(newValue)
        }
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var searchString: String {
        return "\(firstName) \(lastName) \(patientID)"
    }
    

    func exerciseThresholdRange(_ exercise: ExerciseConfig) -> ClosedRange<Double> {
        guard let current = exerciseThresholds[exercise.name] else {
            return exercise.exerciseThreshold
        }
        return current
    }
    
    func updateExerciseThresholdRange(_ name: String, range: ClosedRange<Double>) {
        let realm = try! Realm()
        var array = exerciseThresholds
        if let current = array[name], current == range {
            return
        }
        array[name] = range
        try! realm.write {
            exerciseThresholds = array
        }
    }
    
    func delete() {
        let realm = try! Realm()
        // Remove their sessions
        let sessions = realm.objects(Session.self).filter("patient == %@", self)
        // We only need to delete the sessions locally since the server takes care
        // of cleaning up all sessions when deleting the patient.
        sessions.forEach { $0.delete(localOnly: true) }
        try! realm.write {
            if let parseObjectId = parseObjectId {
                let op = DeleteOp()
                op.isPatient = true
                op.parseObjectId = parseObjectId
                realm.add(op)
            }
            realm.delete(self)
        }
    }
    
    func updateLastSession() {
        // Since notification listener on the allPatient token is what we use to
        // sync local changes to Parse, we don't want it to fire for changes to
        // lastSession.  The Parse server handles lastSession updates on its own.
        let tokens: [NotificationToken] = NotificationToken.allPatients == nil ? [] : [NotificationToken.allPatients!]
        let realm = try! Realm()
        realm.beginWrite()
        // Update lastSession
        if let newest = realm.objects(Session.self).filter("patient == %@", self).sorted(byKeyPath: "started", ascending: false).first {
            lastSession = newest.started
        } else {
            lastSession = nil
        }
        try! realm.commitWrite(withoutNotifying: tokens)
    }

}
