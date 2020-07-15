//
//  指示書ボルト欄.swift
//  DataManager
//
//  Created by manager on 2020/05/13.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

private let 箱文字Set = Set<工程型>([.立ち上がり, .半田, .裏加工, .立ち上がり_溶接, .溶接, .裏加工_溶接])
private let 切文字Set = Set<工程型>([.切文字])

public enum ボルト数調整モード型 {
    case 調整なし
    case 箱文字式
    case 切文字式
    
    public init(_ process: 工程型) {
        if 箱文字Set.contains(process) {
            self = .箱文字式
        } else if 切文字Set.contains(process) {
            self = .切文字式
        } else {
            self = .調整なし
        }
    }
    
    public func 数量調整(ベース数量 count: Double, 資材種類: 資材種類型?, 表示名: String) -> Double {
        switch self {
        case .箱文字式:
            let offset: [Double]
            switch 資材種類 {
            case .ボルト(_, _), .六角(_, _), .スタッド(_, _), .ALスタッド(_, _), .ストレートスタッド(_, _):
                offset = [1, 2, 3, 3, 3, 5, 5, 6]
            case .丸パイプ(_, _), .浮かしパイプ(_, _):
                offset = [1, 2, 3, 3, 3, 5, 5, 6]
            case .スリムヘッド(_, _), .トラス(_, _), .サンロックトラス(_, _), .サンロック特皿(_, _), .特皿(_, _), .Cタッピング(_, _), .ナベ(_, _), .テクスナベ(_, _), .テクス皿(_, _), .テクス特皿(_, _), .皿(_, _), .片ネジ(_, _):
                offset = [2, 3, 3, 5, 10, 10, 10, 20]
            case .ナット(_):
                offset = [2, 3, 3, 5, 10, 10, 10, 15]
            case .ワッシャー(_), .Sワッシャー(_), .特寸ワッシャー(_, _, _):
                offset = [2, 3, 3, 5, 10, 10, 10, 15]
            case .定番FB(_), .FB(_, _):
                return count
            case .三角コーナー:
                return count
            case nil:
                if 表示名.hasPrefix("L金具") {
                    offset = [2, 3, 3, 5, 10, 10, 10, 10]
                    break
                }
                return count
            }
            assert(offset.count == 8)
            if (1...5).contains(count) { return offset[0] + count }
            if (6...10).contains(count) { return offset[1] + count }
            if (11...15).contains(count) { return offset[2] + count }
            if (16...30).contains(count) { return offset[3] + count }
            if (31...40).contains(count) { return offset[4] + count }
            if (41...50).contains(count) { return offset[5] + count }
            if (51...100).contains(count) { return offset[6] + count }
            if (101...).contains(count) { return offset[7] + count }
            return count
        case .切文字式:
            let offset: [Double]
            switch 資材種類 {
            case .ボルト(_, _), .六角(_, _), .スタッド(_, _), .ALスタッド(_, _), .ストレートスタッド(_, _):
                offset = [1, 2, 3, 3, 3, 5, 10, 10]
            case .丸パイプ(_, _), .浮かしパイプ(_, _):
                offset = [1, 2, 3, 3, 3, 5, 10, 10]
            case .スリムヘッド(_, _), .トラス(_, _), .サンロックトラス(_, _), .サンロック特皿(_, _), .特皿(_, _), .Cタッピング(_, _), .ナベ(_, _), .テクスナベ(_, _), .テクス皿(_, _), .テクス特皿(_, _), .皿(_, _), .片ネジ(_, _):
                offset = [2, 3, 3, 5, 10, 10, 10, 10]
            case .ナット(_):
                offset = [2, 3, 3, 5, 10, 10, 10, 10]
            case .ワッシャー(_), .Sワッシャー(_), .特寸ワッシャー(_, _, _):
                offset = [2, 3, 3, 5, 10, 10, 10, 10]
            case .定番FB(_), .FB(_, _):
                return count
            case .三角コーナー:
                return count
            case nil:
                return count
            }
            assert(offset.count == 8)
            if (1...5).contains(count) { return offset[0] + count }
            if (6...10).contains(count) { return offset[1] + count }
            if (11...15).contains(count) { return offset[2] + count }
            if (16...30).contains(count) { return offset[3] + count }
            if (31...40).contains(count) { return offset[4] + count }
            if (41...50).contains(count) { return offset[5] + count }
            if (51...100).contains(count) { return offset[6] + count }
            if (101...).contains(count) { return offset[7] + count }
            return count
        default:
            return count
        }
    }
}

