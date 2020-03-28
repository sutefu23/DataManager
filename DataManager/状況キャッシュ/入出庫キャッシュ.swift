//
//  入出庫キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/23.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

class 入出庫キャッシュ型 {
    var 在庫寿命: TimeInterval = 10 * 60 // 10分間
    static let shared = 入出庫キャッシュ型()
    
    private let lock = NSLock()
    private var cache: [図番型: (有効期限: Date, 入出庫: [資材入出庫型])] = [:]
    
    func 現在入出庫(of item: 資材型) throws -> [資材入出庫型] {
        let limit = Date(timeIntervalSinceNow: 在庫寿命)
        let num = try 資材入出庫型.find(資材: item)
        lock.lock()
        self.cache[item.図番] = (limit, num)
        lock.unlock()
        return num
    }
    
    func キャッシュ入出庫(of item: 資材型) throws -> [資材入出庫型] {
        lock.lock()
        if let cache = self.cache[item.図番], Date() < cache.有効期限 {
            lock.unlock()
            return cache.入出庫
        }
        lock.unlock()
        return try 現在入出庫(of: item)
    }
    
    func flushCache(_ item: 図番型) {
        lock.lock()
        cache[item] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}
