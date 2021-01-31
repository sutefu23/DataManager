//
//  DMScanner.swift
//  DataManager
//
//  Created by manager on 2020/02/25.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

/// 文字列を解析する
public struct DMScanner: RandomAccessCollection {
    /// スキャン対象(調整済み)
    private let source: String
    /// スキャン時にスペースを除外するならtrue
    public var skipSpaces: Bool {
        didSet { needsSpaceCheck = skipSpaces }
    }

    /// 先頭が空白チェック必要の場合true
    private var needsSpaceCheck: Bool = true
    /// 現在のスキャン位置
    public var startIndex: String.Index {
        didSet { needsSpaceCheck = skipSpaces }
    }
    /// 終端のスキャン位置(+1)
    public private(set) var endIndex: String.Index

    /// 終端にあればtrue
    public var isAtEnd: Bool { return startIndex >= endIndex  }
    /// 終端にあればtrue
    public var isEmpty: Bool { return startIndex >= endIndex }
    
    /// 指定位置の文字
    public subscript(index: String.Index) -> Character { return source[index] }
    /// 指定範囲の文字列
    public subscript(range: Range<String.Index>) -> String { return String(source[range]) }
    /// 指定インデックスの前のインデックス
    public func index(before i: String.Index) -> String.Index { return source.index(before: i) }
    /// 指定インデックスの後のインデックス
    public func index(after i: String.Index) -> String.Index { return source.index(after: i) }

    /// スキャン待ちの現在の文字(調整済み)
    public var string: String {
        mutating get { String(substring) }
    }
    /// スキャン待ちの現在の文字(調整済み)
    var substring: Substring {
        mutating get {
        if needsSpaceCheck { dropHeadSpaces() }
        return source[startIndex..<endIndex]
        }
    }

    /// 読み込みの終わった場所
    func leftString(from: String.Index) -> String {
        return String(source[from..<startIndex])
    }
    
    /// カーソルを最初に戻す
    public mutating func reset() {
        self.startIndex = source.startIndex
    }
    
    /// 文字列スキャナの初期化
    /// - Parameters:
    ///   - string: 分析対象の文字列
    ///   - normalizedFullHalf: 英数は半角に、日本語なは全角に寄せる
    ///   - upperCased: 全て大文字にする
    ///   - skipSpaces: 自動的に空欄を読み飛ばす
    ///   - newlineToSpace: 改行コードをスペースに置き換える
    public init<S: StringProtocol>(_ string: S, normalizedFullHalf: Bool = false, upperCased:Bool = false, skipSpaces: Bool = false, newlineToSpace: Bool = false) {
        self.skipSpaces = skipSpaces
        self.needsSpaceCheck = skipSpaces
        var str: String
        if normalizedFullHalf {
            str = string.toJapaneseNormal
            if upperCased { str = str.uppercased() }
            if newlineToSpace { str = str.newlineToSpace }
        } else {
            if upperCased {
                str = string.uppercased()
                if newlineToSpace { str = str.newlineToSpace }
            } else {
                str = newlineToSpace ? string.newlineToSpace : String(string)
            }
        }
        self.source = str
        self.startIndex = source.startIndex
        self.endIndex = source.endIndex
    }

    /// 末尾に指定文字列を含むとtrue
    public mutating func hasSuffix(_ suffix: String, upperCased: Bool = false) -> Bool {
        if upperCased {
            return substring.uppercased().hasSuffix(suffix)
        } else {
            return substring.hasSuffix(suffix)
        }
    }

    /// 末尾に指定文字列のどれかを含むとtrue
    public mutating func hasSuffix(_ suffix: [String], upperCased: Bool = false) -> Bool {
        if upperCased {
            let target = substring.uppercased()
            return suffix.contains { target.hasSuffix($0) }
        } else {
            let target = substring
            return suffix.contains { target.hasSuffix($0) }
        }
    }

    /// 先頭に指定文字列を含むとtrue
    public mutating func hasPrefix(_ prefix: String, upperCased: Bool = false) -> Bool {
        if upperCased {
            return substring.uppercased().hasPrefix(prefix)
        } else {
            return substring.hasPrefix(prefix)
        }
    }

    /// カーソルを1文字進める
    public mutating func skip1Character() {
        startIndex = source.index(after: startIndex)
    }
    