public enum ボルト数欄型 {
    case 合計(Double)
    case 分納(Double, Double)
    
    public init?(ボルト数欄: String, セット数: Double) {
        var scanner = DMScanner(ボルト数欄, normalizedFullHalf: true, upperCased: true, skipSpaces: true)
        if scanner.scanString("/") {
            guard scanner.scanAll().isEmpty else { return nil }
            self = .分納(0, 0)
            return
        }
        guard let number = scanner.scanDouble() else { return nil }
        if scanner.scanCharacter("+") {
            guard let number2 = scanner.scanDouble() else { return nil }
            self = .合計((number+number2) * セット数)
        } else if scanner.scanCharacter("/") {
            guard let number2 = scanner.scanDouble() else { return nil }
            self = .分納(number * セット数, number2 * セット数)
        } else {
            self = .合計(number * セット数)
        }
    }
    
    public var 総数: Double {
        switch self {
        case .合計(let num):
            return num
        case .分納(let left, let right):
            return left + right
        }
    }
    
    public var 溶接数: Double? {
        switch self {
        case .分納(let left, _):
            return left
        case .合計(_):
            return nil
        }
    }
    
    public var 半田数: Double? {
        switch self {
        case .分納(_,let right):
            return right
        case .合計(_):
            return nil
        }
    }
}

public enum 金額計算タイプ型 {
    case 平面板(height: Double, width: Double)
    case 平面形状(area: Double)
    case カット棒(itemLength: Double, length: Double)
    case 個数物
    case コイル材
    
    public var area: Double? {
        switch self {
        case .平面板(height: let height, width: let width):
            return height * width
        case .平面形状(area: let area):
            return area
        default:
            return nil
        }
    }
    
    public func 単位量(資材 item: 資材型) -> Double? {
        switch self {
        case .カット棒(itemLength: let itemLength, length: let length):
            return length / itemLength
        case .コイル材:
            let coil = 資材コイル情報型(item)
            if coil.種類 != "コイル" { return nil }
            let vol = coil.板厚 * coil.高さ
            switch coil.材質 {
            case "SUS304":
                let kg = vol * 7.93 / 1000000
                return kg
            default:
                return nil
            }
            
        case .個数物:
            return 1.0
        case .平面形状(area: let area):
            if let sheetArea = 資材板情報型(item).面積 {
                return area / sheetArea
            }
        case .平面板(height: let height, width: let width):
            if let sheetArea = 資材板情報型(item).面積 {
                let area = width * height
                return area / sheetArea
            }
        }
        return nil
    }
    
    public func 使用量表示(count: Double?) -> String {
        if let count = count {
            switch self {
            case .カット棒(itemLength: _, length: let length):
                return "\(length)mm \(count)本"
            case .コイル材:
                return "\(count)mm"
            case .個数物:
                return "\(count)個"
            case .平面形状(area: let area):
                return "\(area)㎟ \(count)個"
            case .平面板(height: let height, width: let width):
                return "\(height)x\(width) \(count)枚"
            }
        } else {
            switch self {
            case .カット棒(itemLength: _, length: let length):
                return "\(length)mm"
            case .コイル材:
                return ""
            case .個数物:
                return ""
            case .平面形状(area: let area):
                return "\(area)㎟"
            case .平面板(height: let height, width: let width):
                return "\(height)x\(width)"
            }
        }
    }
    public func 金額(資材: 資材型, count: Double?) -> Double? {
        guard let price = 資材.単価, let unit = self.単位量(資材: 資材) else { return nil }
        let count = count ?? 1.0
        return unit * count * price
    }
}

