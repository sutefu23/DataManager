//
//  資材発注キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public func flush資材発注キャッシュ() {
    資材発注キャッシュ型.shared.removeAllCache()
}

struct 資材発注キャッシュKey: Hashable, DMCacheElement, CustomStringConvertible {
    let 図番: 図番型
    var 発注種類: 発注種類型?
    
    var memoryFootPrint: Int { return 図番.memoryFootPrint + MemoryLayout<発注種類型>.stride }
    var description: String {
        return "図番:\(図番), 発注種類:\(発注種類?.description ?? "nil")"
    }
}

struct 資材発注キャッシュData型: DMCacheElement {
    let array: [発注型]
    
    var memoryFootPrint: Int { array.reduce(16) { $0 + $1.memoryFootPrint }}

}

class 資材指定注番発注キャッシュ型: DMDBCache<指定注文番号型, 発注型> {
    static let shared: 資材指定注番発注キャッシュ型 = 資材指定注番発注キャッシュ型(lifeSpan: 1*60*60, nilCache: true) {
        try 発注型.find(指定注文番号: $0).last
    }
}

class 資材発注キャッシュ型: DMDBCache<資材発注キャッシュKey, 資材発注キャッシュData型> {
    static let shared: 資材発注キャッシュ型 = 資材発注キャッシュ型(lifeSpan: 1*60*60, nilCache: true) {
        let list = try 発注型.find(発注種類: $0.発注種類, 資材番号: $0.図番)
        if list.isEmpty { return nil }
        list.forEach { 資材指定注番発注キャッシュ型.shared.regist($0, forKey: $0.指定注文番号) }
        return 資材発注キャッシュData型(array: list)
    }
    
    func 現在発注一覧(図番: 図番型, 発注種類: 発注種類型? = .資材) throws -> [発注型] {
        let key = 資材発注キャッシュKey(図番: 図番, 発注種類: 発注種類)
        return try find(key, noCache: true)?.array ?? []
    }
    
    func キャッシュ発注一覧(図番: 図番型, 発注種類: 発注種類型? = .資材) throws -> [発注型] {
        let key = 資材発注キャッシュKey(図番: 図番, 発注種類: 発注種類)
        return try find(key, noCache: false)?.array ?? []
    }

    func flushCache(図番: 図番型) {
        var key = 資材発注キャッシュKey(図番: 図番, 発注種類: nil)
        self.removeCache(forKey: key)
        for type in 発注種類型.allCases {
            key.発注種類 = type
            self.removeCache(forKey: key)
        }
    }

}