    /// 指定文字数末尾を削る
    public mutating func dropLast(_ count: Int) {
        if count <= 0 { return }
        let diff = source.distance(from: startIndex, to: endIndex)
        if diff > count {
            endIndex = source.index(endIndex, offsetBy: -count)
        } else {
            endIndex = startIndex
        }
    }

    /// 指定文字数先頭を削る
    public mutating func dropFirst(_ count: Int) {
        if count <= 0 { return }
        let diff = source.distance(from: startIndex, to: endIndex)
        if diff > count {
            startIndex = source.index(startIndex, offsetBy: count)
        } else {
            startIndex = endIndex
        }
    }
    
    /// 必要ならく空白文字をスキップする
    private mutating func dropHeadSpacesIfNeeds() {
        if needsSpaceCheck { dropHeadSpaces() }
    }

    /// skipSpacesにかかかわらず先頭の空白を削る
    public mutating func dropHeadSpaces() {
        var index = startIndex
        while index < endIndex && source[index].isWhitespace { index = source.index(after: index) }
        startIndex = index
        needsSpaceCheck = false
    }

    /// 末尾の空白を削る
    public mutating func dropTailSpaces() {
        if startIndex == endIndex { return }
        var lastIndex = source.index(before: endIndex)
        while startIndex <= lastIndex, source[lastIndex].isWhitespace {
            lastIndex = source.index(before: lastIndex)
        }
        endIndex = source.index(after: lastIndex)
    }

    /// 先頭が指定文字ならtrue。indexは次に移動する
    @discardableResult public mutating func scanCharacter(_ character: Character) -> Bool {
        if testCharacter(character) {
            startIndex = source.index(after: startIndex)
            return true
        } else {
            return false
        }
    }
    
    @discardableResult public mutating func scanCharacters(_ characters: Character...) -> Bool {
        if characters.contains(where: { testCharacter($0) }) {
            startIndex = source.index(after: startIndex)
            return true
        } else {
            return false
        }
    }

    /// 先頭が指定文字ならtrue。indexは次に移動しない
    @discardableResult public mutating func testCharacter(_ character: Character) -> Bool {
        if needsSpaceCheck {
            var index = startIndex
            while true {
                guard index < endIndex else {
                    startIndex = index
                    self.needsSpaceCheck = false
                    return false
                }
                let ch = source[index]
                if ch.isWhitespace {
                    index = source.index(after: index)
                    startIndex = index
                    continue
                } else {
                    self.needsSpaceCheck = false
                    return ch == character
                }
            }
        } else {
            if isAtEnd { return false }
            let first = source[startIndex]
            return first == character
        }
    }

    /// 先頭が文字か調べる
    @discardableResult public mutating func isFirstLetter() -> Bool {
        dropHeadSpacesIfNeeds()
        if isAtEnd { return false }
        let first = source[startIndex]
        return first.isLetter
    }
    
    public mutating func skip数字以外() {
        dropHeadSpacesIfNeeds()
        var index = startIndex
        while index < endIndex {
            let ch = source[index]
            if ch.isASCIINumber {
                self.startIndex = index
                return
            }
            index = source.index(after: index)
        }
        self.startIndex = index
    }
    
    /// 先頭文字が存在しないか数字以外ならtrue
    public mutating func first数字以外() -> Bool {
        dropHeadSpacesIfNeeds()
        if self.isAtEnd { return true }
        let ch = source[startIndex]
        return !ch.isASCIINumber
    }
    
    /// 指定文字まで走査して途中の文字を返す
    public mutating func scanUpTo(_ character: Character) -> String? {
        var index = startIndex
        var result: String = ""
        while index < endIndex {
            let ch = source[index]
            if needsSpaceCheck {
                if ch.isWhitespace {
                    index = source.index(after: index)
                    continue
                }
                self.startIndex = index
                self.needsSpaceCheck = false
            }
            index = source.index(after: index)
            if ch == character {
                startIndex = index
                return result
            }
            result.append(ch)
        }
        return nil
    }

    /// 指定文字のどれかまで走査して途中の文字を返す
    public mutating func scanUpTo(_ characters: Character...) -> String? {
        dropHeadSpacesIfNeeds()
        var index = startIndex
        var result: String = ""
        while index < endIndex {
            let ch = source[index]
            index = source.index(after: index)
            if characters.contains(ch) {
                startIndex = index
                return result
            }
            result.append(ch)
        }
        return nil
    }
    
