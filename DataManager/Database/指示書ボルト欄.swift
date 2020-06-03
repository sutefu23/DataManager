//
//  指示書ボルト欄.swift
//  DataManager
//
//  Created by manager on 2020/05/13.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum ボルト数欄型 {
    case 合計(Int)
    case 分納(Int, Int)
    
    public init?(ボルト数欄: String, セット数: Int) {
        var scanner = DMScanner(ボルト数欄, normalizedFullHalf: true, upperCased: true, skipSpaces: true)
        guard let number = scanner.scanInteger() else { return nil }
        if scanner.scanCharacter("+") {
            guard let number2 = scanner.scanInteger() else { return nil }
            self = .合計((number+number2) * セット数)
        } else if scanner.scanCharacter("/") {
            guard let number2 = scanner.scanInteger() else { return nil }
            self = .分納(number * セット数, number2 * セット数)
        } else {
            self = .合計(number * セット数)
        }
    }
    
    public var 総数: Int {
        switch self {
        case .合計(let num):
            return num
        case .分納(let left, let right):
            return left + right
        }
    }
    
    public var 溶接数: Int? {
        switch self {
        case .分納(let left, _):
            return left
        case .合計(_):
            return nil
        }
    }
    
    public var 半田数: Int? {
        switch self {
        case .分納(_,let right):
            return right
        case .合計(_):
            return nil
        }
    }
}

public enum 金額計算タイプ型 {
    case 平面板(height: Double, width: Double, count: Int)
    case 平面形状(area: Double, count: Int)
    case カット棒(itemLength: Double, length: Double, count: Int)
    case 個数物(count: Int)
    case コイル材(weight: Double)
    
    public var area: Double? {
        switch self {
        case .平面板(height: let height, width: let width, let count):
            return height * width * Double(count)
        case .平面形状(area: let area, let count):
            return area * Double(count)
        default:
            return nil
        }
    }
    
    public func 分量(資材 item: 資材型) -> Double {
        switch self {
        case .カット棒(itemLength: let itemLength, length: let length, count: _):
            return length / itemLength
        case .コイル材(weight: let weight):
            return weight / 43.0
        case .個数物(count: _):
            return 1.0
        case .平面形状(area: let area, count: _):
            if let sheetArea = 資材板情報型(item).面積 {
                return area / sheetArea
            }
        case .平面板(height: let height, width: let width, count: _):
            if let sheetArea = 資材板情報型(item).面積 {
                let area = width * height
                return area / sheetArea
            }
        }
        return 0
    }
    
    public func makeData(資材 item: 資材型) -> (使用量: String, 使用面積: Double?, 金額: Double?) {
        var value: Double? = nil
        switch self {
        case .カット棒(itemLength: let itemLength, length: let length, count: let count):
            if let price = item.単価 {
                value = (length / itemLength) * price * Double(count)
            }
            return ("\(length)mm \(count)本", nil, value)
        case .コイル材(weight: let weight):
            if let price = item.単価 {
                value = (weight / 43.0) * price
            }
            return ("\(weight)kg", nil, value)
        case .個数物(count: let count):
            if let price = item.単価 {
                value = price * Double(count)
            }
            return ("\(count)個", nil, value)
        case .平面形状(area: let area, count: let count):
            if let price = item.単価, let sheetArea = 資材板情報型(item).面積 {
                value = (area / sheetArea) * price
            }
            return ("\(area)㎟ \(count)個", area, value)
        case .平面板(height: let height, width: let width, count: let count):
            if let price = item.単価, let sheetArea = 資材板情報型(item).面積 {
                let area = width * height
                value = (area / sheetArea) * price
            }
            return ("\(height)x\(width) \(count)枚", area, value)
        }
    }
}

public class 資材要求情報型 {
    public let 図番: 図番型
    public let 金額計算タイプ: 金額計算タイプ型?
    public let 表示名: String
    public let 分割表示名1: String
    public let 分割表示名2: String
    public let ソート順: Int
    public let 資材種類: 資材種類型?
    public let ボルト数量:ボルト数欄型?

    public lazy var 資材: 資材型? = 資材型(図番: self.図番)
    public lazy var 単価: Double? = self.資材?.単価
    public var 金額: Double? {
        guard let item = self.資材 else { return nil }
        let data = 金額計算タイプ?.makeData(資材: item)
        return data?.金額
    }

    public var 使用量: String? {
        guard let item = self.資材 else { return nil }
        let data = 金額計算タイプ?.makeData(資材: item)
        return data?.使用量
    }
    public var 使用面積: Double? {
        guard let item = self.資材 else { return nil }
        let data = 金額計算タイプ?.makeData(資材: item)
        return data?.使用面積
    }
    
