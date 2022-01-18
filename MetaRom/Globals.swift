//
//  Globals.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 5/29/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
//import Bolts
import BoltsSwift
import RealmSwift

extension UIColor {
    static let darkYellowGreen = #colorLiteral(red: 0.3529411765, green: 0.5882352941, blue: 0, alpha: 1)
    static let steelGrey = #colorLiteral(red: 0.4588235294, green: 0.5176470588, blue: 0.5254901961, alpha: 1)
    static let turquoiseBlue = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.7490196078, alpha: 1)
    static let darkLime = #colorLiteral(red: 0.5450980392, green: 0.7490196078, blue: 0, alpha: 1)
    static let tomato = #colorLiteral(red: 0.8470588235, green: 0.1333333333, blue: 0.1333333333, alpha: 1)
    static let axisSilver = #colorLiteral(red: 0.7960784314, green: 0.8117647059, blue: 0.8431372549, alpha: 1)
    
    //joint colors
    static let leftKnee = #colorLiteral(red: 1, green: 0.5254901961, blue: 0.4431372549, alpha: 1)
    static let rightKnee = #colorLiteral(red: 0.7764705882, green: 0.007843137255, blue: 0.1137254902, alpha: 1)
    static let leftElbow = #colorLiteral(red: 0.9490196078, green: 0.7725490196, blue: 0.06666666667, alpha: 1)
    static let rightElbow = #colorLiteral(red: 0.7607843137, green: 0.6196078431, blue: 0.05490196078, alpha: 1)
    static let leftForearm = #colorLiteral(red: 0, green: 0.7725490196, blue: 0.737254902, alpha: 1)
    static let rightForearm = #colorLiteral(red: 0, green: 0.6196078431, blue: 0.5882352941, alpha: 1)
    static let leftAnkle = #colorLiteral(red: 0.5568627451, green: 0.262745098, blue: 0.6784313725, alpha: 1)
    static let rightAnkle = #colorLiteral(red: 0.4470588235, green: 0.2117647059, blue: 0.5411764706, alpha: 1)
    static let leftShoulder = #colorLiteral(red: 0.2, green: 0.5960784314, blue: 0.8588235294, alpha: 1)
    static let rightShoulder = #colorLiteral(red: 0.1607843137, green: 0.4784313725, blue: 0.6862745098, alpha: 1)
    static let leftHip = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
    static let rightHip = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    static let leftWrist = #colorLiteral(red: 0.7764705882, green: 0.007843137255, blue: 0.4980392157, alpha: 1)
    static let rightWrist = #colorLiteral(red: 0.6196078431, green: 0.007843137255, blue: 0.4, alpha: 1)
    static let neck = #colorLiteral(red: 0.1450980392, green: 0.6392156863, blue: 0.3529411765, alpha: 1)
    static let spine = #colorLiteral(red: 0.968627451, green: 0.3607843137, blue: 0.01176470588, alpha: 1)
}

let graphLineColors: [UIColor] = [.turquoiseBlue, .darkLime, .tomato]

extension Collection where Element: BinaryFloatingPoint {
    var sum: Element {
        return self.reduce(0, +)
    }
    var average: Element {
        return self.sum / Element(self.count)
    }
    var stdev: Element {
        let mean = self.average
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }
}