    public mutating func scanUpToSpace() -> String? {
        dropHeadSpacesIfNeeds()
        var index = startIndex
        var result: String = ""
        while index < endIndex {
            let ch = source[index]
            let resultIndex = index
            index = source.index(after: index)
            if ch.isWhitespace {
                self.startIndex = resultIndex
                return result
            }
            result.append(ch)
        }
        return nil
    }

    /// stringまでスキャンする。ポインタはstringの次に移動する。stringまでの文字列を返す
    public mutating func scanUpToString(_ string: String) -> String? {
        let count = string.count
        if count == 0 { return nil }
        dropHeadSpacesIfNeeds()
        var left = ""
        var startIndex = self.startIndex
        let limitIndex = source.index(source.endIndex, offsetBy: -count)
        while startIndex <= limitIndex {
            let endIndex = source.index(startIndex, offsetBy: count)
            if source[startIndex..<endIndex] == string {
                self.startIndex = endIndex
                return left
            }
            left.append(source[startIndex])
            startIndex = source.index(after: startIndex)
        }
        return nil
    }
    
    /// 整数値を取り出す
    public mutating func scanInteger() -> Int? {
        return Int(self.scanIntegerString())
    }

    public mutating func scanIntegerString() -> String {
        var hasSign: Bool = false
        var hasNumber: Bool = false
        var numberString = "" // 最後にまとめてsubstringを作るよりappendを繰り返す方が高速
        var index = startIndex
        while index < endIndex {
            let ch = source[index]
            guard let ascii = ch.asciiValue else { break }
            if needsSpaceCheck {
                if isASCIISpaceValue(ascii) {
                    index = source.index(after: index)
                    continue
                }
                self.startIndex = index
                self.needsSpaceCheck = false
            }
            if isASCIINumberValue(ascii) {
                numberString.append(ch)
                hasNumber = true
            } else if isASCIISignValue(ascii) {
                if hasSign || hasNumber { break }
                numberString.append(ch)
                hasSign = true
            } else {
                break
            }
            index = source.index(after: index)
        }
        if !hasNumber {
            return ""
        }
        startIndex = index
        return numberString
    }
    

    public mutating func searchInteger(suffix: String) -> Int? {
        defer { self.reset() }
        while !isAtEnd {
            guard let number = self.scanInteger() else {
                skip1Character()
                continue
            }
            if scanString(suffix) { return number}
            skip1Character()
        }
        return nil
    }

    /// 実数文字列を取り出す
    private mutating func scanDecimalString() -> String? {
        var hasSign: Bool = false
        var hasNumber: Bool = false
        var hasDot: Bool = false
        var hasE: Bool = false
        var numberString = "" // 最後にまとめてsubstringを作るよりappendを繰り返す方が高速
        var index = startIndex
        while index < endIndex {
            let ch = source[index]
            guard let ascii = ch.asciiValue else { break }
            if needsSpaceCheck {
                if isASCIISpaceValue(ascii) {
                    index = source.index(after: index)
                    continue
                }
                self.startIndex = index
                self.needsSpaceCheck = false
            }
            if isASCIINumberValue(ascii) {
                numberString.append(ch)
                hasNumber = true
            } else if isASCIISignValue(ascii) {
                if hasSign || hasNumber { break }
                numberString.append(ch)
                hasSign = true
            } else if isASCIIDotValue(ascii) {
                if hasDot || hasE { break }
                numberString.append(ch)
                hasDot = true
            } else if isASCIIExpValue(ascii) {
                if hasE || !hasNumber { break }
                numberString.append(ch)
                hasE = true
                hasSign = false
                hasNumber = false
            } else {
                break
            }
            index = source.index(after: index)
        }
        if !hasNumber { return nil }
        startIndex = index
        return numberString
    }

    /// 実数の取り出し
    public mutating func scanDouble() -> Double? {
        guard let str = self.scanDecimalString() else { return nil }
        return Double(str)
    }
    
    public mutating func scanStringAndDouble() -> (string: String, value: Double)? {
        let initialIndex = self.startIndex
        var index = self.startIndex
        while index < self.endIndex {
            self.startIndex = index
            if let value = self.scanDouble() {
                if self.isAtEnd { return (String(source[initialIndex..<index]), value) }
            }
            index = source.index(after: index)
        }
        self.startIndex = initialIndex
        return nil
    }
    