public struct 資材要求情報型 {
    public let 図番: 図番型
    public let 金額計算タイプ: 金額計算タイプ型?
    public let 表示名: String
    public let 分割表示名1: String
    public let 分割表示名2: String
    public let ソート順: Double
    public let 資材種類: 資材種類型?
    public let ボルト数量: ボルト数欄型?
    public let is附属品: Bool?
    
    public var 資材: 資材型? { 資材型(図番: self.図番) }
    public lazy var 単価: Double? = self.資材?.単価
    public var 単位数: Double?
    public var 金額: Double? {
        guard let item = self.資材 else { return nil }
        return 金額計算タイプ?.金額(資材: item, count: self.単位数)
    }
    
    public var 使用量: String? { 金額計算タイプ?.使用量表示(count: self.単位数) }
    public var 単価テキスト: String { self.資材?.単価?.金額テキスト ?? "" }
    public var 金額テキスト: String { self.金額?.金額テキスト ?? "" }
    
    public func is分納相手完納済み(_ order: 指示書型, 自工程: 工程型) throws -> Bool? {
        guard let list = try order.キャッシュ資材使用記録() else { return false }
        switch self.ボルト数量 {
        case .合計(_), nil:
            return nil
        case .分納(_, _):
            return list.contains { $0.図番 == self.図番 && $0.工程 != 自工程 && $0.表示名 == self.表示名 }
        }
    }
    
    public func allRegistered(_ order: 指示書型) throws -> Bool {
        guard let list = try order.キャッシュ資材使用記録() else { return false }
        switch self.ボルト数量 {
        case .合計(_), nil:
            return list.contains { $0.図番 == self.図番 && $0.表示名 == self.表示名 }
        case .分納(_, _):
            var set = Set<工程型>()
            for data in list where data.図番 == self.図番 && data.表示名 == self.表示名 {
                set.insert(data.工程)
            }
            return set.count >= 2
        }
    }
    
    public func checkRegistered(_ order: 指示書型, _ process: 工程型) throws -> Bool {
        guard let list = try order.キャッシュ資材使用記録() else { return false }
        switch self.ボルト数量 {
        case .合計(_), nil:
            return list.contains{ $0.図番 == self.図番 && $0.表示名 == self.表示名 }
        case .分納(_, _):
            return list.contains{ $0.図番 == self.図番 && $0.工程 == process && $0.表示名 == self.表示名 }
        }
    }
    
    public mutating func 数量調整(ボルト数調整モード: ボルト数調整モード型) {
        switch ボルト数調整モード {
        case .調整なし: return
        case .箱文字式, .切文字式:
            if self.is附属品 != true { return }
            guard let count = self.単位数 else { return }
            self.単位数 = ボルト数調整モード.数量調整(ベース数量: count, 資材種類: self.資材種類, 表示名: self.表示名)
        }
    }
    
    public init?(ボルト欄: String, 数量欄: String, セット数: Double, 伝票種類: 伝票種類型) {
        if ボルト欄.isEmpty { return nil }
        var text = ボルト欄.toJapaneseNormal
        let is附属品: Bool
        if text.hasPrefix("+") {
            text.removeFirst(1)
            is附属品 = false
        } else {
            is附属品 = true
        }
        self.表示名 = text
        self.is附属品 = is附属品
        let set = (セット数 >= 1) ? セット数 : 1
        let numbers = ボルト数欄型(ボルト数欄: 数量欄, セット数: set)
        guard let (title, size, type, priority) = scanSource(ボルト欄: text) else {
            guard let object = 板加工在庫マップ[text] else { return nil }
            self.ソート順 = object.ソート順
            self.分割表示名1 = object.名称
            self.分割表示名2 = ""
            self.資材種類 = nil
            self.ボルト数量 = numbers
            self.単位数 = numbers?.総数
            self.金額計算タイプ = 金額計算タイプ型.平面形状(area: object.面積)
            self.図番 = object.資材.図番
            return
        }
        self.ソート順 = priority
        self.分割表示名1 = title
        self.分割表示名2 = size
        self.資材種類 = type
        self.ボルト数量 = numbers
        self.単位数 = numbers?.総数 ?? 0
        guard let info = type.make使用情報() else { return nil }
        self.図番 = info.図番
        self.金額計算タイプ = info.金額計算タイプ
    }

