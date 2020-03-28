//
//  在庫キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/18.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

class 在庫数キャッシュ型 {
    var 在庫寿命: TimeInterval = 10 * 60 // 10分間
    static let shared = 在庫数キャッシュ型()
    
    private let lock = NSLock()
    private var cache: [図番型: (有効期限: Date, 在庫数: Int)] = [:]
    
    func 現在在庫(of item: 資材型) throws -> Int {
        let limit = Date(timeIntervalSinceNow: 在庫寿命)
        let num = item.レコード在庫数
        lock.lock()
        self.cache[item.図番] = (limit, num)
        lock.unlock()
        return num
    }
    
    func キャッシュ在庫数(of item: 資材型) throws -> Int {
        lock.lock()
        if let cache = self.cache[item.図番], Date() < cache.有効期限 {
            lock.unlock()
            return cache.在庫数
        }
        lock.unlock()
        return try 現在在庫(of: item)
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
