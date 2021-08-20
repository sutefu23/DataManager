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
    
    public mutating func removeTailSpace() {
        while self.last?.isWhitespace == true { self.removeLast() }
    }
    
    public var is空欄: Bool {
        return self.spaceStripped.isEmpty
    }
}

extension StringProtocol {
    public var isエラーあり: Bool {
        if self.contains("\0") { return true }
        return false
    }
    
    ///　末尾に数字がある場合、それを取り出す
    public var tailNumbers: String? {
        var result: String = ""
        for ch in self.reversed() {
            if ch.isASCIINumber {
                result.insert(ch, at: result.startIndex)
            }
        }
        return !result.isEmpty ? result : nil
    }
    
    public var 比較用文字列: String {
        var result = ""
        for ch in self.toJapaneseNormal.spaceStripped {
            switch ch {
            case "㈲":
                result.append("有限会社")
            case "㈱":
                result.append("株式会社")
            case "・", "･", "．", "。": // 点は全部同じ扱い
                result.append(".")
            case "−": //マイナスを半角ハイフンに
                result.append("-")
            case "~":
                result.append("〜")
            case "\'":
                result.append("")
            default:
                result.append(ch)
            }
        }
        result = result.replacingOccurrences(of: "(株)", with: "株式会社").replacingOccurrences(of: "(有)", with: "有限会社")
        return result
    }

    public var remove㈱㈲: String {
        var result = String(self).toJapaneseNormal
        if let ch = result.first, ch == "㈱" || ch == "㈲" {
            result.removeFirst(1)
            while let ch = result.first, ch.isWhitespace || ch == "　" {
                result.removeFirst(1)
            }
            return result
        } else if result.hasPrefix("(株)") || result.hasPrefix("(有)") {
            result.removeFirst(3)
            return result
        }
        if let ch = result.last, ch == "㈱" || ch == "㈲" {
            result.removeLast(1)
            while let ch = result.last, ch.isWhitespace || ch == "　" {
                result.removeLast(1)
            }
            return result
        } else if result.hasSuffix("(株)") || result.hasSuffix("(有)") {
            result.removeLast(3)
            return result
        }
        return result
    }
    
    func dropFirst(全角2文字 count: Int) -> String {
        var scanner = DMScanner(self, normalizedFullHalf: true, newlineToSpace: true)
        scanner.drop(全角2文字: count)
        return scanner.string
    }
    func prefix(全角2文字 count: Int) -> String {
        var scanner = DMScanner(self, normalizedFullHalf: true, newlineToSpace: true)
        return scanner.drop(全角2文字: count)
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

extension Character {
    public var isASCIINumber: Bool {
        guard let ascii = self.asciiValue else { return false }
        return isASCIINumberValue(ascii)
    }
    
    public var isASCIIAlphabet: Bool {
        guard let ascii = self.asciiValue else { return false }
        return isASCIIAlphabetValue(ascii)
    }
}

public extension StringProtocol {
    var newlineToSpace: String {
        return String(self.map { $0.isNewline ? " " : $0 })
    }
    
    var headNumber: String {
        String(self.prefix { $0.isASCIINumber })
    }
}

extension Double {
    public var 金額テキスト: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let str = formatter.string(from: NSNumber(value: self))
        return str ?? ""
    }

    public var 金額テキスト2: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let str = formatter.string(from: NSNumber(value: self.rounded()))
        return str ?? ""
    }