    public mutating func scanStringAsDouble() -> (string: String, value: Double)? {
        let initialIndex = self.startIndex
        skip数字以外()
        let valueHead = self.startIndex
        guard let value = self.scanDouble() else {
            self.startIndex = initialIndex
            return nil
        }
        let string = String(source[valueHead..<self.startIndex])
        return (string, value)
    }

    public mutating func scanDoubleAndDouble() -> (left: Double, splitter: String, right: Double)? {
        let initialIndex = self.startIndex
        guard let left = scanDouble(), let (splitter, right) = scanStringAndDouble() else {
            self.startIndex = initialIndex
            return nil
        }
        return (left, splitter, right)
    }

    /// 左括弧と右カッコを指定し、その左側と中の文字を取り出す
    public mutating func scanParen(_ left: Character, _ right: Character, stopSpaces: Bool = false) -> (left: String, contents: String)? {
        dropHeadSpacesIfNeeds()
        var index = startIndex
        var noLeft = true
        var leftCount = 0
        var rightCount = 0
        var leftContents = ""
        var contents = ""
        while index < endIndex {
            let ch = source[index]
            index = source.index(after: index)
            if noLeft && ch != left {
                if stopSpaces && ch.isWhitespace { return nil }
                if ch == right { return nil }
                leftContents.append(ch)
                continue
            }
            if ch == left {
                noLeft = false
                if leftCount > 0 { contents.append(ch) }
                leftCount += 1
            } else if ch == right {
                rightCount += 1
                if rightCount >= leftCount { break }
                contents.append(ch)
            } else if leftCount > 0 {
                contents.append(ch)
            }
        }
        if leftCount == 0 || rightCount == 0 || leftCount != rightCount {
            return nil
        }
        if skipSpaces && leftContents.last?.isWhitespace == true {
            var scanner = DMScanner(leftContents, normalizedFullHalf: false)
            scanner.dropTailSpaces()
            leftContents = String(scanner.substring)
        }
        startIndex = index
        return (leftContents, contents)
    }

    /// 左括弧と右カッコを指定し、その左側と中の文字を取り出す
    public mutating func scanParens(_ left: [Character], _ right: [Character], stopSpaces: Bool = false) -> (left: String, contents: String)? {
        dropHeadSpacesIfNeeds()
        var index = startIndex
        var noLeft = true
        var leftCount = 0
        var rightCount = 0
        var leftContents = ""
        var contents = ""
        while index < endIndex {
            let ch = source[index]
            index = source.index(after: index)
            if noLeft && !left.contains(ch) {
                if stopSpaces && ch.isWhitespace { return nil }
                if right.contains(ch) { return nil }
                leftContents.append(ch)
                continue
            }
            if left.contains(ch) {
                noLeft = false
                if leftCount > 0 { contents.append(ch) }
                leftCount += 1
            } else if right.contains(ch) {
                rightCount += 1
                if rightCount >= leftCount { break }
                contents.append(ch)
            } else if leftCount > 0 {
                contents.append(ch)
            }
        }
        if leftCount == 0 || rightCount == 0 || leftCount != rightCount {
            return nil
        }
        if skipSpaces && leftContents.last?.isWhitespace == true {
            var scanner = DMScanner(leftContents, normalizedFullHalf: false)
            scanner.dropTailSpaces()
            leftContents = String(scanner.substring)
        }
        startIndex = index
        return (leftContents, contents)
    }
    
    /// 指定文字分スキップする
    @discardableResult public mutating func scanString(_ pattern: String) -> Bool {
        let count = pattern.count
        if count == 0 { return false }
        dropHeadSpacesIfNeeds()
        let match = self.substring
        if match.count < count { return false }
        if match.count == count {
            if match == pattern {
                startIndex = self.source.index(startIndex, offsetBy: count)
                return true
            } else {
                return false
            }
        }
        let first = match.startIndex
        let end = match.index(first, offsetBy: count)
        if match[first..<end] == pattern {
            startIndex = self.source.index(startIndex, offsetBy: count)
            return true
        } else {
            return false
        }
    }

    /// patternsのどれか合致する物をスキップする
    @discardableResult public mutating func scanStrings(_ patterns: String...) -> String? {
        let patterns = patterns.sorted { $0.count > $1.count } // 長いものから順に実施する
        for pattern in patterns {
            if self.scanString(pattern) { return pattern }
        }
        return nil
    }

