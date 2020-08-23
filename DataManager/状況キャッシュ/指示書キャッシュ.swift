//
//  指示書キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/02/12.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public let 指示書キャッシュ = 指示書キャッシュ型()

public final class 指示書キャッシュ型 {
    let lock = NSLock()
    var cache: [伝票番号型 : 指示書型?] = [:]

    public func find(_ number: 伝票番号型) throws -> 指示書型? {
        lock.lock()
        defer { lock.unlock() }
        if let cache = self.cache[number] { return cache }
        let order = try 指示書型.findDirect(伝票番号: number)
        cache[number] = order
        return order
    }
    
    public func clearAll() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}

public let 伝票番号キャッシュ = 伝票番号キャッシュ型()
public final class 伝票番号キャッシュ型 {
    let lock = NSLock()
    
    var cache: [Int: 伝票番号型] = [:]

    public func find(_ number: String) throws -> 伝票番号型? {
        return try self.find(Int(number))
    }
    
    public func find(_ number: Int?) throws -> 伝票番号型? {
        guard let number = number, 伝票番号型.isValidNumber(number) else { return nil }
        lock.lock()
        defer { lock.unlock() }
        if let cache = self.cache[number] { return cache }
        let orderNumber = try 伝票番号型(invalidNumber: number)
        cache[number] = orderNumber
        return orderNumber
    }
    
    public func isExists(_ number: String) throws -> Bool {
        return try self.find(number) != nil
    }

    public func isExists(_ number: Int?) throws -> Bool {
        return try self.find(number) != nil
    }

    public func clearAll() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}