    public init?(金額テキスト text: String) {
        let text = text.filter { $0 != "," }
        guard let value = try? Double(formula: text) else { return nil }
        self = value
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
        switch data {
        case let str as String:
            self = str
        case let astr as NSAttributedString:
            self = astr.string
        case let num as CustomStringConvertible:
            self = num.description
        default:
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
    }
    
    /// 全角を半角に変換する
    public func 全文字半角変換() -> String {
        return self.toHalfCharacters
    }
    
    @inlinable public func 全角半角日本語規格化() -> String {
        self.toJapaneseNormal
    }
    
    public var shiftJISBytes: Int {
        let data = self.data(using: .shiftJIS, allowLossyConversion: true)
        return data?.count ?? 0
    }
}

func make2dig(_ value: Int) -> String {
    return value >= 0 && value <= 9 ? "0\(value)" : String(value)
}

func make2digS(_ value: Int) -> String {
    return value >= 0 && value <= 9 ? " \(value)" : String(value)
}

func make4dig(_ value: Int) -> String {
    switch value {
    case 1000...:
        return String(value)
    case 0...9:
        return "000\(value)"
    case 10...99:
        return "00\(value)"
    case 100...999:
        return "0\(value)"
    default:
        return String(value)
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

/// 1から始まる数字をアルファベット順に直します。26を超えるものはaa、ab、、など桁を増やしていきます
/// 0以下は想定していないので空文字を返します
func from数字to26進数(_ num: Int, chars: [Character] = []) -> String{
    if num <= 0 { return ""}

    let newNum = num - 1
    let alphabets = [Character]("abcdefghijklmnopqrstuvwxyz")
    let 商 = newNum / 26
    let 剰余 = newNum % 26
    var newChars = chars
    newChars.append(alphabets[剰余])
    if 商 == 0 {
        return newChars.reversed().map{String($0)}.joined()
    } else {
        return from数字to26進数(商, chars: newChars)
    }
}
/// abなどのアルファベット文字列から数値を出力
/// アルファベットでない場合は0を返す。大文字小文字を区別しない
func from26進数to数字(_ digit: String) -> Int{
    let alphabets = [Character]("abcdefghijklmnopqrstuvwxyz")
    var result = 0
    for i in (0 ..< digit.count).reversed() { // 1の位から処理
        let ch = Array(digit.lowercased().reversed())[i]
        guard let n = alphabets.firstIndex(of: ch) else { return 0 }

        let number = n + 1
        if i == 0 { // １の位
            result += number
        } else {
            result += Int(pow(Double(26) , Double(i))) * number
        }
    }
    return result
}

/// 与えられたIDとSetから最後の26進数コードを取得
/// 例：コード1234の中にa1234、b1234があったら次のb1234を返す
public func last26進数コード(_ code: String, codeSet: Set<String>) -> String?{
    let lastId = codeSet.filter{
        let id = $0.filter26進数除外ID()
        return id == code
    }.sorted{ $0 < $1 }.last
    
    return lastId
}
/// 与えられたIDとSetから次の26進数コードを取得
/// 例：コード1234の中にa1234、b1234があったら次のc1234を返す
public func next26進数コード(_ code: String, codeSet: Set<String>) -> String{
    
    if let lastId = last26進数コード(code, codeSet: codeSet){
        let abc = lastId.filter26進数ID()
        let nextNum = from26進数to数字(abc) + 1
        let nextAbc = from数字to26進数(nextNum)
        return nextAbc + code
    }else {
        return from数字to26進数(1) + code
    }
}

extension String {
    /// idがabcなどの26進数付きかどうかを判別
    func is26進数付きID()-> Bool{
        let pattern = "[a-zA-Z]+[0-9]+"
        return self.contain(pattern)
    }
    /// idから26進数を取得。存在しなければ空文字
    func filter26進数ID()-> String{
        let pattern = "^[a-zA-Z]+"
        let machies = self.matchFilter(pattern)
        if machies.count > 0 {
            return machies[0]
        }else{
            return ""
        }
    }
    /// idから26進数を除外した部分を取得。最後が数字でなければ空文字
    func filter26進数除外ID()-> String{
        let pattern = "[0-9]+$"
        let machies = self.matchFilter(pattern)
        if machies.count > 0 {
            return machies[0]
        }else{
            return ""
        }
    }

}

/// 正規表現パターンマッチ
extension String {
    /// 正規表現を含むか否か
    func contain(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options()) else {
            return false
        }
        return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, self.count)) != nil
    }
    ///マッチした部分の抽出
    func matchFilter(_ pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let matched = regex.firstMatch(in: self, range: NSRange(location: 0, length: self.count))
        else { return [] }
        return (0 ..< matched.numberOfRanges).map {
            NSString(string: self).substring(with: matched.range(at: $0))
        }
    }
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
    /// 先頭の半角スペース・全角スペース・タブを修正する
    public var dropHeadSpaces: String {
        var result = ""
        var isHead = true
        for ch in self {
            if isHead {
                if ch.isWhitespace { continue }
                isHead = false
            }
            result.append(ch)
        }
        return result
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

// MARK: - CSV関連
extension StringProtocol {
    /// CSVでテキストを分割する
    public var csvColumns: [String] {
        return self.splitColumns(delimiter: ",", bracket: ("\"", "\""))
    }
    /// TSVでテキストを分割する
    public var tsvColumns: [String] {
        return self.splitColumns(delimiter: "\t", bracket: nil)
    }
    /// 指定の文字でテキストを分割する
    public func splitColumns(delimiter: Character, bracket: (left: Character, right: Character)?) -> [String] {
        if self.isEmpty { return [""] }
        var columns: [String] = []
        var scanner = DMScanner(self)
        var leftComma: Bool = false
        while !scanner.isEmpty {
            if scanner.scanCharacter(delimiter) {
                columns.append("")
                leftComma = true
                continue
            }
            if let bracket = bracket {
                if scanner.scanCharacter(bracket.left) {
                    if let left = scanner.scanUpTo(bracket.right) {
                        columns.append(left)
                        guard scanner.scanCharacter(delimiter) else {
                            leftComma = false
                            break
                        }
                        leftComma = true
                        continue
                    } else {
                        columns.append(scanner.scanAll())
                        leftComma = false
                        break
                    }
                }
            }
            if let left = scanner.scanUpTo(delimiter) {
                columns.append(left)
                leftComma = true
            } else {
                columns.append(scanner.scanAll())
                leftComma = false
                break
            }
        }
        if leftComma {
            columns.append(scanner.string)
        }
        return columns
    }
    
    /// カラムの先頭が'だった場合削除する
    public var dashStribbped: String {
        if self.hasPrefix("'") {
            return String(self.dropFirst())
        } else {
            return String(self)
        }
    }
}
