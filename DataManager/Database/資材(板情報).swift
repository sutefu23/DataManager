//
//  資材(板情報).swift
//  DataManager
//
//  Created by manager on 2020/03/28.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public protocol 資材情報型 {
    init(製品名称: String, 規格: String)
}

public extension 資材情報型 {
    init(_ item: 資材型) {
        self.init(製品名称: item.製品名称, 規格: item.規格)
    }
}

public struct 資材板情報型: 資材情報型 {
    public private(set) var 材質: String
    public private(set) var 種類: String
    public private(set) var 板厚: String
    public private(set) var サイズ: String
    public private(set) var 高さ: Double?
    public private(set) var 横幅: Double?
    public private(set) var 備考: String
    
    var アクリル種類: アクリル種類型?
    
    public var 面積: Double? {
        guard let height = self.高さ, let width = self.横幅 else { return nil }
        return width * height
    }
    
    public init(製品名称: String, 規格: String) {
        var material: String = ""
        var type: String = ""
        var thin: String = ""
        var square: String = ""
        var height: Double? = nil
        var width: Double? = nil
        var memo: String = ""
        
        // material, type
        let first: String
        var scanner = DMScanner(製品名称, normalizedFullHalf: true, newlineToSpace:true)
        let 製品名称 = scanner.string
        var index = scanner.startIndex
        if let _ = scanner.scanParen("(", ")", stopSpaces:true) {
            let _ = scanner.scanUpToSpace()
            
            first = scanner.leftString(from: index)
        } else if let left = scanner.scanUpToSpace() {
            first = left
        } else {
            first = scanner.string
            scanner.removeAll()
        }
        scanner.dropHeadSpaces()
        let aktype: アクリル種類型? = アクリル種類型(first)
        if let name = aktype?.caption {
            material = name
            if first.hasPrefix("アクリル") {
                let index = first.index(first.startIndex, offsetBy: 4)
                type = String(first[index..<first.endIndex])
            }
        } else if 製品名称.containsOne(of: "カラーステンレス", "チタンゴールド") { // カラーステンレス専用処理
            material = "SUS304"
            thin = "1.5"
            if scanner.scanString("カラーステンレス") {
                scanner.dropHeadSpaces()
            }
        } else if 製品名称.containsOne(of: "チタン", "TP340") { // チタン専用処理
            material = "チタン"
        } else if first.hasSuffix("板") {
            material = String(first.dropLast())
        } else {
            material = String(first)
        }
        // type, memo
        var second: String
        index = scanner.startIndex
        if let _ = scanner.scanParen("(", ")", stopSpaces:true) {
            let _ = scanner.scanUpToSpace()
            second = scanner.leftString(from: index)
        } else if let left = scanner.scanUpToSpace() {
            second = left
        } else {
            second = scanner.string
            scanner.removeAll()
        }
        scanner.dropHeadSpaces()
        scanner.dropTailSpaces()
        var third = scanner.string
        if material == "チタン" { // チタン専用処理
            if second.contains("340") {
                second = third
                third = ""
            }
        }
        if second.contains("SPV") {
            memo = second
            if !third.isEmpty { memo += " \(third)" }
        } else {
            type += second
            memo = third
        }
        // サイズ計算
        func scanSheetSize(_ string: String, normalSize: Bool = false) -> (height: Double, width: Double)? {
            var scanner = DMScanner(string, skipSpaces: true)
            if let (left, _, right) = scanner.scanDoubleAndDouble() {
                if left > 10 && right > 10 {
                    if aktype == .スミペックス && left == 1000 && right == 2000 { return (1040, 2040) }
                    return (left, right)
                }
                if normalSize == true { return nil }
                if let size = aktype?.size(of: (left, right)) { return size }
                switch (left, right) {
                case (1, 1):
                    return (1000, 1000)
                case (1, 2):
                    return (1000, 2000)
                case (3, 6):
                    return (914, 1829)
                case (4, 8):
                    return (1219, 2438)
                case (4, 10):
                    return (1219, 3048)
                case (5, 10):
                    return (1524, 3048)
                default:
                    break
                }
            }
            return nil
        }
        
        // thin, size
        scanner = DMScanner(規格, normalizedFullHalf: true, skipSpaces: true, newlineToSpace: true)
        if let left = scanner.scanUpTo("t") {
            var head = DMScanner(left)
            if let (str, val) = head.scanStringDouble() {
                type.append(str)
                thin = String(val)
            } else {
                thin = left
            }
            if let pair = scanner.scanParen("(", ")") {
                square = pair.left
                if let (h, w) = scanSheetSize(pair.contents, normalSize: true) ?? scanSheetSize(pair.left) {
                    height = h
                    width = w
                }
            } else {
                square = scanner.string
                if let (h, w) = scanSheetSize(square) {
                    height = h
                    width = w
                }
            }
        } else {
            if let left = scanner.scanUpToSpace() {
                type.append(left)
                square = scanner.string
            } else {
                square = scanner.string
            }
            if let (h, w) = scanSheetSize(square) {
                height = h
                width = w
            }
        }
        self.材質 = material
        self.種類 = type
        self.板厚 = thin
        self.サイズ = square
        self.高さ = height
        self.横幅 = width
        self.備考 = memo
        self.アクリル種類 = aktype
    }
}

