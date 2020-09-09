//
//  SerialCache.swift
//  NCEngineから移行
//
//  Created by manager on 2017/01/27.
//  Copyright © 2017年 四熊 泰之. All rights reserved.
//

import Foundation

public final class SerialCache<Key : Hashable, Data> {
    private let lock = NSLock()
    private(set) var cache: Dictionary<Key, Data>

    public init(_ source: [Key:Data] = [:]) {
        self.cache = source
    }
    
    public subscript(_ key: Key) -> Data? {
        get {
            return lock.getValue { self.cache[key] }
        }
        set {
            lock.exec { self.cache[key] = newValue }
        }
    }
    
    public var isEmpty: Bool  {
        lock.lock()
        defer { lock.unlock() }
        return cache.isEmpty
    }
    
    public func flush() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
    
    @discardableResult public func prepare(data generator: @autoclosure ()->Data, forKey key: Key) -> Data {
        lock.lock()
        defer { lock.unlock() }
        if let cache = self.cache[key] { return cache }
        let data = generator()
        self.cache[key] = data
        return data
    }
}

extension SerialCache where Data: Hashable {
    public func makeReverseCache(_ name:String? = nil) -> SerialCache<Data, Key> {
        var dic = [Data:Key]()
        lock.exec {
            for (key, data) in cache {
                dic[data] = key
            }
        }
        return SerialCache<Data, Key>(dic)
    }
}
