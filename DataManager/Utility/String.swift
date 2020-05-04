//
//  String.swift
//  DataManager
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

private let controlSet = CharacterSet.controlCharacters

extension String {
    var tabStripped: [Substring] {
        return self.split(separator: "\t", omittingEmptySubsequences: false).map(\.controlStripped)
    }
    
    var commaStripped: [Substring] {
        return self.split(separator: ",", omittingEmptySubsequences: false).map(\.controlStripped)
    }
}

extension Substring {
    var controlStripped: Substring {
        if let tail = self.last?.unicodeScalars.first {
            if controlSet.contains(tail) {
                return self.dropLast().controlStripped
            }
        }
        return self
    }
}

private var numberSet: CharacterSet = {
    var set = CharacterSet()
    set.insert(charactersIn: "0123456789")
    return set
}()

extension StringProtocol {
    var newlineToSpace: String {
        return String(self.map { $0.isNewline ? " " : $0 })
    }
    
    var headNumber: String {
        var string: String = ""
        for ch in self {
            guard let sc = ch.unicodeScalars.first else { break }
            guard numberSet.contains(sc) else { break }
            string.append(ch)
        }
        return string
    }
}

extension Double {
    public var 金額テキスト: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let str = formatter.string(from: NSNumber(value: self))
        return str ?? ""
    }
}

extension String {
    func containsOne(of strings: String...) -> Bool {
        for str in strings {
            if self.contains(str) { return true }
        }
        return false
    }
}

private let numberRange = (Character("0")...Character("9"))

extension StringProtocol {
    func makeNumbers() -> [Int] {
        return self.split { numberRange.contains($0) == false }.compactMap { Int($0) }
    }
}

func make2dig(_ value: Int) -> String {
    let str = String(value)
    switch str.count {
    case 0:
        return "00"
    case 1:
        return "0" + str
    default:
        return str
    }
}

func make4dig(_ value: Int) -> String {
    let str = String(value)
    switch str.count {
    case 0:
        return "0000"
    case 1:
        return "000" + str
    case 2:
        return "00" + str
    case 3:
        return "0" + str
    default:
        return str
    }
}

func calc箱文字側面高さ(_ line: String) -> [Double] {
    var result = [Double]()
    var scanner = DMScanner(line, toHalf: true, upperCased: true)
    while !scanner.isAtEnd {
        if scanner.scanParen("(", ")") != nil || scanner.scanParen("（", "）") != nil { continue }
        scanner.skip数字以外()
        if let value = scanner.scanDouble() {
            if scanner.scanCharacter("T") || scanner.scanCharacter("t") || scanner.scanCharacter("Ｔ") { continue }
            result.append(value)
        }
    }
    return result
}

func calc箱文字以外側面高さ(_ line: String) -> [Double] {
    var result = [Double]()
    var scanner = DMScanner(line, toHalf: true, upperCased: true)
    while !scanner.isAtEnd {
        scanner.skip数字以外()
        if let value = scanner.scanDouble() {
            if scanner.scanCharacter("T") {
                result.append(value)
            }
        }
    }
    return result
}

func calc寸法サイズ(_ line: String) -> [Double] {
    var result = [Double]()
    var scanner = DMScanner(line, toHalf: true, upperCased: true, skipSpaces: true)
    var header: Character? = nil
    while !scanner.isAtEnd {
        while scanner.first数字以外() {
            guard let ch = scanner.scan1Character() else { return result }
            header = ch
        }
        if let value = scanner.scanDouble() {
            if header == nil || header == "H" || header == "Ｈ" {
                result.append(value)
            }
        }
    }
    return result
}
