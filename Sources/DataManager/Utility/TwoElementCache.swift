//
//  DoubleCache.swift
//  NCEngineより移行
//
//  Created by 四熊泰之 on R 2/02/02.
//  Copyright © Reiwa 2 四熊 泰之. All rights reserved.
//

import Foundation

private struct TwoElementCacheData<T, U> where T: Equatable {
    let key: T
    let value: U
    
    init(key:T, value: U) {
        self.key = key
        self.value = value
    }
}

/// ２データサイズの小キャッシュ（ロックあり）
public class TwoElementCache<T: Equatable, U>: TwoElementStorage<T, U> {
    private let lock: NSLock

    public init(_ lock: NSLock = NSLock()){
        self.lock = lock
    }

    public override func result(for key: T, calc: ()->U) -> U {
        lock.lock()
        defer { lock.unlock() }
        return super.result(for: key, calc: calc)
    }
}

/// ２データサイズの小キャッシュ（ロックなし）
public class TwoElementStorage<T: Equatable, U> {
    private var firstCache: TwoElementCacheData<T, U>? = nil
    private var secondCache: TwoElementCacheData<T, U>? = nil

    public init() {}
    
    public func result(for key: T, calc: ()->U) -> U {
        if let cache = firstCache, cache.key == key { return cache.value }
        if let cache = secondCache, cache.key == key {
            self.secondCache = firstCache
            self.firstCache = cache
            return cache.value
        }
        let value = calc()
        self.secondCache = self.firstCache
        self.firstCache = TwoElementCacheData(key: key, value: value)
        return value
    }
}
