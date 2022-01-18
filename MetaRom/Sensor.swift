//
//  Sensor.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 1/13/19.
//  Copyright © 2019 MBIENTLAB, INC. All rights reserved.
//

import RealmSwift

class Sensor: Object {
    @objc dynamic var name = ""
    @objc dynamic var side = ""
    @objc dynamic var joint = ""
    @objc dynamic var min: Double = 0.0
    @objc dynamic var max: Double = 0.0
    @objc dynamic var parent: Session?
    
    var titleLabel: String {
        return "\(config.side.displayName)\(config.joint.rawValue)"
    }
    lazy var config: JointConfig = { [unowned self] in
        if let side = Side(rawValue: self.side),
            let joint = Joint(rawValue: self.joint),
            let config = JointConfig.lookup[joint]?[side] {
            return config
        }
        fatalError("couldn't find JointConfig for: \(self.side) \(self.joint)")
    }()
    
    override static func ignoredProperties() -> [String] {
        return ["titleLabel", "config"]
    }
    
    func writeToFile(_ directory: URL, data: [(Date, Double)]) throws {
        let started = parent!.started
        var fileData = "\(csvHeaderRoot)\(name) (°)".data(using: .utf8)!
        data.forEach {
            let epoch = String($0.0.timeIntervalSince1970 * 1000)
            let time = Globals.msecDateFormatter.string(from: $0.0)
            let elapsed =  String(format: "%.1f", $0.0.timeIntervalSince(started))
            let value = String(format: "%.1f", $0.1)
            let row = "\n\(epoch),\(time),\(elapsed),\(value)"
            fileData.append(row.data(using: .utf8)!)
        }
        let url = directory.appendingPathComponent(name.pathSafe).appendingPathExtension("csv")
        try fileData.write(to: url)
    }
    
    func loadFromFile(_ directory: URL) -> [(Date, Double)] {
        let url = directory.appendingPathComponent(name.pathSafe).appendingPathExtension("csv")
        return url.processTheraCSV()
    }
}

extension URL {
    func processTheraCSV() -> [(Date, Double)] {
        guard let file = try? String(contentsOf: self, encoding: .utf8) else {
            return []
        }
        let lines = file.components(separatedBy: .newlines)
        guard lines.count > 0 else {
            return []
        }
        let data: [(Date, Double)] = lines[1...].compactMap {
            let entries = $0.components(separatedBy: ",")
            guard entries.count > 3,
                let value = Double(entries[3]),
                let epoch = Double(entries[0]) else {
                    return nil
            }
            return (Date(timeIntervalSince1970: epoch / 1000.0), value)
        }
        return data
    }
}

fileprivate let zoneFormatter = DateFormatter { $0.dateFormat = "ZZZZ" }
fileprivate var csvHeaderRoot: String {
    get {
        return "epoc (ms),timestamp (\(zoneFormatter.string(from: Date()))),elapsed (s),"
    }
}
