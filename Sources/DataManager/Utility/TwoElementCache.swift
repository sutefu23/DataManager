//
//  DoubleCache.swift
//  NCEngineより移行
//
//  Created by 四熊泰之 on R 2/02/02.
//  Copyright © Reiwa 2 四熊 泰之. All rights reserved.
//

import Foundation

private final class TwoElementCacheData<T, U> where T: Equatable {
    let key: T
    let value: U
    
    init(key:T, value: U) {
        self.key = key
        self.value = value
    }
}

/// ２データサイズの小キャッシュ
public struct TwoElementCache<T, U> where T: Equatable {
    private let lock = NSLock()
    private var firstCache: TwoElementCacheData<T, U>? = nil
    private var secondCache: TwoElementCacheData<T, U>? = nil

    public init(){}

    public mutating func result(for key: T, calc: ()->U) -> U {
        lock.lock()
        defer { lock.unlock() }
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
