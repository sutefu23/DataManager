//
//  指示書ボルト欄.swift
//  DataManager
//
//  Created by manager on 2020/05/13.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 消費情報型 {
    public var 図番: 図番型
    public var 分量: Double
}

public enum 資材種類型 {
    case ボルト(サイズ: String, 長さ: Double)
    case ワッシャー(サイズ: String)
    case Sワッシャー(サイズ: String)
    case ナット(サイズ: String)
    case 丸パイプ(サイズ: String)
    case 特皿(サイズ: String, 長さ: Double)
    case サンロックトラス(サイズ: String, 長さ: Double)
    case サンロック特皿(サイズ: String, 長さ: Double)
    case トラス(サイズ: String, 長さ: Double)
    case スリムヘッド(サイズ: String, 長さ: Double)
    case Cタッピング(サイズ: String, 長さ: Double)
    
    init?(ボルト欄: String) {
        var scanner = DMScanner(ボルト欄, normalizedFullHalf: true, upperCased: true, skipSpaces: true)
        if let data = scanner.scanボルト() { self = data }
        else if let data = scanner.scanワッシャー() { self = data }
        else if let data = scanner.scanSワッシャー() { self = data }
        else if let data = scanner.scanナット() { self = data }
        else if let data = scanner.scan丸パイプ() { self = data }
        else if let data = scanner.scan特皿() { self = data }
        else if let data = scanner.scanサンロックトラス() { self = data }
        else if let data = scanner.scanサンロック特皿() { self = data }
        else if let data = scanner.scanトラス() { self = data }
        else if let data = scanner.scanスリムヘッド() { self = data }
        else if let data = scanner.scanCタッピング() { self = data }
        else { return nil }
    }
    
    
}

private extension DMScanner {
    mutating func scanSizeXLength(_ name: String) -> (size: String, length: Double)? {
        guard scanString(name) else { return nil }
        guard var size = scanStringDouble(), size.value > 0 else { return nil }
        if scanCharacter("/"), let size2 = scanStringDouble() {
            size.string += "/\(size2.string)"
        }
        guard scanCharacters("X", "×", "*") else { return nil }
        guard let length = scanDouble(), length > 0 else { return nil }
        guard scanCharacter("L") else { return nil }
        return (size.string, length)
    }
    
    mutating func scanSize(_ name: String) -> String? {
        guard name.isEmpty || scanString(name) else { return nil }
        guard let size = scanStringDouble(), size.value > 0 else { return nil }
        return size.string
    }
    
    mutating func scanボルト() -> 資材種類型? {
        guard let (size, length) = scanSizeXLength("M") else {
            self.reset()
            return nil
        }
        return .ボルト(サイズ: size, 長さ: length)
    }
    
    mutating func scanワッシャー() -> 資材種類型? {
        guard let size = scanSize("ワッシャー") else {
            self.reset()
            return nil
        }
        return .ワッシャー(サイズ: size)
    }
    
    mutating func scanSワッシャー() -> 資材種類型? {
        guard let size = scanSize("Sワッシャー") else {
            self.reset()
            return nil
        }
        return .Sワッシャー(サイズ: size)
    }
    
    mutating func scanナット() -> 資材種類型? {
        guard scanString("ナット") else { return nil }
        guard let size = scanStringDouble(), size.value > 0 else {
            self.reset()
            return nil
        }
        return .ナット(サイズ: size.string)
    }
    
    mutating func scan丸パイプ() -> 資材種類型? {
        guard let size = scanStringDouble(), size.value > 0 else {
            self.reset()
            return nil
        }
        guard scanCharacter("φ") else { return nil }
        return .丸パイプ(サイズ: size.string)
    }
    
    mutating func scan特皿() -> 資材種類型? {
        guard let (size, length) = scanSizeXLength("特皿M") else {
            self.reset()
            return nil
        }
        return .特皿(サイズ: size, 長さ: length)
    }
    
    mutating func scanサンロックトラス() -> 資材種類型? {
        guard let (size, length) = scanSizeXLength("サンロックトラスM") else {
            self.reset()
            return nil
        }
        return .サンロックトラス(サイズ: size, 長さ: length)
    }
    
    mutating func scanサンロック特皿() -> 資材種類型? {
        guard let (size, length) = scanSizeXLength("サンロック特皿M") else {
            self.reset()
            return nil
        }
        return .サンロックトラス(サイズ: size, 長さ: length)
    }
    
    mutating func scanトラス() -> 資材種類型? {
        guard let (size, length) = scanSizeXLength("トラスM") else {
            self.reset()
            return nil
        }
        return .トラス(サイズ: size, 長さ: length)
    }
    
    mutating func scanスリムヘッド() -> 資材種類型? {
        guard let (size, length) = scanSizeXLength("スリムヘッドM") else {
            self.reset()
            return nil
        }
        return .スリムヘッド(サイズ: size, 長さ: length)
    }
    
    mutating func scanCタッピング() -> 資材種類型? {
        guard let (size, length) = scanSizeXLength("CタッピングM") else {
            self.reset()
            return nil
        }
        return .Cタッピング(サイズ: size, 長さ: length)
    }
}
