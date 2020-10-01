//
//  DMCharacterMap.swift
//  DataManager
//
//  Created by manager on 2020/09/25.
//

import Foundation

extension StringProtocol {
    /// 記号英数半角、仮名全角に揃える（横棒は直前の文字が全角なら全角、半角なら半角になる）
    public var toJapaneseNormal: String {
        var result = ""
        var halfMode = true
        for ch in self {
            if ch == "ー" || ch == "-" { // 全角横棒・半角ASCIIハイフン
                if halfMode {
                    result.append("-")
                } else {
                    result.append("ー")
                }
            } else if ch.isASCII {
                result.append(ch)
                halfMode = true
            } else if let ch = 全角ASCIIto半角ASCIIMap[ch] {
                result.append(ch)
                halfMode = true
            } else if let ch = 半角カナto全角仮名Map[ch] {
                result.append(ch)
                halfMode = false
            } else {
                result.append(ch)
                halfMode = false
            }
        }
        return result
    }
}

private var bundle: Bundle {
    #if os(Linux)
    let bundle = Bundle.module
    #else
    let bundle = Bundle(for: TextReader.self)
    #endif
    return bundle
}

let 全角ASCIIto半角ASCIIMap: [Character: Character] = {
    var map: [Character: Character] = [:]
    let url = bundle.url(forResource: "全角ASCIIto半角ASCII", withExtension: "txt")!
    let reader = try! TextReader(url: url, encoding: .utf8)
     while let line = reader.nextLine() {
        if line.isEmpty { continue }
        let digs = line.split(separator: "\t")
        assert(digs.count == 2)
        let zenkaku = digs[0].first!
        let hankaku = digs[1].first!
        map[zenkaku] = hankaku
        let str1 = String(zenkaku).applyingTransform(.fullwidthToHalfwidth, reverse: false)
        let str2 = String(hankaku)
        assert(str1 == str2)
    }
    return map
}()

let 半角カナto全角仮名Map: [Character: Character] = {
    var map: [Character: Character] = [:]
    let url = bundle.url(forResource: "全角カナto半角カナ", withExtension: "txt")!
    let reader = try! TextReader(url: url, encoding: .utf8)
     while let line = reader.nextLine() {
        if line.isEmpty { continue }
        let digs = line.split(separator: "\t")
        assert(digs.count == 2)
        let zenkaku = digs[0].first!
        let hankaku = digs[1].first!
        map[hankaku] = zenkaku
        let str1 = String(zenkaku).applyingTransform(.fullwidthToHalfwidth, reverse: false)
        let str2 = String(hankaku)
        assert(str1 == str2)
    }
    return map
}()
