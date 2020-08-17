//
//  資材キャッシュ.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/03/08.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

public class 資材キャッシュ型 {
    var expire: TimeInterval = 4*60*60 // 8時間
    public static let shared = 資材キャッシュ型()
    
    let lock = NSLock()
    var cache: [図番型: (expire: Date, item: 資材型)] = [:]
    
    public func 現在資材(図番: 図番型) throws -> 資材型? {
        guard let result = try 資材型.find(図番: 図番) else { return nil }
        let date = Date(timeIntervalSinceNow: self.expire)
        lock.lock()
        self.cache[図番] = (date, result)
        lock.unlock()
        return result
    }
    
    public func キャッシュ資材(図番: 図番型) throws -> 資材型? {
        if 図番.isEmpty { return nil }
        lock.lock()
        let cache = self.cache[図番]
        lock.unlock()
        if let cache = cache, Date() < cache.expire { return cache.item }
        return try self.現在資材(図番: 図番)
    }
    
    func flushCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}