    public func checkRegistered(_ order: 指示書型, _ process: 工程型) throws -> Bool {
        guard let list = try order.キャッシュ資材使用記録() else { return false }
        if list.contains(where: { $0.図番 == self.図番 && $0.工程 == process && $0.表示名 == self.表示名 }) {
            return true
        }
//        guard let list2 = try order.現在資材使用記録() else { return false }
//        if list2.contains(where: { $0.図番 == self.図番 && $0.工程 == process && $0.表示名 == self.表示名 }) {
//            return true
//        }
        return false
    }
    
    public init?(ボルト欄: String, 数量欄: String, セット数: Int) {
        self.表示名 = ボルト欄
        guard let (title, size, type, priority) = scanSource(ボルト欄: ボルト欄) else { return nil }
        self.ソート順 = priority
        self.分割表示名1 = title
        self.分割表示名2 = size
        self.資材種類 = type
        let set = (セット数 >= 1) ? セット数 : 1
        guard let numbers = ボルト数欄型(ボルト数欄: 数量欄, セット数: set) else { return nil }
        self.ボルト数量 = numbers
        let count = numbers.総数
        assert(count > 0)
        switch type {
        case .ボルト(サイズ: let size, 長さ: let length):
            let itemLength: Double
            if length == 285 {
                itemLength = 285
                switch Double(size) {
                case  4: self.図番 = "321"
                case  5: self.図番 = "322"
                case  6: self.図番 = "323"
                case  8: self.図番 = "324"
                case 10: self.図番 = "326"
                case 12: self.図番 = "327"
                case 16: self.図番 = "314"
                default:
                    switch size {
                    case "3/8": self.図番 = "325"
                    default:
                        return nil
                    }
                }
            } else if length == 360 {
                itemLength = 360
                switch Double(size) {
                case 16: self.図番 = "949"
                default:
                    return nil
                }
            } else {
                itemLength = 1000
                switch Double(size) {
                case  3: self.図番 = "328I"
                case  4: self.図番 = "329"
                case  5: self.図番 = "330"
                case  6: self.図番 = "331"
                case  8: self.図番 = "332"
                case 10: self.図番 = "334"
                case 12: self.図番 = "335"
                case 16: self.図番 = "2733"
                default:
                    switch size {
                    case "3/8": self.図番 = "333"
                    default:
                        return nil
                    }
                }
            }
            self.金額計算タイプ = .カット棒(itemLength: itemLength, length: length, count: count)
        case .ナット(サイズ: let size):
            switch Double(size) {
            case  3: self.図番 = "363"
            case  4: self.図番 = "364"
            case  5: self.図番 = "365"
            case  6: self.図番 = "366"
            case  8: self.図番 = "367"
            case 10: self.図番 = "389"
            case 12: self.図番 = "370"
            default:
                switch size {
                case "3/8": self.図番 = "368"
                default:
                    return nil
                }
            }
            self.金額計算タイプ = .個数物(count: count)
        case .ワッシャー(サイズ: let size):
            switch Double(size) {
            case  3: self.図番 = "381"
            case  4: self.図番 = "382"
            case  5: self.図番 = "383"
            case  6: self.図番 = "384"
            case  8: self.図番 = "385"
            case 10: self.図番 = "386"
            case 12: self.図番 = "387"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .Sワッシャー(サイズ: let size):
            switch Double(size) {
            case  5: self.図番 = "391"
            case  6: self.図番 = "392"
            case  8: self.図番 = "393"
            case 10: self.図番 = "396"
            case 12: self.図番 = "395"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .丸パイプ(サイズ: let size, 長さ: let length):
            switch Double(size) {
            case 5: self.図番 = "991070"
            case 6: self.図番 = "991071"
            case 7: self.図番 = "991069"
            case 8: self.図番 = "991072"
            case 9: self.図番 = "996019"
            case 10: self.図番 = "991073"
            case 12: self.図番 = "991076"
            case 13: self.図番 = "996200"
            case 14: self.図番 = "991768"
            case 15: self.図番 = "991082"
            case 16: self.図番 = "991083"
            case 19: self.図番 = "991085"
            case 21.7: self.図番 = "996310"
            case 22: self.図番 = "996139"
            case 25: self.図番 = "996085"
            default: return nil
            }
            let itemLength: Double = 4000
            self.金額計算タイプ = .カット棒(itemLength: itemLength, length: length, count: count)
        case .Cタッピング(サイズ: let size, 長さ: let length):
            switch (Double(size), length) {
            case (4, 6): self.図番 = "996585"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .サンロックトラス(サイズ: let size, 長さ: let length):
            switch (Double(size), length) {
            case (4, 6): self.図番 = "991680"
            case (4, 8): self.図番 = "991681"
            case (4, 10): self.図番 = "5827"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .サンロック特皿(サイズ: let size, 長さ: let length):
            switch (Double(size), length) {
            case (2, 5): self.図番 = "7277"
            case (4, 10): self.図番 = "5790"
            case (4, 6): self.図番 = "5922"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .特皿(サイズ: let size, 長さ: let length):
            switch (Double(size), length) {
            case (3, 6): self.図番 = "5020"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .トラス(サイズ: let size, 長さ: let length):
            switch (Double(size), length) {
            case (3, 10): self.図番 = "580"
            case (4, 6): self.図番 = "39592"
            case (5, 10): self.図番 = "582"
            case (5, 15): self.図番 = "2569"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .スリムヘッド(サイズ: let size, 長さ: let length):
            switch (Double(size), length) {
            case (4, 6): self.図番 = "9799"
            case (4, 8): self.図番 = "7276"
            case (4, 10): self.図番 = "9699"
            case (3, 6): self.図番 = "6711F"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .ナベ(サイズ: let size, 長さ: let length):
            switch (Double(size), length) {
            case (4, 10): self.図番 = "3829"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        case .テクスナベ(サイズ: let size, 長さ: let length):
            switch (Double(size), length) {
            case (4, 19): self.図番 = "7275"
            default: return nil
            }
            self.金額計算タイプ = .個数物(count: count)
        }
    }
}
public func sortCompare(_ left: 資材要求情報型, _ right: 資材要求情報型) -> Bool {
    if left.ソート順 != right.ソート順 { return left.ソート順 < right.ソート順 }
    if left.分割表示名1 != right.分割表示名1 { return left.分割表示名1 < right.分割表示名2 }
    if left.分割表示名2 != right.分割表示名2 { return left.分割表示名1 < right.分割表示名2 }
    return false
}

func scanSource(ボルト欄: String) -> (名称: String, サイズ: String, 種類: 資材種類型, ソート順: Int)? {
    var scanner = DMScanner(ボルト欄, normalizedFullHalf: true, upperCased: true, skipSpaces: true)
    func makeTail(_ data: (名称: String, 種類: 資材種類型, ソート順: Int)) -> (名称: String, サイズ: String, 種類: 資材種類型, ソート順: Int) {
        scanner.reset()
        scanner.skipMatchString(data.名称)
        return (data.名称, scanner.string, data.種類, data.ソート順)
    }

    if let data = scanner.scanボルト() { return makeTail(data) }
    if let data = scanner.scanワッシャー() { return makeTail(data) }
    if let data = scanner.scanSワッシャー() { return makeTail(data) }
    if let data = scanner.scanナット() { return makeTail(data) }
    if let data = scanner.scan丸パイプ() { return makeTail(data) }
    if let data = scanner.scan特皿() { return makeTail(data) }
    if let data = scanner.scanサンロックトラス() { return makeTail(data) }
    if let data = scanner.scanサンロック特皿() { return makeTail(data) }
    if let data = scanner.scanトラス() { return makeTail(data) }
    if let data = scanner.scanスリムヘッド() { return makeTail(data) }
    if let data = scanner.scanCタッピング() { return makeTail(data) }
    if let data = scanner.scanナベ() { return makeTail(data) }
    if let data = scanner.scanテクスナベ() { return makeTail(data) }
    return nil
}

public enum 資材種類型 {
    case ボルト(サイズ: String, 長さ: Double)
    case ワッシャー(サイズ: String)
    case Sワッシャー(サイズ: String)
    case ナット(サイズ: String)
    case 丸パイプ(サイズ: String, 長さ: Double)
    case 特皿(サイズ: String, 長さ: Double)
    case サンロックトラス(サイズ: String, 長さ: Double)
    case サンロック特皿(サイズ: String, 長さ: Double)
    case トラス(サイズ: String, 長さ: Double)
    case スリムヘッド(サイズ: String, 長さ: Double)
    case Cタッピング(サイズ: String, 長さ: Double)
    case ナベ(サイズ: String, 長さ: Double)
    case テクスナベ(サイズ: String, 長さ: Double)

    public func 数量調整(_ count: Int) -> Int {
        let offset: [Int]
        switch self {
        case .ボルト(_, _):
            offset = [1, 2, 3, 3, 3, 5, 5, 6]
        case .丸パイプ(_, _):
            offset = [1, 2, 3, 3, 3, 5, 5, 6]
        case .スリムヘッド(_, _), .トラス(_, _), .サンロックトラス(_, _), .サンロック特皿(_, _), .特皿(_, _), .Cタッピング(_, _), .ナベ(_, _), .テクスナベ(_, _):
            offset = [2, 3, 3, 5, 10, 10, 10, 20]
        case .ナット(_):
            offset = [2, 3, 3, 5, 10, 10, 10, 15]
        case .ワッシャー(_), .Sワッシャー(_):
            offset = [2, 3, 3, 5, 10, 10, 10, 15]
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
    }
    
}

private extension DMScanner {
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
    
    mutating func scanSize(_ name: String) -> String? {
        guard name.isEmpty || scanString(name) else { return nil }
        guard let size = scanStringAsDouble(), size.value > 0 else { return nil }
        return size.string
    }
    
    mutating func scanボルト() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("M") else {
            self.reset()
            return nil
        }
        return ("ボルト", .ボルト(サイズ: size, 長さ: length), -140)
    }
    
    mutating func scanワッシャー() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let size = scanSize("ワッシャー") else {
            self.reset()
            return nil
        }
        return ("ワッシャー", .ワッシャー(サイズ: size), -80)
    }
    
    mutating func scanSワッシャー() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let size = scanSize("Sワッシャー") else {
            self.reset()
            return nil
        }
        return ("Sワッシャー", .Sワッシャー(サイズ: size), -70)
    }
    
    mutating func scanナット() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard scanString("ナット") else { return nil }
        guard let size = scanStringAsDouble(), size.value > 0 else {
            self.reset()
            return nil
        }
        return ("ナット", .ナット(サイズ: size.string), -90)
    }
    
    mutating func scan丸パイプ() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        if let (size, length) = scanSizeXLength("浮かし", unit1: "Φ") {
            return ("浮かしパイプ", .丸パイプ(サイズ: size, 長さ: length), -130)
        }
        self.reset()
        if let (size, length) = scanSizeXLength("配線", unit1: "Φ") {
            return ("配線パイプ", .丸パイプ(サイズ: size, 長さ: length), -120)
        }
        self.reset()
        if let (size, length) = scanSizeXLength("電源用", unit1: "Φ") {
            return ("電源用パイプ", .丸パイプ(サイズ: size, 長さ: length), -100)
        }
        self.reset()
        if let (size, length) = scanSizeXLength("", unit1: "Φ") {
            return ("丸パイプ", .丸パイプ(サイズ: size, 長さ: length), -110)
        }
        self.reset()
        return nil
    }
    
    mutating func scan特皿() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("特皿M") else {
            self.reset()
            return nil
        }
        return ("特皿", .特皿(サイズ: size, 長さ: length), -30)
    }
    
    mutating func scanサンロックトラス() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("サンロックトラスM") else {
            self.reset()
            return nil
        }
        return ("サンロックトラス", .サンロックトラス(サイズ: size, 長さ: length), -40)
    }
    
    mutating func scanサンロック特皿() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("サンロック特皿M") else {
            self.reset()
            return nil
        }
        return ("サンロック特皿", .サンロックトラス(サイズ: size, 長さ: length), -20)
    }
    
    mutating func scanトラス() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("トラス") else {
            self.reset()
            return nil
        }
        return ("トラス", .トラス(サイズ: size, 長さ: length), -50)
    }
    
    mutating func scanスリムヘッド() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("スリムヘッドM") else {
            self.reset()
            return nil
        }
        return ("スリムヘッド", .スリムヘッド(サイズ: size, 長さ: length), -10)
    }
    
