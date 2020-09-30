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
    case 半角カナ濁点
}

let 全角ASCIIto半角ASCIIMap: [Character: Character] = {
    var map: [Character: Character] = [:]
    return map
}()

let 半角カナto全角仮名Map: [String: Character] = {
    var map: [String: Character] = [:]
    let bundle = Bundle(for: TextReader.self)
    let url = bundle.url(forResource: "全角カナto半角カナ", withExtension: "txt")!
    let reader = try! TextReader(url: url, encoding: .utf8)
    
    return map
}()

func convertTo半角ASCII(全角ASCII from: Character) -> Character {
    return from
}

func convertTo全角仮名(半角カナ文字 from: String) -> Character {
    return from.first!
}

extension Character {
    var 文字種類: 文字種類型 {
        return .通常
    }
}