struct Globals {
    static var cachedEmail: String {
        get { return UserDefaults.standard.string(forKey: "cachedEmail") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "cachedEmail") }
    }
    static let autoLogoutTime: TimeInterval = 8 * 60 * 60 // 8 hours
    static var backgroundDate: Date {
        get { return UserDefaults.standard.value(forKey: "backgroundDate") as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "backgroundDate") }
    }
    static var expirationDate: Date {
        get { return UserDefaults.standard.value(forKey: "expirationDate") as? Date ?? Date(timeIntervalSince1970: 0) }
        set { UserDefaults.standard.set(newValue, forKey: "expirationDate") }
    }
    static var isExpired: Bool {
        // Extra 2 days (well only 40 hours) leeway as Stripe suggests
        return Globals.expirationDate.timeIntervalSinceNow < -(60 * 60 * 40)
    }
    static var maxPatients: Int {
        get { return UserDefaults.standard.object(forKey: "maxPatients") as? Int ?? 1000 }
        set { UserDefaults.standard.set(newValue, forKey: "maxPatients") }
    }
    static var cloudSyncMode: Bool {
        get { return UserDefaults.standard.object(forKey: "cloudSyncMode") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "cloudSyncMode") }
    }
    static var seenManualScreens: Bool {
        get { return UserDefaults.standard.object(forKey: "seenManualScreens") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "seenManualScreens") }
    }
    static var seenPlacementPopup: Bool {
        get { return UserDefaults.standard.object(forKey: "seenPlacementPopup") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "seenPlacementPopup") }
    }
    static var seenSessionWalkthrough: Bool {
        get { return UserDefaults.standard.object(forKey: "seenSessionWalkthrough") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "seenSessionWalkthrough") }
    }
    static let applicationSupportDirectory = FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    static let documentDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    static let cachesDirectory = FileManager().urls(for: .cachesDirectory, in: .userDomainMask).first!    

    static let msecDateFormatter = DateFormatter { $0.dateFormat = "yyyy-MM-dd'T'HH.mm.ss.SSS" }
    static let dateFormatter = DateFormatter { $0.dateFormat = "yyyy-MM-dd'T'HH.mm.ss" }
    
    static let quaternionAverageId: UInt8 = 0
    
    static let state1_4_97 = "02610401013519010000000200010203000301020004FFFF05FFFF06FFFF0700000008FFFF090002011C0A0000011C0B00020508000027100C000001080DFFFF0F000202080710FFFF110007010312FFFF1300010014FFFF1500020016FFFF17FFFF18FFFF190002080300060002000100FE0003003701010000010000000000010101000100000000000101FF000100010100000304FF000702030201000304FF000802010201000304FF000802010201020304FF00080201020104030BFF00210001010000030EFF002400010100000311FF001C00010100000319FF00010001010000031CFF0007020302010003DAFF0001000102000009030000010001010000FF03010000000709030100010001010000FF03010000000709030200160004040100FF0102001109C4000001000101000009C401000100010100000BC4FF001F00010500000BC5FF000100010400000C0600000C060100110AFF001111000109010000000000111101000100000000001111FF00010001010000111200040405060A01000000000011120104000102030100000000001112FF0001000101000011CBFF001D000106000011CCFF000E000103000011CCFF0001000102000111CCFF0001000101000011D1FF0001000101000011D100010701000000000011D10101080100000000001305FF000504030201001305FF000604010201001305FF000604010201021305FF000604010201041307FF000504030201001505FF000C08030201001505FF000D08010201001505FF000D08010201021505FF000D08010201041509FF000C08030201001904FF001A00010D01001905FF001800010D01001906FF001800010D01001907FF001600040401001908FF001700040401001909FF00190003040100190AFF0019000304010019CBFF00220003010000FEC4FF000100010400000303280C0730810BC000141414040A1848081100001328001902130801999BCA5A6A0100000000".hexaBytes
    
    static let state1_4_4 = "02040401013519010000000200010203000301020004FFFF05FFFF06FFFF0700000008FFFF090002011C0A0000011C0B00020508000027100C000001080DFFFF0F000202080710FFFF110007010312FFFF1300010014FFFF1500020016FFFF17FFFF18FFFF190002080300060002000100FE0003003701010000010000000000010101000100000000000101FF000100010100000304FF000702030201000304FF000802010201000304FF000802010201020304FF00080201020104030BFF00210001010000030EFF002400010100000311FF001C00010100000319FF00010001010000031CFF0007020302010003DAFF0001000102000009030000010001010000FF03010000000709030100010001010000FF03010000000709030200160004040100FF0102001109C4000001000101000009C401000100010100000BC4FF001F00010500000BC5FF000100010400000C0600000C060100110AFF001111000109010000000000111101000100000000001111FF00010001010000111200040405060A01000000000011120104000102030100000000001112FF0001000101000011CBFF001D000106000011CCFF000E000103000011CCFF0001000102000111CCFF0001000101000011D1FF0001000101000011D100010701000000000011D10101080100000000001305FF000504030201001305FF000604010201001305FF000604010201021305FF000604010201041307FF000504030201001505FF000C08030201001505FF000D08010201001505FF000D08010201021505FF000D08010201041509FF000C08030201001904FF001A00010D01001905FF001800010D01001906FF001800010D01001907FF001600040401001908FF001700040401001909FF00190003040100190AFF0019000304010019CBFF00220003010000FEC4FF000100010400000303280C0730810BC000141414040A1848081100001328001902130801CF4AC95A6A0100000000".hexaBytes

    static let state1_5_0 = "02000501013519010000000200010203000301020004FFFF05FFFF06FFFF0700000008FFFF090002011C0A0000011C0B00020508000027100C000001080DFFFF0F000202080710FFFF110007010312FFFF1300010014FFFF1500020016FFFF17FFFF18FFFF190002080300060002000100FE0003003701010000010000000000010101000100000000000101FF000100010100000304FF000702030201000304FF000802010201000304FF000802010201020304FF00080201020104030BFF00210001010000030EFF002400010100000311FF001C00010100000319FF00010001010000031CFF0007020302010003DAFF0001000102000009030000010001010000FF03010000000709030100010001010000FF03010000000709030200160004040100FF0102001109C4000001000101000009C401000100010100000BC4FF001F00010500000BC5FF000100010400000C0600000C060100110AFF001111000109010000000000111101000100000000001111FF00010001010000111200040405060A01000000000011120104000102030100000000001112FF0001000101000011CBFF001D000106000011CCFF000E000103000011CCFF0001000102000111CCFF0001000101000011D1FF0001000101000011D100010701000000000011D10101080100000000001305FF000504030201001305FF000604010201001305FF000604010201021305FF000604010201041307FF000504030201001505FF000C08030201001505FF000D08010201001505FF000D08010201021505FF000D08010201041509FF000C08030201001904FF001A00010D01001905FF001800010D01001906FF001800010D01001907FF001600040401001908FF001700040401001909FF00190003040100190AFF0019000304010019CBFF00220003010000FEC4FF000100010400000303280C0730810BC000141414040A1848081100001328001902130801DDF0FCC5700100000000".hexaBytes
}

