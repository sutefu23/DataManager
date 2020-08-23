//
//  在庫キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/18.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public final class 在庫数キャッシュ型 {
    var 在庫寿命: TimeInterval = 10 * 60 // 10分間
    public static let shared = 在庫数キャッシュ型()
    
    private let lock = NSLock()
    private var cache: [図番型: (有効期限: Date, 在庫数: Int)] = [:]
    
    func 現在在庫(of item: 資材型) throws -> Int {
        guard let item2 = try 資材型.find(図番: item.図番) else {
            throw FileMakerError.notFound(message: " 資材 図番:\(item.図番)")
        }
        let num = item2.レコード在庫数
        let limit = Date(timeIntervalSinceNow: 在庫寿命)
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
    
    public func flushCache(_ item: 図番型, 暫定個数: Int? = nil) {
        lock.lock()
        if let num = 暫定個数 {
            let limit = Date(timeIntervalSinceNow: 在庫寿命)
            cache[item] = (limit, num)
        } else {
            cache[item] = nil
        }
        lock.unlock()
    }
    
    public func flushAllCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}
