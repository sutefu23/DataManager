//
//  資材（パイプ情報）.swift
//  DataManager
//
//  Created by manager on 2020/06/01.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 資材パイプ種類型 {
    case 角
}

public enum 資材パイプ仕上型 {
    case D
    case HL
    case F
}

public struct 資材パイプ情報型: 資材情報型 {
    public let 仕上: 資材パイプ仕上型 // F
    public let 種類: 資材パイプ種類型
    public let 板厚: String // 0.8t
    public let サイズ: String // "13角"
    public let 長さ: String // "4"
    public let ボルト等表示: String

    public init(製品名称: String, 規格: String) {
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
    }
}

let 資材パイプリスト: [(図番型, 資材パイプ情報型)] = {
    let bundle = Bundle.dataManagerBundle
    let url = bundle.url(forResource: "角パイプ一覧", withExtension: "csv")!
    let text = try! TextReader(url: url, encoding: .utf8)
    let list: [(図番型, 資材パイプ情報型)] = text.lines.compactMap {
        let cols = $0.split(separator: ",")
        if cols.isEmpty { return nil }
        assert(cols.count == 2)
        let info = 資材パイプ情報型(製品名称: "", 規格: String(cols[0]))
        return (String(cols[1]), info)
    }
    return list
}()
