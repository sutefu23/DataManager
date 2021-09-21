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

struct 資材発注キャッシュKey: Hashable, DMCacheElement {
    let 図番: 図番型
    var 発注種類: 発注種類型?
    
    var memoryFootPrint: Int { return 図番.memoryFootPrint + MemoryLayout<発注種類型>.stride }
}

struct 資材発注キャッシュData型: DMCacheElement {
    let array: [発注型]
    
    var memoryFootPrint: Int { array.reduce(16) { $0 + $1.memoryFootPrint }}

}

class 資材発注キャッシュ型: DMDBCache<資材発注キャッシュKey, 資材発注キャッシュData型> {
    static let shared: 資材発注キャッシュ型 = 資材発注キャッシュ型(lifeTime: 1*60*60) {
        let list = try 発注型.find(発注種類: $0.発注種類, 資材番号: $0.図番)
        if list.isEmpty { return nil }
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

/*
final class 資材発注キャッシュ型 {
    static let shared = 資材発注キャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [資材発注キャッシュKey: (有効期限: Date, 一覧: [発注型])] = [:]
    
    func 現在発注一覧(図番: 図番型, 発注種類: 発注種類型? = .資材) throws -> [発注型] {
        let key = 資材発注キャッシュKey(図番: 図番, 発注種類: 発注種類)
        let list = try 発注型.find(発注種類: 発注種類, 資材番号: 図番)
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[key] = (expire, list)
        lock.unlock()
        return list
    }
    
    func キャッシュ発注一覧(図番: 図番型, 発注種類: 発注種類型? = .資材) throws -> [発注型] {
        let key = 資材発注キャッシュKey(図番: 図番, 発注種類: 発注種類)

        lock.lock()
        let data = self.cache[key]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.一覧
        }
        return try self.現在発注一覧(図番: 図番, 発注種類: 発注種類)
    }
    
    func flushCache(図番: 図番型) {
        lock.lock()
        for type in 発注種類型.allCases {
            self.cache[資材発注キャッシュKey(図番: 図番, 発注種類: type)] = nil
        }
        self.cache[資材発注キャッシュKey(図番: 図番, 発注種類: nil)] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }
}
*/
