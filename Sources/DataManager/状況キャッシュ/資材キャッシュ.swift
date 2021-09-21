//
//  資材キャッシュ.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/03/08.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation
/*
public final class 資材キャッシュ型 {
    var expire: TimeInterval = 4*60*60 // 4時間
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
*/
public typealias 資材キャッシュ型 = DMDBCache<図番型, 資材型>

private let 資材キャッシュ = 資材キャッシュ型(lifeTime: 4*60*60) {
    if $0 == "996068" {
        return try 資材型.find(図番: "990120")
    } else {
        return try 資材型.find(図番: $0)
    }
}
extension 資材キャッシュ型 {
    public static var shared: 資材キャッシュ型 { return 資材キャッシュ }
    public func 現在資材(図番: 図番型) throws -> 資材型? { try find(図番, noCache: true) }
    public func キャッシュ資材(図番: 図番型) throws -> 資材型? { try find(図番, noCache: false) }
}
