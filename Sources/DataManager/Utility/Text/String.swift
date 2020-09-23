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
    public init(丸数字 num: Int) {
        guard num >= 0 && num <= 50 else {
            let str = "(\(num))"
            self.init(str)
            return
        }
        let code: Int
        if num == 0 {
            code = 0x24EA
        } else if num <= 20 {
            code = 0x2460 + num - 1
        } else if num <= 35 {
            code = 0x3251 + num - 21
        } else {
            code = 0x32B1 + num - 36
        }
        let ch = Character(UnicodeScalar(code)!)
        self.init(ch)
    }
    
    var tabStripped: [Substring] {
        return self.split(separator: "\t", omittingEmptySubsequences: false).map(\.controlStripped)
    }
    
    var commaStripped: [Substring] {
        return self.split(separator: ",", omittingEmptySubsequences: false).map(\.controlStripped)
    }
}

extension StringProtocol {
    public var 比較用文字列: String {
        var result = self.replacingOccurrences(of: "㈲", with: "（有）")
        result = result.replacingOccurrences(of: "㈱", with: "（株）")
        return result.toJapaneseNormal.spaceStripped
    }

    /// 記号英数半角、仮名全角に揃える（横棒は直前の文字が全角なら全角、半角なら半角になる）
    public var toJapaneseNormal: String {
        var result = ""
        var halfMode = true
        for ch in self {
            if !halfMode && (ch == "ー" || ch == "-" || ch == "ｰ") {
                result.append("ー")
            } else if ch.isASCII {
                result.append(ch)
                halfMode = true
            } else if let half = String(ch).applyingTransform(.fullwidthToHalfwidth, reverse: false)?.first, half.isASCII {
                result.append(half)
                halfMode = true
            } else {
                if let full = String(ch).applyingTransform(.fullwidthToHalfwidth, reverse: true) {
                    result.append(full)
                } else {
                    result.append(ch)
                }
                halfMode = false
            }
        }
        return result
    }
    
    public var remove㈱㈲: String {
        var result = String(self)
        if let ch = result.first, ch == "㈱" || ch == "㈲" {
            result.removeFirst(1)
            while let ch = result.first, ch.isWhitespace || ch == "　" {
                result.removeFirst(1)
            }
            return result
        }
        if let ch = result.last, ch == "㈱" || ch == "㈲" {
            result.removeLast(1)
            while let ch = result.last, ch.isWhitespace || ch == "　" {
                result.removeLast(1)
            }
            return result
        }
        return result
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

public extension StringProtocol {
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

public extension String {
    func containsOne(of strings: String...) -> Bool {
        for str in strings {
            if self.contains(str) { return true }
        }
        return false
    }
    
    init?(any data: Any?) {
        if let str = data as? String {
            self = str
        } else if let astr = data as? NSAttributedString {
            self = astr.string
        } else if let num = data as? CustomStringConvertible {
            self = num.description
        } else {
            return nil
        }
    }
}

private let numberRange = (Character("0")...Character("9"))

extension StringProtocol {
    /// 整数を取り出す
    func makeNumbers() -> [Int] {
        var numbers: [Int] = []
        var scanner = DMScanner(self, normalizedFullHalf: true)
        scanner.skip数字以外()
        while !scanner.isAtEnd {
            if let number = scanner.scanInteger() {
                numbers.append(number)
            }
            scanner.skip数字以外()
        }
        return numbers
//        return self.split { numberRange.contains($0) == false }.compactMap { Int($0) }
    }
    
    public func 全文字半角変換() -> String {
        self.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? String(self)
    }
    
    @inlinable public func 全角半角日本語規格化() -> String {
        self.toJapaneseNormal
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

func make2digS(_ value: Int) -> String {
    let str = String(value)
    switch str.count {
    case 0:
        return "  "
    case 1:
        return " " + str
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
    var scanner = DMScanner(line, normalizedFullHalf: true, upperCased: true)
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
    var scanner = DMScanner(line, normalizedFullHalf: true, upperCased: true)
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
    var scanner = DMScanner(line, normalizedFullHalf: true, upperCased: true, skipSpaces: true)
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

//　NCEngineから移行
extension String {
    /// 文字列をパスに見立てたときの末尾のファイル名（絶対パスで区切り文字は"/"）
    public var lastPathComponent: String {
        guard let index = self.lastIndex(of: "/") else { return self }
        let nextIndex = self.index(after: index)
        return String(self[nextIndex...])
    }
    /// 文字列をファイル名またはファイルへのパスと見立てたときのファイルの拡張子
    public var lowercasedExtension: String {
        for index in self.indices.reversed() {
            if self[index] == "." {
                if index == self.startIndex { return "" }
                let start = self.index(after: index)
                return self[start...].lowercased()
            }
        }
        return ""
    }
    /// 文字列をファイル名と見立てたときのファイル名本体と拡張子
    public var filenameComponents: (body: String, extension: String) {
        for index in self.indices.reversed() {
            if self[index] == "." {
                let start = self.index(after: index)
                return (String(self[..<index]), String(self[start...]))
            }
        }
        return (self, "")
    }
    
    /// 半角スペース・全角スペース・タブを除去する
    public var spaceStripped: String {
        return self.filter { $0 != " " && $0 != "　" && $0 != "\t" }
    }
    /// どれか一つを先頭に持つ
    public func hasPrefix(oneOf: String...) -> Bool {
        return oneOf.contains { self.hasPrefix($0) }
    }
    /// どれか一つを末尾に持つ
    public func contains(oneOf: String...) -> Bool {
        return oneOf.contains { self.contains($0) }
    }
    /// どれか一つを末尾に持つ
    public func hasSuffix(oneOf: [String]) -> Bool {
        return oneOf.contains { self.hasSuffix($0) }
    }

    // MARK: - QMetalItaファイル用
    /// 「 / 」区切りのMacのパスを「 \ 」区切りのWindowsのパスに変換する（形式のみで実用は考慮していない）
    public func windowsPath() -> String { self.replacingOccurrences(of: "/", with: "\\") }
    
    /// 「 \ 」区切りのWindowsのパスを「 / 」区切りのMacのパスに変換する（形式のみで実用は考慮していない）
    public func macPath() -> String { self.replacingOccurrences(of: "\\", with: "/") }

    public func encodeLF() -> String {
        return self.replacingOccurrences(of: "\n", with: "[cr]")
    }
    
    public func decodeLF() -> String {
        return self.replacingOccurrences(of: "[cr]", with: "\n")
    }
}

extension Array where Element == String {
    public func contains(_ lines: [String]) -> Bool {
        guard let firstLine = lines.first else { return false }
        var index = self.startIndex
        while index < self.endIndex {
            if self[index] == firstLine {
                let endIndex = self.index(index, offsetBy: lines.count)
                if self.endIndex < endIndex { return false }
                if Array<String>(self[index..<endIndex]) == lines { return true }
            }
            index = self.index(after: index)
        }
        return false
    }
}
