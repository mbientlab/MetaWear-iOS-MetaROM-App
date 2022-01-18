//
//  MacroLogger.swift
//  
//
//  Created by Stephen Schiffli on 7/21/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import MetaWear


protocol MacroPrinter {
    func finish(comment: String, isBoot: Bool)
    func dumpFile(comment: String)
}

class CPrinter: MacroPrinter {
    func finish(comment: String, isBoot: Bool) {
        let msg = "// Macro:\(Macro.all.count) lines:\(Macro.cur.lineCount) bytes:\(Macro.cur.byteCount) bootup:\(isBoot ? "yes" : "no") - \(comment)"
        Macro.cur.allCommands = msg + Macro.cur.allCommands
        Macro.cur.isBoot = isBoot
        Macro.all.append(Macro.cur)
        Macro.reset()
    }
    
    func dumpFile(comment: String) {
        var offset = 0
        let file = """
        const mw_macro_command_t static_macro_commands[] = {
        \(Macro.all.reduce("") { $0 + "\n" + $1.allCommands })
        0xFF, 0xFF, 0xFF, 0xFF,
        };
        const mw_macro_macro_t static_macro_macros[] = {
        \(Macro.all.reduce("") {
        let result = $0 + "  {0, \($1.lineCount), \($1.isBoot ? "1" : "0"), \(offset)},\n"
        offset += $1.byteCount
        return result
        })
        };
        """
        print(file)
    }
}

class SwiftPrinter: MacroPrinter {
    func finish(comment: String, isBoot: Bool) {
        let msg = "// \(comment)\n[\n"
        Macro.cur.allCommands = msg + Macro.cur.allCommands
        Macro.cur.allCommands.append("],\n")
        Macro.cur.isBoot = isBoot
        Macro.all.append(Macro.cur)
        Macro.reset()
    }
    
    func dumpFile(comment: String) {
        let file = """
        let commands\(comment): [[[UInt8]]] = [
        \(Macro.all.reduce("") { $0 + $1.allCommands })
        ]
        """
        print(file)
    }
}

struct Macro {
    var allCommands = ""
    var lineCount = 0
    var byteCount = 0
    var isBoot = false
    
    static var printer: MacroPrinter = CPrinter()
    static var cur = Macro()
    static var all: [Macro] = []
    
    static func reset() {
        cur = Macro()
    }
    static func finish(comment: String, isBoot: Bool) {
        printer.finish(comment: comment, isBoot: isBoot)
    }
    static func dumpFile(comment: String) {
        printer.dumpFile(comment: comment)
    }
}

public struct SwiftMacroLogger: LogDelegate {
    public static let shared: SwiftMacroLogger = {
        Macro.printer = SwiftPrinter()
        return SwiftMacroLogger()
    }()
    
    public func logWith(_ level: LogLevel, message: String) {
        ConsoleLogger.shared.logWith(level, message: message)
        let words = message.split(separator: " ")
        if words[0] == "Writing" {
            let value = String(words.last!).hexadecimal()!
            Macro.cur.allCommands.append("[")
            value.forEach { Macro.cur.allCommands.append(String(format: "0x%02X, ", $0)) }
            Macro.cur.allCommands.removeLast(2)
            Macro.cur.allCommands.append("],\n")
        }
    }
}

public struct CMacroLogger: LogDelegate {
    public static let shared: CMacroLogger = {
        Macro.printer = CPrinter()
        return CMacroLogger()
    }()
    
    public func logWith(_ level: LogLevel, message: String) {
        ConsoleLogger.shared.logWith(level, message: message)
        let words = message.split(separator: " ")
        if words[0] == "Writing" {
            let value = String(words.last!).hexadecimal()!
            Macro.cur.allCommands.append("\n\(value.count)")
            value.forEach { Macro.cur.allCommands.append(String(format: ", 0x%02X", $0)) }
            var i = 1 + value.count
            while (i % 4) != 0 {
                Macro.cur.allCommands.append(", 0xFF")
                i += 1
            }
            Macro.cur.allCommands.append(",")
            Macro.cur.byteCount += i
            Macro.cur.lineCount += 1
        }
    }
}

extension String {
    func hexadecimal() -> Data? {
        var data = Data(capacity: count / 2)
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        guard data.count > 0 else { return nil }
        return data
    }
}