    public init?(printSource: 資材使用記録型) {
        var text = printSource.表示名.toJapaneseNormal
        self.表示名 = text
        let is附属品: Bool
        if text.hasPrefix("+") {
            text.removeFirst(1)
            is附属品 = false
        } else {
            is附属品 = true
        }
        self.図番 = printSource.図番
        self.is附属品 = is附属品
        self.資材種類 = nil
        self.ボルト数量 = nil
        self.単位数 = nil
        self.金額計算タイプ = nil
        if let (title, size, _, priority) = scanSource(ボルト欄: text) {
            self.ソート順 = priority
            self.分割表示名1 = title
            self.分割表示名2 = size
        } else if let object = 板加工在庫マップ[text] {
            self.ソート順 = object.ソート順
            self.分割表示名1 = printSource.表示名
            self.分割表示名2 = ""
        } else {
            self.ソート順 = 0
            self.分割表示名1 = printSource.表示名
            self.分割表示名2 = ""
        }
    }
    
    public func 現在数量(伝票番号: 伝票番号型) ->  Double? {
        guard let list = (try? 資材使用記録型.find(伝票番号: 伝票番号, 図番: self.図番, 表示名: self.表示名)), !list.isEmpty else { return nil }
        var volume: Double? = nil
        for data in list {
            guard let vol = data.単位数 else { continue }
            if let vol2 = volume {
                volume = vol2 + vol
            } else {
                volume = vol
            }
        }
        return volume
    }
}
public func sortCompare(_ left: 資材要求情報型, _ right: 資材要求情報型) -> Bool {
    if left.ソート順 != right.ソート順 { return left.ソート順 > right.ソート順 }
    if left.分割表示名1 != right.分割表示名1 { return left.分割表示名1 < right.分割表示名2 }
    if left.分割表示名2 != right.分割表示名2 { return left.分割表示名1 < right.分割表示名2 }
    return false
}

func scanSource(ボルト欄: String) -> (名称: String, サイズ: String, 種類: 資材種類型, ソート順: Double)? {
    var scanner = DMScanner(ボルト欄, normalizedFullHalf: true, upperCased: true, skipSpaces: true, newlineToSpace: true)
    func makeTail(_ data: (名称: String, 種類: 資材種類型, ソート順: Double)) -> (名称: String, サイズ: String, 種類: 資材種類型, ソート順: Double) {
        scanner.reset()
        scanner.skipMatchString(data.名称)
        let size: String
        switch data.種類 {
        case .特寸ワッシャー(サイズ: _, 外径: _, 内径: _):
            size = scanner.substring.lowercased()
        default:
            size = scanner.string
        }
        return (data.名称, size, data.種類, data.ソート順)
    }
    
    if let data = scanner.scanボルト() { return makeTail(data) }
    if let data = scanner.scanFB() { return makeTail(data) }
    if let data = scanner.scanワッシャー() { return makeTail(data) }
    if let data = scanner.scanSワッシャー() { return makeTail(data) }
    if let data = scanner.scan特寸ワッシャー() { return makeTail(data) }
    if let data = scanner.scanナット() { return makeTail(data) }
    if let data = scanner.scan丸パイプ() { return makeTail(data) }
    if let data = scanner.scan特皿() { return makeTail(data) }
    if let data = scanner.scan皿() { return makeTail(data) }
    if let data = scanner.scanサンロックトラス() { return makeTail(data) }
    if let data = scanner.scanサンロック特皿() { return makeTail(data) }
    if let data = scanner.scanトラス() { return makeTail(data) }
    if let data = scanner.scanスリムヘッド() { return makeTail(data) }
    if let data = scanner.scanCタッピング() { return makeTail(data) }
    if let data = scanner.scanナベ() { return makeTail(data) }
    if let data = scanner.scanテクスナベ() { return makeTail(data) }
    if let data = scanner.scanテクス皿() { return makeTail(data) }
    if let data = scanner.scanテクス特皿() { return makeTail(data) }
    if let data = scanner.scan六角() { return makeTail(data) }
    if let data = scanner.scanスタッド() { return makeTail(data) }
    if let data = scanner.scanストレートスタッド() { return makeTail(data) }
    if let data = scanner.scanALスタッド() { return makeTail(data) }
    if let data = scanner.scanFBSimple() { return makeTail(data) }
    if let data = scanner.scan三角コーナー() { return makeTail(data) }

    return nil
}

