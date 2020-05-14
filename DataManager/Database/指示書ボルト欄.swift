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

public enum 指示書ボルト欄型 {
    case ボルトカット(サイズ: String, 長さ: Double, 数量: Int, 消費情報: 消費情報型?)
    case パイプカット(サイズ: String, 長さ: Double, 数量: Int, 消費情報: 消費情報型?)
    
    init?(ボルト欄: String, 数量欄: String) {
        if let bolt = makeボルトカット(ボルト欄: ボルト欄, 数量欄: 数量欄) {
            self = bolt
        } else {
            return nil
        }
    }
}

func makeボルトカット(ボルト欄: String, 数量欄: String) -> 指示書ボルト欄型? {
    var info: 消費情報型? = nil
    var scale = 1.0
    var scanner = DMScanner(ボルト欄, normalizedFullHalf: true, upperCased: true, skipSpaces: true)
    guard let size = scanner.scanStringDouble() else { return nil }
    guard let length = scanner.scanDouble() else { return nil }
    guard scanner.scanCharacter("L") else { return nil }
    guard let count = Int(数量欄) else { return nil }
    if scanner.scanCharacter("各") {
        guard let value = scanner.scanDouble() else { return nil }
        scale = value
    }
    if length == 285 {
        let value = Double(count) * scale
        switch size.value {
        case 4.0: info = 消費情報型(図番: "321", 分量: value)
        case 5.0: info = 消費情報型(図番: "322", 分量: value)
        case 6.0: info = 消費情報型(図番: "323", 分量: value)
        case 8.0: info = 消費情報型(図番: "324", 分量: value)
        case 10.0: info = 消費情報型(図番: "365", 分量: value)
        case 12.0: info = 消費情報型(図番: "327", 分量: value)
        case 16.0: info = 消費情報型(図番: "314", 分量: value)
        default: break
        }
    } else {
        let value = Double(count) * 1000 * scale / length
        switch size.value {
        case 3.0: info = 消費情報型(図番: "328I", 分量: value)
        case 4.0: info = 消費情報型(図番: "339", 分量: value)
        case 5.0: info = 消費情報型(図番: "330", 分量: value)
        case 6.0: info = 消費情報型(図番: "331", 分量: value)
        case 8.0: info = 消費情報型(図番: "332", 分量: value)
        case 10.0: info = 消費情報型(図番: "334", 分量: value)
        case 12.0: info = 消費情報型(図番: "335", 分量: value)
        case 16.0: info = 消費情報型(図番: "2733", 分量: value)
        default: break
        }
    }
    return .パイプカット(サイズ: size.string, 長さ: length, 数量: count, 消費情報: info)
}