extension String {
    var hexaBytes: [UInt8] {
        var position = startIndex
        return (0..<count/2).compactMap { _ in
            defer { position = index(position, offsetBy: 2) }
            return UInt8(self[position...index(after: position)], radix: 16)
        }
    }
    var hexaData: Data { return hexaBytes.data }
    
    var pathSafe: String {
        return spaceToDash.forwardSlashToDash
    }
    var spaceToDash: String {
        get {
            return self.replacingOccurrences(of: " ", with: "-", options: NSString.CompareOptions.literal, range: nil)
        }
    }
    var forwardSlashToDash: String {
        get {
            return self.replacingOccurrences(of: "/", with: "-", options: NSString.CompareOptions.literal, range: nil)
        }
    }
}

extension Collection where Iterator.Element == UInt8 {
    var data: Data {
        return Data(self)
    }
    var hexa: String {
        return map{ String(format: "%02X", $0) }.joined()
    }
}

extension Double {
    func precised(_ value: Int = 1) -> Double {
        let offset = pow(10, Double(value))
        return (self * offset).rounded() / offset
    }
    
    static func equal(_ lhs: Double, _ rhs: Double, precise value: Int? = nil) -> Bool {
        guard let value = value else {
            return lhs == rhs
        }
        return lhs.precised(value) == rhs.precised(value)
    }
}

extension DateFormatter {
    convenience init(_ block: @escaping (DateFormatter) -> Void) {
        self.init()
        block(self)
    }
}

enum MetaClinicError: Error {
    case loginRequired
    case patientNotSyncd
    case sessionNotSyncd
}

extension MetaClinicError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .loginRequired:
            return "Login required before performing operation."
        case .patientNotSyncd:
            return "Patient not saved to server."
        case .sessionNotSyncd:
            return "Session not saved to server."
        }
    }
}

//extension BFExecutor {
//    static var background: BFExecutor {
//        return BFExecutor(dispatchQueue: DispatchQueue.global(qos: .background))
//    }
//}

extension Executor {
    static var background: Executor {
        return Executor.queue(DispatchQueue.global(qos: .background))
    }
}

extension NotificationToken {
    static var allPatients: NotificationToken? = nil
}
