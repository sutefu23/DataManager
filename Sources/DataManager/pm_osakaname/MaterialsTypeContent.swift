//
//  資材種類内容.swift
//  DataManager
//
//  Created by manager on 2021/09/30.
//

import Foundation

struct 資材種類内容型: Hashable, DMCacheElement {
    
    let ボルト等種類: Set<選択ボルト等種類型>?
    let 旧図番: Set<図番型>?
    
    static func ==(left: 資材種類内容型, right: 資材種類内容型) -> Bool {
        return left.ボルト等種類 == right.ボルト等種類 && left.旧図番 == right.旧図番
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.ボルト等種類)
        hasher.combine(self.旧図番)
    }
    
    var memoryFootPrint: Int { return 16 }
    
    init(種類: String) {
        if 種類.isEmpty {
            self.ボルト等種類 = nil
            self.旧図番 = nil
            return
        }
        var ボルト等種類: Set<選択ボルト等種類型> = []
        var 旧図番: Set<図番型> = []

        func appendType(_ type: String) {
            guard let type = 選択ボルト等種類型(rawValue: type)  else { return }
            ボルト等種類.insert(type)
        }
        func appendNumber(_ number: String) {
            guard !number.isEmpty else { return }
            旧図番.insert(number)
        }
        
        var scanner = DMScanner(種類, normalizedFullHalf: true, skipSpaces: true, newlineToSpace: true)
        scanner.dropTailSpaces()
        
        while let (left, number) = scanner.scanParen("[", "]") {
            旧図番.insert(number)
            var typeScanner = DMScanner(left, skipSpaces: true)
            typeScanner.dropTailSpaces()
            while !typeScanner.isAtEnd {
                guard let typename = typeScanner.scanUpTo(",") else { break }
                appendType(typename)
            }
        }
        while let typename = scanner.scanUpTo(",") {
            appendType(typename)
        }
        appendType(scanner.string)
        self.ボルト等種類 = ボルト等種類.isEmpty ? nil : ボルト等種類
        self.旧図番 = 旧図番.isEmpty ? nil : 旧図番
    }
}
