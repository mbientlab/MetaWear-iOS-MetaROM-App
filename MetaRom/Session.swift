//
//  Session.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 6/6/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

//import Parse
import RealmSwift
import Zip
import BoltsSwift
import MetaWear

class Session: Object {
    @objc dynamic var parseObjectId: String?
    @objc dynamic var name = ""
    @objc dynamic var started: Date = Date()
    @objc dynamic var ended: Date = Date()
    let sensors = LinkingObjects(fromType: Sensor.self, property: "parent")
    @objc dynamic var patient: Patient?
    @objc dynamic var exerciseName: String?
    var exercise: ExerciseConfig? {
        return exerciseName == nil ? nil : ExerciseConfig.lookup[exerciseName!]
    }
    let thresholds = List<Double>()
    let reps = RealmOptional<Int>()
    let repAtTop = RealmOptional<Bool>()
    
    var zipFilename: String {
        let patientID = patient!.patientID
        let timestamp = Globals.dateFormatter.string(from: started)
        return "\(patientID)_\(name.pathSafe)_\(timestamp)"
    }
    var zipFileURL: URL {
        // File in the temp dir if sync'd to Parse
        return Globals.cloudSyncMode && parseObjectId != nil ?
            Globals.temporaryDirectory.appendingPathComponent(zipFilename).appendingPathExtension("zip") :
            Globals.documentDirectory.appendingPathComponent(zipFilename).appendingPathExtension("zip")
    }
    var source: TaskCompletionSource<Void>?

    override static func ignoredProperties() -> [String] {
        return ["source"]
    }
    
    static func saveNew(patient: Patient,
                        measurements: [MeasurementData],
                        side: Side,
                        joint: Joint,
                        parseObjectId: String? = nil,
                        exerciseName: String? = nil,
                        exerciseThreshold: ClosedRange<Double>? = nil,
                        reps: Int? = nil,
                        repAtTop: Bool? = nil) throws {
        let needsSyncd = Globals.cloudSyncMode && (parseObjectId == nil)
        var data: [(Sensor, [(Date, Double)])] = []
        let realm = try Realm()
        let session = Session()
        try realm.write {
            session.parseObjectId = parseObjectId
            session.name = "\(side.displayName)\(exerciseName != nil ? exerciseName! : joint.rawValue)"
            session.started = measurements.oldestTimestamp
            session.ended = measurements.newestTimestamp
            session.patient = patient
            session.exerciseName = exerciseName
            if let exerciseThreshold = exerciseThreshold {
                session.thresholds.append(exerciseThreshold.lowerBound)
                session.thresholds.append(exerciseThreshold.upperBound)
            }
            session.reps.value = reps
            session.repAtTop.value = repAtTop
            realm.add(session)
            // Create temp folder for session data to be saved
            let tempDir = Globals.temporaryDirectory.appendingPathComponent(session.zipFilename, isDirectory: true)
            try? FileManager.default.removeItem(at: tempDir)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: false, attributes: nil)
            defer {
                try? FileManager.default.removeItem(at: tempDir)
            }
            
            try measurements.forEach { measurement in
                let sensor = Sensor()
                sensor.name = measurement.measurement.rawValue
                sensor.side = side.rawValue
                sensor.joint = joint.rawValue
                sensor.min = measurement.sessionData.min { $0.1 < $1.1 }!.1
                sensor.max = measurement.sessionData.max { $0.1 < $1.1 }!.1
                sensor.parent = session
                realm.add(sensor)
                try sensor.writeToFile(tempDir, data: measurement.sessionData)
                if needsSyncd {
                    data.append((sensor, measurement.sessionData))
                }
            }
            
            // ZIP the data to the permeant location
            var url = session.zipFileURL
            try Zip.zipFiles(paths: [tempDir], zipFilePath: url, password: nil, progress: nil)
            // Don't back this up in iCloud
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        }
        patient.updateLastSession()
    }
    
    func delete(localOnly: Bool = false) {
        try? FileManager.default.removeItem(at: zipFileURL)
        let realm = try! Realm()
        let patient = self.patient!
        try! realm.write {
            if !localOnly, let parseObjectId = parseObjectId {
                let op = DeleteOp()
                op.isPatient = false
                op.parseObjectId = parseObjectId
                realm.add(op)
            }
            realm.delete(sensors)
            realm.delete(self)
        }
        patient.updateLastSession()
    }
    
    func loadFromZip() -> Task<[(Sensor, [(Date, Double)])]> {
        let source = TaskCompletionSource<[(Sensor, [(Date, Double)])]>()

        let tempDir = Globals.temporaryDirectory
        let outputFolder = tempDir.appendingPathComponent(zipFilename, isDirectory: true)
        do {
            try Zip.unzipFile(zipFileURL, destination: tempDir, overwrite: true, password: nil)
            defer {
                try? FileManager.default.removeItem(at: outputFolder)
            }
            let result: [(Sensor, [(Date, Double)])] = sensors.map { ($0, $0.loadFromFile(outputFolder)) }
            source.trySet(result: result)
        /*} catch ZipError.fileNotFound {
            loadFromParse().continueWith(.mainThread) { t in
                if let error = t.error {
                    source.trySet(error: error)
                } else {
                    do {
                        try Zip.unzipFile(self.zipFileURL, destination: tempDir, overwrite: true, password: nil)
                        defer {
                            try? FileManager.default.removeItem(at: outputFolder)
                        }
                        let result: [(Sensor, [(Date, Double)])] = self.sensors.map { ($0, $0.loadFromFile(outputFolder)) }
                        source.trySet(result: result)
                    } catch {
                        source.trySet(error: error)
                    }
                   
                }
            }*/
        } catch {
            source.trySet(error: error)
        }
        return source.task
    }
}

extension Sequence where Iterator.Element == MeasurementData {
    var oldestTimestamp: Date {
        get {
            let dates = self.compactMap { $0.sessionData.first?.0 }
            return dates.min() ?? Date(timeIntervalSince1970: 0)
        }
    }
    var newestTimestamp: Date {
        get {
            let dates = self.compactMap { $0.sessionData.last?.0 }
            return dates.max() ?? Date(timeIntervalSince1970: 0)
        }
    }
}