    @discardableResult public mutating func scanStrings(_ patterns: [String]) -> String? {
        let patterns = patterns.sorted { $0.count > $1.count } // 長いものから順に実施する
        for pattern in patterns {
            if self.scanString(pattern) { return pattern }
        }
        return nil
    }

    /// マッチする分スキップする
    public mutating func skipMatchString(_ pattern: String) {
        dropHeadSpacesIfNeeds()
        for ch in pattern {
            if !self.scanCharacter(ch) { return }
        }
        return
    }

    /// スキャン完了状態にする
    public mutating func removeAll() {
        endIndex = startIndex // startIndexを動かすと余計な計算が入るのでendIndexを動かす
    }
    
    /// 残りを全て取り出す（uppercased済み）
    public mutating func scanAll() -> String {
        let result = self.string
        removeAll()
        return result
    }
    
    // MARK: - NCEngineより
    /// 1文字取り出す
    public mutating func scan1Character() -> Character? { fetchCharacter() }
    public mutating func fetchCharacter() -> Character? {
        if needsSpaceCheck {
            var index = startIndex
            while index < endIndex {
                let ch = source[index]
                index = source.index(after: index)
                if !ch.isWhitespace {
                    startIndex = index
                    return ch
                }
            }
            startIndex = index
            return nil
        } else {
            if isAtEnd { return nil }
            let ch = source[startIndex]
            startIndex = source.index(after: startIndex)
            return ch
        }
    }
    
    /// Gコード用10進数の取り出し。小数点がない場合defaultPrecisionが小数点位置となる
    public mutating func scanNCDecimal(defaultPrecision: Int? = nil) -> Decimal? {
        guard let str = self.scanDecimalString() else { return nil }
        guard var decimal = Decimal(string: str) else { return nil }
        if let count = defaultPrecision, count > 0, str.contains(".") == false {
            for _ in 1...count { decimal /= 10 }
        }
        return decimal
    }