    mutating func scanCタッピング() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("CタッピングM") else {
            self.reset()
            return nil
        }
        return ("Cタッピング", .Cタッピング(サイズ: size, 長さ: length), -60)
    }
    mutating func scanナベ() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("ナベM") else {
            self.reset()
            return nil
        }
        return ("ナベ", .ナベ(サイズ: size, 長さ: length), -60)
    }
    mutating func scanテクスナベ() -> (名称: String, 種類: 資材種類型, ソート順: Int)? {
        guard let (size, length) = scanSizeXLength("テクスナベM") else {
            self.reset()
            return nil
        }
        return ("テクスナベ", .テクスナベ(サイズ: size, 長さ: length), -60)
    }
}

private let lengthMap: [図番型: Double] = [
    // 285ボルト
    "321": 285, "322": 285, "323": 285, "324": 285,
    "326": 285, "327": 285, "314": 285, "325": 285,
    // ボルト
    "328I": 1000, "329": 1000, "330": 1000, "331": 1000, "333": 1000,
    "332": 1000, "334": 1000, "335": 1000, "2733": 1000,
    // 丸パイプ
    "991070": 4000, "991071": 4000, "991069": 4000, "991072": 4000, "996019": 4000,
    "991073": 4000, "991076": 4000, "996200": 4000, "991082": 4000, "991083": 4000,
    "991085": 4000, "996310": 4000, "996139": 4000, "996085": 4000,
]

extension 資材型 {
    public var itemLength: Double? {
        return lengthMap[self.図番]
    }
}