public enum 資材種類型 {
    case ボルト(サイズ: String, 長さ: Double)
    case FB(板厚: String, 高さ: Double)
    case 定番FB(板厚: String)
    case ワッシャー(サイズ: String)
    case Sワッシャー(サイズ: String)
    case 特寸ワッシャー(サイズ: String, 外径: Double, 内径: Double)
    case ナット(サイズ: String)
    case 浮かしパイプ(サイズ: String, 長さ: Double)
    case 丸パイプ(サイズ: String, 長さ: Double)
    case 皿(サイズ: String, 長さ: Double)
    case 特皿(サイズ: String, 長さ: Double)
    case サンロックトラス(サイズ: String, 長さ: Double)
    case サンロック特皿(サイズ: String, 長さ: Double)
    case トラス(サイズ: String, 長さ: Double)
    case スリムヘッド(サイズ: String, 長さ: Double)
    case Cタッピング(サイズ: String, 長さ: Double)
    case ナベ(サイズ: String, 長さ: Double)
    case テクスナベ(サイズ: String, 長さ: Double)
    case テクス皿(サイズ: String, 長さ: Double)
    case テクス特皿(サイズ: String, 長さ: Double)
    case 片ネジ(サイズ: String, 長さ: Double)
    case 六角(サイズ: String, 長さ: Double)
    case スタッド(サイズ: String, 長さ: Double)
    case ストレートスタッド(サイズ: String, 長さ: Double)
    case ALスタッド(サイズ: String, 長さ: Double)
    case 三角コーナー
    