    public mutating func scanDoubles(count: Int, separator: Character) -> [Double]? {
        if count == 0 { return [] }
        let initialIndex = self.startIndex
        var result: [Double] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            scanCharacter(separator)
            guard let value = self.scanDouble() else {
                self.startIndex = initialIndex
                return nil
            }
            result.append(value)
        }
        return result
    }
    
    public mutating func scanIntegers(count: Int, separator: Character) -> [Int]? {
        if count == 0 { return [] }
        let initialIndex = self.startIndex
        var result: [Int] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            scanCharacter(separator)
            guard let value = self.scanInteger() else {
                self.startIndex = initialIndex
                return nil
            }
            result.append(value)
        }
        return result
    }
    
    /// 指定文字にマッチするところまで進めてpatternより左にあるものを返す。マッチする文字列が無い場合進めずにnilを返す
    public mutating func searchString(_ pattern: String) -> String? {
        if scanString(pattern) { return "" }
        var left: String = ""
        let initailIndex = startIndex
        while let ch = fetchCharacter() {
            left.append(ch)
            if scanString(pattern) { return left }
        }
        self.startIndex = initailIndex
        return nil
    }
    
    /// 微妙な文字（ローマ数字など）を使っている場合true
    public var containsNGCharacters: Bool {
        source[startIndex..<endIndex].containsNGCharacters
    }
    
    /// hh:mmまたはhh:mm:ssを読みとる。
    public mutating func scanTime() -> Time? {
        dropHeadSpacesIfNeeds()
        let initialIndex = self.startIndex
        var index = initialIndex
        var hoursStr = ""
        var hasCol = false
        var hasCol2 = false
        var minutesStr = ""
        var secondsStr = ""
        while index < self.endIndex {
            let ch = source[index]
            if ch.isASCIINumber {
                if hasCol == false {
                    hoursStr.append(ch)
                } else if hasCol2 == false {
                    minutesStr.append(ch)
                } else {
                    secondsStr.append(ch)
                }
            } else if ch == ":" {
                if hasCol == false {
                    hasCol = true
                } else if hasCol2 == false {
                    hasCol2 = true
                } else {
                    self.startIndex = initialIndex
                    return nil
                }
            } else {
                break
            }
            index = source.index(after: index)
        }
        if minutesStr.count == 2, let hours = Int(hoursStr),
           (hoursStr.count == 2 || hoursStr.count == 1 && hours < 10) && hours < 24,
           let minutes = Int(minutesStr), minutes < 60 {
            assert(hours >= 0 && minutes >= 0) // マイナス記号がないため
            if hasCol2 {
                if secondsStr.count == 2, let seconds = Int(secondsStr), seconds < 60 {
                    assert(seconds >= 0) // マイナス記号がないため
                    self.startIndex = index
                    return Time(hours, minutes, seconds)
                }
            } else {
                self.startIndex = index
                return Time(hours, minutes)
            }
        }
        self.startIndex = initialIndex
        return nil
    }
    
    /// 時間のところまで読み込み、それまでの文字列と時間を返す
    public mutating func scanUpToTime() -> (left: String, time: Time)? {
        var left: String = ""
        let initialIndex = self.startIndex
        var index = initialIndex
        while index < self.endIndex {
            let ch = source[index]
            if ch.isASCIINumber {
                self.startIndex = index
                if let time = self.scanTime() {
                    return (left, time)
                }
            }
            if !(self.skipSpaces && ch.isWhitespace) {
                left.append(ch)
            }
            index = source.index(after: index)
        }
        self.startIndex = initialIndex
        return nil
    }
    
    // MARK: - 逆方向スキャン
    /// 必要なら逆方向にスペースをスキップする
    private mutating func reverseDropHeadSpacesIfNeeds() {
        if skipSpaces { reverseDropHeadSpaces() }
    }
    /// 一つ前がスペースでないようにカーソルを前に移動する
    public mutating func reverseDropHeadSpaces() {
        var index = startIndex
        while index != source.startIndex {
            index = source.index(before: startIndex)
            if !source[index].isWhitespace { return }
            startIndex = index
        }
        needsSpaceCheck = skipSpaces
    }

    /// 前方キャラが指定された文字ならカーソルを前に戻してtrueを返す
    public mutating func reverseScanCharacter(_ character: Character) -> Bool {
        reverseDropHeadSpacesIfNeeds()
        guard startIndex != source.startIndex else { return false }
        let index = source.index(before: startIndex)
        if source[index] == character {
            startIndex = index
            return true
        } else {
            return false
        }
    }

    public mutating func reverseScanInteger() -> Int? {
        return Int(reverseScanIntegerString())
    }
    
    public mutating func reverseScanIntegerString() -> String {
        reverseDropHeadSpacesIfNeeds()
        var numberString = ""
        var index = startIndex
        while index != source.startIndex {
            self.startIndex = index
            index = source.index(before: index)
            let ch = source[index]
            if ch.isASCIINumber {
                numberString.insert(ch, at: numberString.startIndex)
                continue
            } else if !numberString.isEmpty {
                if ch == "+" || ch == "-" {
                    numberString.insert(ch, at: numberString.startIndex)
                    startIndex = index
                    return numberString
                }
            }
            break
        }
        return numberString
    }
    
    public mutating func reverseScanDay() -> Day? {
        reverseDropHeadSpacesIfNeeds()
        let currentIndex = self.startIndex
        guard let day = self.reverseScanInteger(), day >= 1 && day <= 31,
              self.reverseScanCharacter("/") == true,
              let month = self.reverseScanInteger(), month >= 1 && month <= 12 else {
            self.startIndex = currentIndex
            return nil
        }
        return Day(month, day)
    }
}

let ngCharacters: Set<Character> = [
    "\u{2160}", "\u{2164}", "\u{2169}", "\u{216C}", "\u{216D}", "\u{216E}", "\u{216F}" // ローマ数字
]

public extension StringProtocol {
    var containsNGCharacters: Bool {
        self.contains { ngCharacters.contains($0) }
    }
}

/// '0'~'9'
func isASCIINumberValue(_ ascii: UInt8) -> Bool { ascii >= 48 && ascii <= 57 }
/// SPACE or TAB
func isASCIISpaceValue(_ ascii: UInt8) -> Bool { ascii == 32 || ascii == 9 }
/// '+' or '-'
func isASCIISignValue(_ ascii: UInt8) -> Bool { ascii == 43 || ascii == 45 }
/// '.'
func isASCIIDotValue(_ ascii: UInt8) -> Bool { ascii == 46 }
/// 'E' or 'e'
func isASCIIExpValue(_ ascii: UInt8) -> Bool { ascii == 69 || ascii == 101 }
/// 'A'~'Z' or 'a'~'z'
func isASCIIAlphabetValue(_ ascii: UInt8) -> Bool { ascii >= 65 && ascii <= 90 || ascii >= 97 && ascii <= 122 }
