//
//  資材（パイプ情報）.swift
//  DataManager
//
//  Created by manager on 2020/06/01.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 資材パイプ種類型: String {
    case 角
    case 丸
    case FB
}

public enum 資材パイプ仕上型: String {
    case D
    case HL
    case F
    case CO2C
    case CO
    case HO
    case 仕上げなし
    
    public var caption: String {
        switch self {
        case .仕上げなし:
            return ""
        default:
            return self.rawValue
        }
    }
}

public enum 資材パイプ材質型: String {
    case SUS
    case BSP
    case CUP
    case アルミ
}

public struct 資材パイプ情報型 {
    public let 図番: 図番型
    public let 社名先頭1文字: String
    public let 仕上: 資材パイプ仕上型 // F
    public let 材質: 資材パイプ材質型
    public let 種類: 資材パイプ種類型
    public let 板厚: String // 0.8t
    public let サイズ: String // "13角"
    public let 長さ: String // "4"
    public let ボルト等表示: String
    let カット用チェック名: String?
    
    public var 仕上げ材質表示: String {
        switch self.仕上 {
        case .仕上げなし:
            return self.材質.rawValue
        default:
            return self.仕上.rawValue
        }
    }
    
    public var 分割表示名1: String {
        return ボルト等表示 // TODO: 仮設定により、表示内容確認
    }
    public var 分割表示名2: String {
        return "" // TODO: 仮設定により、表示内容確認
    }

    public init(図番: 図番型, 規格: String) {
        self.図番 = 図番
        let str = 規格.toJapaneseNormal.replacingOccurrences(of: "×", with: "x").spaceStripped
        if let index = str.lastIndex(where: {$0 == "x" }) {
            self.カット用チェック名 = str[...index].toJapaneseNormal.spaceStripped.uppercased()
        } else {
            self.カット用チェック名 = nil
        }
        self.ボルト等表示 = str
        var scanner = DMScanner(str, normalizedFullHalf: true, upperCased: true, skipSpaces: true, newlineToSpace: false)
        if scanner.scanString("FB") { // FB
            // 種類
            self.種類 = .FB
            // 材質
            if scanner.scanString("SUS") {
                self.材質 = .SUS
            } else if scanner.scanString("BSP") {
                self.材質 = .BSP
            } else if scanner.scanString("CUP") {
                self.材質 = .CUP
            } else if scanner.scanString("アルミ") {
                self.材質 = .アルミ
            } else {
                fatalError()
            }
            // 仕上げ
            if scanner.scanString("D") {
                self.仕上 = .D
            } else if scanner.scanString("HL") {
                self.仕上 = .HL
            } else if scanner.scanString("F") {
                self.仕上 = .F
            } else if scanner.scanString("CO2C") {
                self.仕上 = .CO2C
            } else if scanner.scanString("CO") {
                self.仕上 = .CO
            } else if scanner.scanString("HO") {
                self.仕上 = .HO
            } else {
                self.仕上 = .仕上げなし
            }
            // 板厚
            guard let thin = scanner.scanUpTo("T"), Double(thin) != nil else { fatalError() }
            self.板厚 = thin
            let digs = scanner.string.split(separator: "X")
            switch digs.count {
            case 2:
                self.サイズ = "\(digs[0])"
                self.長さ = "\(digs[1])"
            case 3:
                self.サイズ = "\(digs[0])x\(digs[1])"
                self.長さ = "\(digs[2])"
            default:
                fatalError()
            }
        } else { // 角・丸
            // 仕上げ
            if scanner.scanString("D") {
                self.仕上 = .D
            } else if scanner.scanString("HL") {
                self.仕上 = .HL
            } else if scanner.scanString("F") {
                self.仕上 = .F
            } else {
                fatalError()
            }
            // 材質
            self.材質 = .SUS
            // 板厚
            guard let thin = scanner.scanUpTo("T"), Double(thin) != nil else { fatalError() }
            self.板厚 = thin
            // サイズ
            if let size = scanner.scanUpTo("角") {
                self.種類 = .角
                self.サイズ = size
                self.長さ = scanner.string
            } else if let size = scanner.scanUpTo("Φ") {
                self.種類 = .丸
                self.サイズ = size
                self.長さ = scanner.string
            } else {
                let digs = scanner.string.split(separator: "X")
                if digs.count == 3 {
                    self.種類 = .角
                    self.サイズ = "\(digs[0])x\(digs[1])"
                    self.長さ = "\(digs[2])"
                } else {
                    fatalError()
                }
            }
        }
        // 先頭１文字社名
        if let item = 資材型(図番: 図番) {
            if let ch = item.発注先名称.remove㈱㈲.first {
                self.社名先頭1文字 = String(ch)
            } else {
                self.社名先頭1文字 = ""
            }
        } else {
            self.社名先頭1文字 = "?"
        }
    }
}

func searchボルト等パイプ(ボルト欄: String) -> 資材パイプ情報型? {
    資材パイプリスト.first { $0.ボルト等表示 == ボルト欄 }
}

func searcボルト欄パイプ等カット(ボルト欄: String) -> (info: 資材パイプ情報型, 全長: Double, 長さ: Double)? {
    var scanner = DMScanner(ボルト欄.replacingOccurrences(of: "×", with: "X"), upperCased: true)
    for info in カット可能資材パイプリスト {
        guard let header = info.カット用チェック名, !header.isEmpty, let itemLength = Double(info.長さ), itemLength > 0 else { continue }
        if scanner.scanString(header), let length = scanner.scanDouble(), scanner.isAtEnd {
            return (info, itemLength * 1000, length)
        }
        scanner.reset()
    }
    return nil
}

public let 資材パイプリスト: [資材パイプ情報型] = {
    let list = ["FB一覧", "角パイプ一覧", "丸パイプ一覧"].concurrentMap {
        makeList($0)
    }.flatMap { $0 }
    return list
}()

let カット可能資材パイプリスト: [資材パイプ情報型] = {
    let 図番Set: Set<String> = ["991689", "991226", "991228", "991690", "991351", "883428", "883563", "991366", "883430"]
    let list = 資材パイプリスト.filter { 図番Set.contains($0.図番) && $0.カット用チェック名?.isEmpty == false }
    return list
}()

private func makeList(_ name: String) -> [資材パイプ情報型] {
    let bundle = Bundle.dataManagerBundle
    let url = bundle.url(forResource: name, withExtension: "csv")!
    let text = try! TextReader(url: url, encoding: .utf8)
    let list: [資材パイプ情報型] = text.lines.concurrentCompactMap {
        let cols = $0.split(separator: ",")
        if cols.isEmpty { return nil }
        assert(cols.count == 2)
        let info = 資材パイプ情報型(図番: String(cols[1]), 規格: String(cols[0]))
        return info
    }
    return list
}
