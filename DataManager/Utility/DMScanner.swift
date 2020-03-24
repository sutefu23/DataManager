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
    /// スキャン対象(元データ)
//    private let originalSource: String
    /// スキャン開始時にスペースを除外するならtrue
    public var skipSpaces: Bool {
        didSet { needsSpaceCheck = skipSpaces }
    }

    /// 先頭が空白チェック必要の場合true
    private var needsSpaceCheck: Bool = true
    /// 現在のスキャン位置
    public private(set) var startIndex: String.Index {
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
    /// 指定インデックスの前のインデックス
    public func index(before i: String.Index) -> String.Index { return source.index(before: i) }
    /// 指定インデックスの後のインデックス
    public func index(after i: String.Index) -> String.Index { return source.index(after: i) }

    /// スキャン待ちの現在の文字(調整済み)
    public var string: String { return String(substring) }
    /// スキャン待ちの現在の文字(調整済み)
    var substring: Substring { return source[startIndex..<endIndex] }

    /// スキャン待ちの現在の文字(元データ)
//    public var originalString: String { return String(originalSubstring)}
    /// スキャン待ちの現在の文字(元データ)
//    var originalSubstring: Substring { return originalSource[startIndex..<endIndex] }

    public init(_ string: String, upperCased:Bool = false, skipSpaces: Bool = false) {
        self.source = upperCased ? string.uppercased() : string
        self.startIndex = source.startIndex
        self.endIndex = source.endIndex
        self.skipSpaces = skipSpaces
        self.needsSpaceCheck = skipSpaces
    }

    public init<S: StringProtocol>(_ string: S, upperCased:Bool = false, skipSpaces: Bool = false) {
        self.source = upperCased ? string.uppercased() : String(string)
        self.startIndex = source.startIndex
        self.endIndex = source.endIndex
        self.skipSpaces = skipSpaces
        self.needsSpaceCheck = skipSpaces
    }

    /// 末尾に指定文字列を含むとtrue
    public func hasSuffix(_ suffix: String, upperCased: Bool = false) -> Bool {
        if upperCased {
            return substring.uppercased().hasSuffix(suffix)
        } else {
            return substring.hasSuffix(suffix)
        }
    }

    /// 先頭に指定文字列を含むとtrue
    public func hasPrefix(_ prefix: String, upperCased: Bool = false) -> Bool {
        if upperCased {
            return substring.uppercased().hasPrefix(prefix)
        } else {
            return substring.hasPrefix(prefix)
        }
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
    /// 先頭が指定文字ならtrue。indexは次に移動する
    @discardableResult public mutating func testCharacter(_ character: Character) -> Bool {
        dropHeadSpacesIfNeeds()
        if isAtEnd { return false }
        let first = source[startIndex]
        return first == character
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
            if numberCharacters.contains(ch) || changeMap[ch] != nil {
                self.startIndex = index
                return
            }
            index = source.index(after: index)
        }
        self.startIndex = index
    }
    
    public mutating func first数字以外() -> Bool {
        dropHeadSpacesIfNeeds()
        if self.isAtEnd { return true }
        let ch = source[startIndex]
        return !numberCharacters.contains(ch) && changeMap[ch] == nil
    }
    
    public mutating func scan1Character() -> Character? {
        dropHeadSpacesIfNeeds()
        if self.isAtEnd { return nil }
        let ch = source[startIndex]
        startIndex = source.index(after: startIndex)
        return ch
    }
    
    /// 指定文字まで走査して途中の文字を返す
    public mutating func scanUpTo(_ character: Character) -> String? {
        dropHeadSpacesIfNeeds()
        var index = startIndex
        var result: String = ""
        while index < endIndex {
            let ch = source[index]
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
    
    /// 整数値を取り出す
    public mutating func scanInteger() -> Int? {
        dropHeadSpacesIfNeeds()
        var hasSign: Bool = false
        var hasNumber: Bool = false
        var numberString = "" // 最後にまとめてsubstringを作るよりappendを繰り返す方が高速
//        numberString.reserveCapacity(needsCapacity) 遅くなる
        var index = startIndex
        while index < endIndex {
            let ch = source[index]
            if numberCharacters.contains(ch) {
                numberString.append(ch)
                hasNumber = true
            } else if ch == "+" || ch == "-" {
                if hasSign || hasNumber { break }
                numberString.append(ch)
                hasSign = true
            } else if let numCh = changeMap[ch] {
                numberString.append(numCh)
                hasNumber = true
            } else {
                break
            }
            index = source.index(after: index)
        }
        if !hasNumber {
            return nil
        }
        startIndex = index
        return Int(numberString)
    }

    /// 実数文字列を取り出す
    private mutating func scanDecimalString() -> String? {
        dropHeadSpacesIfNeeds()
        var hasSign: Bool = false
        var hasNumber: Bool = false
        var hasDot: Bool = false
        var hasE: Bool = false
        var numberString = "" // 最後にまとめてsubstringを作るよりappendを繰り返す方が高速
//        numberString.reserveCapacity(needsCapacity) // 遅くなる
        var index = startIndex
        while index < endIndex {
            let ch = source[index]
            if numberCharacters.contains(ch) {
                numberString.append(ch)
                hasNumber = true
            } else if ch == "+" || ch == "-" {
                if hasSign || hasNumber { break }
                numberString.append(ch)
                hasSign = true
            } else if ch == "." {
                if hasDot || hasE { break }
                numberString += "."
                hasDot = true
                
            } else if ch == "E" || ch == "e" {
                if hasE || !hasNumber { break }
                numberString.append(ch)
                hasE = true
                hasSign = false
                hasNumber = false
            } else if let numCh = changeMap[ch] {
                numberString.append(numCh)
                hasNumber = true
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
        
    /// 左括弧と右カッコを指定し、その左側と中の文字を取り出す
    public mutating func scanParen(_ left: Character, _ right: Character) -> (left: String, contents: String)? {
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
            var scanner = DMScanner(leftContents)
            scanner.dropTailSpaces()
            leftContents = String(scanner.substring)
        }
        startIndex = index
        return (leftContents, contents)
    }
    
    /// 指定文字分スキップする
    public mutating func scanString(_ pattern: String) -> Bool {
        dropHeadSpacesIfNeeds()
        let count = pattern.count
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
    
    /// 残りを全て取り出す（uppercased無し）
//    public mutating func scanOriginalAll() -> String {
//        let result = self.originalString
//        removeAll()
//        return result
//    }
}

// isNumberだと漢数字なども含まれてしまうため
private let changeMap: [Character: Character] = [
    "０": "0",
    "１": "1",
    "２": "2",
    "３": "3",
    "４": "4",
    "５": "5",
    "６": "6",
    "７": "7",
    "８": "8",
    "９": "9",
]
private let numberCharacters = Set<Character>(arrayLiteral: "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
