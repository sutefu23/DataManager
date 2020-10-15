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
}

public enum 資材パイプ仕上型: String {
    case D
    case HL
    case F
}

public struct 資材パイプ情報型 {
    public let 図番: 図番型
    public let 社名先頭1文字: String
    public let 仕上: 資材パイプ仕上型 // F
    public let 種類: 資材パイプ種類型
    public let 板厚: String // 0.8t
    public let サイズ: String // "13角"
    public let 長さ: String // "4"
    public let ボルト等表示: String
    
    public var 分割表示名1: String {
        return ボルト等表示 // TODO: 仮設定により、表示内容確認
    }
    public var 分割表示名2: String {
        return "" // TODO: 仮設定により、表示内容確認
    }

    public init(図番: 図番型, 規格: String) {
        self.図番 = 図番
        let str = 規格.toJapaneseNormal.replacingOccurrences(of: "×", with: "x")
        self.ボルト等表示 = str
        var scanner = DMScanner(str, normalizedFullHalf: true, upperCased: true, skipSpaces: true, newlineToSpace: false)
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
        // 板厚
        guard let thin = scanner.scanUpTo("T"), Double(thin) != nil else { fatalError() }
        self.板厚 = thin
        // サイズ
        if let size = scanner.scanUpTo("角") {
            self.種類 = .角
            self.サイズ = size
            self.長さ = scanner.string
        } else {
            let digs = scanner.string.split(separator: "X")
            if digs.count == 3 {
                self.種類 = .角
                self.サイズ = "\(digs[0])×\(digs[1])"
                self.長さ = "\(digs[2])"
            } else {
                fatalError()
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

public let 資材パイプリスト: [資材パイプ情報型] = {
    let bundle = Bundle.dataManagerBundle
    let url = bundle.url(forResource: "角パイプ一覧", withExtension: "csv")!
    let text = try! TextReader(url: url, encoding: .utf8)
    let list: [資材パイプ情報型] = text.lines.compactMap {
        let cols = $0.split(separator: ",")
        if cols.isEmpty { return nil }
        assert(cols.count == 2)
        let info = 資材パイプ情報型(図番: String(cols[1]), 規格: String(cols[0]))
        return info
    }
    return list
}()
