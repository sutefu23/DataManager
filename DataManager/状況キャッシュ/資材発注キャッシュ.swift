//
//  資材発注キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

class 資材発注キャッシュ型 {
    static let shared = 資材発注キャッシュ型()
    var expireTime: TimeInterval = 1*60*60
    private let lock = NSLock()
    private var cache: [図番型: (有効期限: Date, 一覧: [発注型])] = [:]
    
    func 現在発注一覧(図番: 図番型) throws -> [発注型] {
        let list = try 発注型.find(資材番号: 図番)
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[図番] = (expire, list)
        lock.unlock()
        return list
    }
    
    func キャッシュ発注一覧(図番: 図番型) throws -> [発注型] {
        lock.lock()
        let data = self.cache[図番]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.一覧
        }
        return try self.現在発注一覧(図番: 図番)
    }
    
    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }
}

extension 資材発注キャッシュ型 {
    
}
