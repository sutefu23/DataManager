//
//  DMCharacterMap.swift
//  DataManager
//
//  Created by manager on 2020/09/25.
//

import Foundation

enum 文字種類型 {
    case 通常
    case 全角ASCII
    case 半角カナ
}

let 全角ASCIIto半角ASCIIMap: [Character: Character] = {
    var map: [Character: Character] = [:]
    let bundle = Bundle(for: TextReader.self)
    let url = bundle.url(forResource: "全角ASCIIto半角ASCII", withExtension: "txt")!
    let reader = try! TextReader(url: url, encoding: .utf8)
     while let line = reader.nextLine() {
        let digs = line.split(separator: "\t")
        if digs.count != 2 { continue }
        let zenkaku = digs[0].first!
        let hankaku = digs[1].first!
        map[zenkaku] = hankaku
    }
    return map
}()

let 半角カナto全角仮名Map: [Character: Character] = {
    var map: [Character: Character] = [:]
    let bundle = Bundle(for: TextReader.self)
    let url = bundle.url(forResource: "全角カナto半角カナ", withExtension: "txt")!
    let reader = try! TextReader(url: url, encoding: .utf8)
     while let line = reader.nextLine() {
        let digs = line.split(separator: "\t")
        if digs.count != 2 { continue }
        let zenkaku = digs[0].first!
        let hankaku = digs[1].first!
        map[hankaku] = zenkaku
    }
    return map
}()

let 全角ASCIISet = Set<Character>(全角ASCIIto半角ASCIIMap.keys)
let 半角カナSet = Set<Character>(半角カナto全角仮名Map.keys)

func convertTo半角ASCII(全角ASCII from: Character) -> Character {
    return 全角ASCIIto半角ASCIIMap[from] ?? from
}

func convertTo全角仮名(半角カナ文字 from: Character) -> Character {
    return 半角カナto全角仮名Map[from] ?? from
}

extension Character {
    var 文字種類: 文字種類型 {
        if 全角ASCIISet.contains(self) { return .全角ASCII }
        if 半角カナSet.contains(self) { return .半角カナ }
        return .通常
    }
}