    public func make使用情報() -> (図番: 図番型, 金額計算タイプ: 金額計算タイプ型)? {
        let 図番: 図番型
        let 金額計算タイプ: 金額計算タイプ型
        switch self {
        case .FB(板厚: let thin, 高さ: let height):
            guard let object = searchボルト等(種類: "FB", サイズ: thin, 長さ: height) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .定番FB(板厚: let size):
            switch Double(size) {
            case 3:
                図番 = "996271"
            case 5:
                図番 = "991176"
            case 6:
                図番 = "991200"
            case 8:
                図番 = "991201"
            case 10:
                図番 = "991206"
            case 12:
                図番 = "991207"
            case 15:
                図番 = "991208"
            case 20:
                図番 = "991210"
            case 25:
                図番 = "991212"
            case 30:
                図番 = "991214"
            default:
                return nil
            }
            金額計算タイプ = .個数物
        case .ボルト(サイズ: let size, 長さ: let length):
            let itemLength: Double
            if let object = searchボルト等(種類: "ボルト", サイズ: size, 長さ: length) {
                itemLength = length
                図番 = object.図番
            } else if let object = searchボルト等(種類: "ボルト", サイズ: size) {
                itemLength = 1000
                図番 = object.図番
            } else {
                return nil
            }
            金額計算タイプ = .カット棒(itemLength: itemLength, length: length)
        case .浮かしパイプ(サイズ: let size, 長さ: let length):
            if let object = searchボルト等(種類: "浮かしパイプ", サイズ: size, 長さ: length) {
                図番 = object.図番
            } else {
                return nil
            }
            金額計算タイプ = .個数物
        case .ナット(サイズ: let size):
            guard let object = searchボルト等(種類: "ナット", サイズ: size) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .ワッシャー(サイズ: let size):
            guard let object = searchボルト等(種類: "ワッシャー", サイズ: size) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .Sワッシャー(サイズ: let size):
            guard let object = searchボルト等(種類: "Sワッシャー", サイズ: size) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .特寸ワッシャー(サイズ: let size, 外径: let r1, 内径: let r2):
            let r1str = String(format: "%.0f", r1)
            let r2format = (r2 == round(r2)) ? "%.0f" : "%.1f"
            let r2str = String(format: r2format, r2)

            let len = "\(r1str)φx\(r2str)φ"
            guard let object = searchボルト等(種類: "特寸ワッシャー", サイズ: size, 長さ: len) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .丸パイプ(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "丸パイプ", サイズ: size) else { return nil }
            図番 = object.図番
            let itemLength: Double = 4000
            金額計算タイプ = .カット棒(itemLength: itemLength, length: length)
        case .Cタッピング(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "Cタッピング", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .サンロックトラス(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "サンロックトラス", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .サンロック特皿(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "サンロック特皿", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .皿(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "皿", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .特皿(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "特皿", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .トラス(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "トラス", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .スリムヘッド(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "スリムヘッド", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .ナベ(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "ナベ", サイズ: size, 長さ: length) ?? searchボルト等(種類: "なべ", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .テクスナベ(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "テクスナベ", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .テクス皿(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "テクス皿", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .テクス特皿(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "テクス特皿", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .片ネジ(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "片ネジ", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .六角(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "六角", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .スタッド(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "スタッド", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .ストレートスタッド(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "ストレートスタッド", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .ALスタッド(サイズ: let size, 長さ: let length):
            guard let object = searchボルト等(種類: "ALスタッド", サイズ: size, 長さ: length) else { return nil }
            図番 = object.図番
            金額計算タイプ = .個数物
        case .三角コーナー:
            図番 = "2016"
            金額計算タイプ = .個数物
        }
        return (図番, 金額計算タイプ)
    }
}

extension DMScanner {
    mutating func scanSizeXLength(_ name: String, unit1: Character? = nil) -> (size: String, length: Double)? {
        guard scanString(name) else { return nil }
        guard var size = scanStringAsDouble(), size.value > 0 else { return nil }
        if scanCharacter("/") {
            if let size2 = scanStringAsDouble() {
                size.string += "/\(size2.string)"
            }
        }
        if let ch = unit1, !scanCharacter(ch) { return nil }
        guard scanCharacters("X", "×", "*") else { return nil }
        guard let length = scanDouble(), length > 0 else { return nil }
        guard scanCharacter("L") else { return nil }
        return (size.string, length)
    }
    mutating func thinXHeight(_ name: String, unit1: Character? = nil) -> (size: String, length: Double)? {
        guard scanString(name) else { return nil }
        guard var thin = scanStringAsDouble(), thin.value > 0 else { return nil }
        if scanCharacter("/") {
            if let size2 = scanStringAsDouble() {
                thin.string += "/\(size2.string)"
            }
        }
        if let ch = unit1, !scanCharacter(ch) { return nil }
        guard scanCharacters("X", "×", "*") else { return nil }
        guard let height = scanDouble(), height > 0 else { return nil }
        return (thin.string, height)
    }
    
    mutating func scanSize(_ name: String) -> String? {
        guard name.isEmpty || scanString(name) else { return nil }
        guard let size = scanStringAsDouble(), size.value > 0 else { return nil }
        return size.string
    }
    mutating func scanSizeXRXR(_ name: String) -> (size: String, r1: Double, r2: Double)? {
        guard scanString(name) else { return nil }
        guard let size = scanStringAsDouble(), size.value > 0 else { return nil }
        let _ = scanCharacters("T", "t")
        guard scanCharacters("X", "×", "*") else { return nil }
        guard let r1 = scanDouble(), r1 > 0 else { return nil }
        guard scanCharacters("Φ", "φ") else { return nil }
        guard scanCharacters("X", "×", "*") else { return nil }
        guard let r2 = scanDouble(), r2 > 0 else { return nil }
        guard scanCharacters("Φ", "φ") else { return nil }
        return (size.string, r1, r2)
    }
    
    mutating func scanボルト() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("M") else {
            self.reset()
            return nil
        }
        return ("ボルト", .ボルト(サイズ: size, 長さ: length), 140)
    }
    
    mutating func scanFB() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (thin, height) = thinXHeight("FB") else {
            self.reset()
            return nil
        }
        return ("FB", .FB(板厚: thin, 高さ: height), 0)
    }
    
    mutating func scanFBSimple() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let size = scanSize("FB") else {
            self.reset()
            return nil
        }
        return ("FB", .定番FB(板厚: size), 0)
    }
    
    mutating func scanワッシャー() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let size = scanSize("ワッシャー") else {
            self.reset()
            return nil
        }
        return ("ワッシャー", .ワッシャー(サイズ: size), 80)
    }
    
    mutating func scanSワッシャー() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let size = scanSize("Sワッシャー") else {
            self.reset()
            return nil
        }
        return ("Sワッシャー", .Sワッシャー(サイズ: size), 70)
    }
    
    mutating func scan特寸ワッシャー() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let result = self.scanSizeXRXR("特寸ワッシャー") else {
            self.reset()
            return nil
        }
        return ("特寸ワッシャー", 資材種類型.特寸ワッシャー(サイズ: result.size, 外径: result.r1, 内径: result.r2), 71)
    }
    
    mutating func scanナット() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard scanString("ナット") else { return nil }
        guard let size = scanStringAsDouble(), size.value > 0 else {
            self.reset()
            return nil
        }
        return ("ナット", .ナット(サイズ: size.string), 90)
    }
    
    mutating func scan浮かしパイプ() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        if let (size, length) = scanSizeXLength("浮かし", unit1: "Φ") {
            return ("浮かしパイプ", .浮かしパイプ(サイズ: size, 長さ: length), 130)
        }
        self.reset()
        return nil
    }
    
    mutating func scan丸パイプ() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        if let (size, length) = scanSizeXLength("浮かし", unit1: "Φ") {
            return ("浮かしパイプ", .丸パイプ(サイズ: size, 長さ: length), 130)
        }
        self.reset()
        if let (size, length) = scanSizeXLength("配線", unit1: "Φ") {
            return ("配線パイプ", .丸パイプ(サイズ: size, 長さ: length), 120)
        }
        self.reset()
        if let (size, length) = scanSizeXLength("電源用", unit1: "Φ") {
            return ("電源用パイプ", .丸パイプ(サイズ: size, 長さ: length), 100)
        }
        self.reset()
        if let (size, length) = scanSizeXLength("", unit1: "Φ") {
            return ("丸パイプ", .丸パイプ(サイズ: size, 長さ: length), 110)
        }
        self.reset()
        return nil
    }
    
    mutating func scan特皿() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("特皿M") else {
            self.reset()
            return nil
        }
        return ("特皿", .特皿(サイズ: size, 長さ: length), 30)
    }
    
    mutating func scan皿() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("皿M") else {
            self.reset()
            return nil
        }
        return ("皿", .皿(サイズ: size, 長さ: length), 30)
    }
    
    mutating func scanサンロックトラス() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("サンロックトラスM") else {
            self.reset()
            return nil
        }
        return ("サンロックトラス", .サンロックトラス(サイズ: size, 長さ: length), 40)
    }
    
    mutating func scanサンロック特皿() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("サンロック特皿M") else {
            self.reset()
            return nil
        }
        return ("サンロック特皿", .サンロックトラス(サイズ: size, 長さ: length), 20)
    }
    
    mutating func scanトラス() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("トラス") else {
            self.reset()
            return nil
        }
        return ("トラス", .トラス(サイズ: size, 長さ: length), 50)
    }
    
    mutating func scanスリムヘッド() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("スリムヘッドM") else {
            self.reset()
            return nil
        }
        return ("スリムヘッド", .スリムヘッド(サイズ: size, 長さ: length), 10)
    }
    