// MARK: -
enum 板材質型 {
    case ステンレス
    case スチール(スチール種類型)
    case アルミ
    case チタン(チタン種類型)
    case 真鍮
    case 銅
    case アクリル(アクリル種類型)
    case その他(その他板材型)
}

enum その他板材型 {
    case パンチング
    case シマ鋼板
    case ガルバニウム鋼板
}

enum チタン種類型 {
    case TP340
    case その他
}

enum スチール種類型 {
    case 黒皮
    case ボンデ
    case ミガキ鉄板
    case 酸洗鋼板
    case 亜鉛鉄板
    case その他
}

enum アクリル種類型 {
    case カナセライト
    case スミペックス
    case ファンタレックス
    case パラグラス
    case アクリライト
    case コモグラス
    case クラレックス
    case コモミラー
    case その他アクリ
    
    init?<S: StringProtocol>(_ name: S) {
        if name.hasPrefix("カナセライト") {
            self = .カナセライト
        } else if name.hasPrefix("スミペックス") {
            self = .スミペックス
        } else if name.hasPrefix("アクリライト") {
            self = .アクリライト
        } else if name.hasPrefix("コモグラス") {
            self = .コモグラス
        } else if name.hasPrefix("ファンタレックス") {
            self = .ファンタレックス
        } else if name.hasPrefix("パラグラス") {
            self = .パラグラス
        } else if name.hasPrefix("コモミラー") {
            self = .コモミラー
        } else if name.hasPrefix("クラレックス") {
            self = .クラレックス
        } else if name.contains("アクリ") || name.contains("グラス") {
            self = .その他アクリ
        } else {
            return nil
        }
    }
    
    func size(of size:(h: Double, w: Double)) -> (height: Double, width: Double)? {
        switch self {
        case .カナセライト:
            switch size {
            case (1, 2):
                return (1020, 2030)
            case (3, 6):
                return (920, 1850)
            case (4, 8):
                return (1230, 2470)
            default:
                break
            }
        case .スミペックス:
            switch size {
            case (1, 2):
                return (1040, 2040)
            case (3, 6):
                return (930, 1860)
            case (4, 8):
                return (1240, 2480)
            default:
                break
            }
        default:
            break
        }
        return nil
    }
    
    var caption: String {
        switch self {
        case .カナセライト: return "カナセライト"
        case .スミペックス: return "スミペックス"
        case .ファンタレックス: return "ファンタレックス"
        case .パラグラス: return "パラグラス"
        case .アクリライト: return "アクリライト"
        case .コモグラス: return "コモグラス"
        case .クラレックス: return "クラレックス"
        case .コモミラー: return "コモミラー"
        case .その他アクリ: return "アクリル"
        }
    }
}


