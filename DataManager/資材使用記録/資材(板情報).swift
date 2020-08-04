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
    public private(set) var 材質: String // SUS304
    public private(set) var 種類: String // HL
    public private(set) var 板厚: String // 3.0
    public private(set) var サイズ: String // 4x8
    public private(set) var 高さ: Double? // 1219
    public private(set) var 横幅: Double? // 2438
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
                let isMeter: Bool = (material.containsOne(of: "アルミ", "BSP"))
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
                    return !isMeter ? (1219, 2438) : (1250, 2500)
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
            if let (str, val) = head.scanStringAndDouble() {
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

// MARK: -
public struct 選択板型 {
    public let 図番: 図番型
    public let 社名先頭1文字: String
    public let 種類: String
    public let 板厚: String
    public let サイズ: String
    
    init(図番: 図番型, 種類: String, 板厚: String, サイズ: String) {
        self.図番 = 図番.toJapaneseNormal
        self.種類 = 種類.toJapaneseNormal
        self.板厚 = 板厚.toJapaneseNormal
        self.サイズ = サイズ.toJapaneseNormal
        if 図番.hasSuffix("B") {
            self.社名先頭1文字 = "M"
        } else if 図番.hasSuffix("M") {
            self.社名先頭1文字 = "松"
        } else if 図番.hasSuffix("K") {
            self.社名先頭1文字 = "菊"
        } else if let item = 資材型(図番: 図番) {
            if let ch = item.発注先名称.remove㈱㈲.first {
                self.社名先頭1文字 = String(ch)
            } else {
                self.社名先頭1文字 = ""
            }
        } else {
            self.社名先頭1文字 = ""
        }
    }
}

public let フォーミング板リスト: [選択板型] = [
    // １枚目
    選択板型(図番: "990020", 種類: "HL", 板厚: "1.2t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990023B", 種類: "HL", 板厚: "1.5t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "992129B", 種類: "HL", 板厚: "1.5t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990026M", 種類: "HL", 板厚: "2.0t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "992116", 種類: "両面HL", 板厚: "1.5t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "881218", 種類: "両面HL", 板厚: "2.0t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990155B", 種類: "2B", 板厚: "1.2t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990163M", 種類: "2B", 板厚: "1.5t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990175M", 種類: "2B", 板厚: "1.5t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990164", 種類: "2B", 板厚: "2.0t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990022", 種類: "2Bテープ無し", 板厚: "1.5t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990021", 種類: "M", 板厚: "1.2t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990024", 種類: "M", 板厚: "1.5t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990027M", 種類: "M", 板厚: "2.0t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990329", 種類: "BSP", 板厚: "1.2t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990330", 種類: "BSP", 板厚: "1.5t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990331", 種類: "BSP", 板厚: "2.0t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990381", 種類: "CUP", 板厚: "1.5t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990382", 種類: "CUP", 板厚: "2.0t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "992018", 種類: "430", 板厚: "2.0t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990230", 種類: "AL", 板厚: "1.5t", サイズ: "1×2(1000×2000)"),
    選択板型(図番: "990231", 種類: "AL", 板厚: "2.0t", サイズ: "1×2(1000×2000)"),
    // ２枚目
    選択板型(図番: "990014B", 種類: "HL", 板厚: "0.8t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990051M", 種類: "HL", 板厚: "0.8t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990051B", 種類: "HL", 板厚: "0.8t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990017B", 種類: "HL", 板厚: "1.0t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990057B", 種類: "HL", 板厚: "1.0t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990160B", 種類: "2B", 板厚: "0.8t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990161B", 種類: "2B", 板厚: "1.0t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990173B", 種類: "2B", 板厚: "1.0t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990173M", 種類: "2B", 板厚: "1.0t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990049K", 種類: "2Bテープ無し", 板厚: "0.8t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990015M", 種類: "M", 板厚: "0.8t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990053B", 種類: "M", 板厚: "0.8t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990018B", 種類: "M", 板厚: "1.0t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990059B", 種類: "M", 板厚: "1.0t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990327", 種類: "BSP", 板厚: "0.8t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990328", 種類: "BSP", 板厚: "1.0t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990378", 種類: "CUP", 板厚: "0.8t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990379", 種類: "CUP", 板厚: "1.0t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "880347", 種類: "ｶﾗｰｽﾃﾝﾚｽ SR-15", 板厚: "0.8t", サイズ: "1219x2000"),
    選択板型(図番: "992045", 種類: "ｶﾗｰｽﾃﾝﾚｽ SR-15", 板厚: "0.8t", サイズ: "4x8"),
    選択板型(図番: "992046", 種類: "ｶﾗｰｽﾃﾝﾚｽ SP-17", 板厚: "0.8t", サイズ: "4x8"),
    選択板型(図番: "880350", 種類: "ｶﾗｰｽﾃﾝﾚｽ SP-17", 板厚: "0.8t", サイズ: "1219x2000"),
    選択板型(図番: "992000", 種類: "塩ビ", 板厚: "1.0t", サイズ: "1x2"),
    選択板型(図番: "992140", 種類: "アルミ複合板", 板厚: "3.0t", サイズ: "1x2(1000x2000)"),
    // ３枚目
    選択板型(図番: "990312", 種類: "BSP", 板厚: "0.5t", サイズ: "小板(365×1200)"),
    選択板型(図番: "990362", 種類: "CUP", 板厚: "0.5t", サイズ: "小板(365×1200)"),
    選択板型(図番: "990363", 種類: "CUP", 板厚: "0.6t", サイズ: "小板(365×1200)"),
    選択板型(図番: "990003", 種類: "M", 板厚: "0.4t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990006", 種類: "M", 板厚: "0.5t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990009", 種類: "M", 板厚: "0.6t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990154B", 種類: "2B", 板厚: "0.4t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990157B", 種類: "2B", 板厚: "0.5t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990158B", 種類: "2B", 板厚: "0.6t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990007", 種類: "2Bテープ無し", 板厚: "0.6t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990002", 種類: "HL", 板厚: "0.4t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990005", 種類: "HL", 板厚: "0.5t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990008", 種類: "HL", 板厚: "0.6t", サイズ: "1x2(1000x2000)"),
    選択板型(図番: "990216", 種類: "ALテープ無し", 板厚: "0.5t", サイズ: "小板(400×1200)"),
    // 追加
    選択板型(図番: "990424", 種類: "ボンデ", 板厚: "1.0t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990434", 種類: "ボンデ", 板厚: "1.2t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990427", 種類: "ボンデ", 板厚: "1.6t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "990430", 種類: "ボンデ", 板厚: "2.3t", サイズ: "4x8(1219x2438)"),
    選択板型(図番: "883056", 種類: "ｶﾗｰｽﾃﾝﾚｽ ST-4", 板厚: "1.5t", サイズ: "4x8(1219x2438)"),

    選択板型(図番: "991055", 種類: "ｶﾗｰｽﾃﾝﾚｽ SR-15", 板厚: "1.5t", サイズ: "4x8"),
    選択板型(図番: "991795", 種類: "ｶﾗｰｽﾃﾝﾚｽ SP-17", 板厚: "1.5t", サイズ: "4x8"),
    選択板型(図番: "991972", 種類: "ﾁﾀﾝｺﾞｰﾙﾄﾞHL", 板厚: "1.5t", サイズ: "4x8"),
    選択板型(図番: "880183", 種類: "ﾁﾀﾝｺﾞｰﾙﾄﾞM", 板厚: "1.5t", サイズ: "4x8"),
    ].sorted {
        if $0.板厚 != $1.板厚 { return $0.板厚 < $1.板厚 }
        if $0.種類 != $1.種類 { return $0.種類 < $1.種類 }
        if $0.サイズ != $1.サイズ { return $0.サイズ < $1.サイズ }
        return $0.図番 < $1.図番
}