    mutating func scanCタッピング() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("CタッピングM") else {
            self.reset()
            return nil
        }
        return ("Cタッピング", .Cタッピング(サイズ: size, 長さ: length), 60)
    }
    mutating func scanナベ() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        if let (size, length) = scanSizeXLength("なべM") {
            return ("なべ", .ナベ(サイズ: size, 長さ: length), 61)
        }
        self.reset()
        guard let (size, length) = scanSizeXLength("ナベM") else {
            self.reset()
            return nil
        }
        return ("ナベ", .ナベ(サイズ: size, 長さ: length), 61)
    }
    mutating func scanテクスナベ() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("テクスナベM") else {
            self.reset()
            return nil
        }
        return ("テクスナベ", .テクスナベ(サイズ: size, 長さ: length), 62)
    }
    mutating func scanテクス皿() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("テクス皿M") else {
            self.reset()
            return nil
        }
        return ("テクス皿", .テクス皿(サイズ: size, 長さ: length), 62)
    }
    mutating func scanテクス特皿() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("テクス特皿M") else {
            self.reset()
            return nil
        }
        return ("テクス特皿", .テクス特皿(サイズ: size, 長さ: length), 62)
    }
    mutating func scan片ネジ() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("片ネジM") else {
            self.reset()
            return nil
        }
        return ("片ネジ", .片ネジ(サイズ: size, 長さ: length), 62)
    }
    mutating func scan六角() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("六角M") else {
            self.reset()
            return nil
        }
        return ("六角", .六角(サイズ: size, 長さ: length), 0)
    }
    mutating func scanスタッド() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("スタッドM") ?? scanSizeXLength("CDスタッドM") else {
            self.reset()
            return nil
        }
        return ("スタッド", .スタッド(サイズ: size, 長さ: length), 0)
    }
    mutating func scanストレートスタッド() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("SスタッドM") ?? scanSizeXLength("ストレートスタッドM")  else {
            self.reset()
            return nil
        }
        return ("ストレートスタッド", .ストレートスタッド(サイズ: size, 長さ: length), 0)
    }
    mutating func scanALスタッド() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard let (size, length) = scanSizeXLength("ALスタッドM") else {
            self.reset()
            return nil
        }
        return ("ALスタッド", .ALスタッド(サイズ: size, 長さ: length), 0)
    }
    mutating func scan三角コーナー() -> (名称: String, 種類: 資材種類型, ソート順: Double)? {
        guard self.scanString("三角コーナー") else {
            self.reset()
            return nil
        }
        return ("三角コーナー", .三角コーナー, 0)
    }
}

private let lengthMap: [図番型: Double] = [
    // 285ボルト
    "321": 285, "322": 285, "323": 285, "324": 285,
    "326": 285, "327": 285, "314": 285, "325": 285,
    // ボルト
    "328F": 1000, "329": 1000, "330": 1000, "331": 1000, "333": 1000,
    "332": 1000, "334": 1000, "335": 1000, "2733": 1000,
    // 丸パイプ
    "991070": 4000, "991071": 4000, "991069": 4000, "991072": 4000, "996019": 4000,
    "991073": 4000, "991076": 4000, "996200": 4000, "991082": 4000, "991083": 4000,
    "991085": 4000, "996310": 4000, "996139": 4000, "996085": 4000,
    // フラットバー
]

extension 資材型 {
    public var itemLength: Double? {
        return lengthMap[self.図番]
    }
}
