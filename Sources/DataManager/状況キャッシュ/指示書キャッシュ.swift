//
//  指示書キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/02/12.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 指示書キャッシュKey型: DMCacheElement, Hashable {
    case number(伝票番号型)
    case uuid(UUID)
    
    public var memoryFootPrint: Int {
        switch self {
        case .number(let number):
            return number.memoryFootPrint
        case .uuid(let uuid):
            return uuid.memoryFootPrint
        }
    }
}

public typealias 指示書キャッシュ型2 = DMDBCache<指示書キャッシュKey型, 指示書型>
private let 指示書キャッシュ = 指示書キャッシュ型2(lifeTime: 10*60*60) {
    switch $0 {
    case .number(let number):
        return try 指示書型.findDirect(伝票番号: number)
    case .uuid(let uuid):
        return try 指示書型.findDirect(uuid: uuid)
    }
}
extension 指示書キャッシュ型2 {
//    public func find(_ number: 伝票番号型) throws -> 指示書型? {
//    }
//    public func find(_ uuid: UUID) throws -> 指示書型? {
//    }
//    public func regist(_ order: 指示書型) {
//    }
    
}

public final class 指示書キャッシュ型 {
    public static let shared = 指示書キャッシュ型()
    let lock = NSLock()
    var cache: [伝票番号型 : 指示書型?] = [:]
    var cache2: [UUID: 指示書型] = [:]

    public func find(_ number: 伝票番号型) throws -> 指示書型? {
        lock.lock()
        defer { lock.unlock() }
        if let cache = self.cache[number] { return cache }
        let order = try 指示書型.findDirect(伝票番号: number)
        cache[number] = order
        if let order = order {
            cache2[order.uuid] = order
        }
        return order
    }
    public func find(_ uuid: UUID) throws -> 指示書型? {
        lock.lock()
        defer { lock.unlock() }
        if let cache = self.cache2[uuid] { return cache }
        let order = try 指示書型.findDirect(uuid: uuid)
        if let order = order {
            cache[order.伝票番号] = order
            cache2[order.uuid] = order
        }
        return order
    }
    
    public func regist(_ order: 指示書型) {
        lock.lock()
        cache[order.伝票番号] = order
        cache2[order.uuid] = order
        lock.unlock()
    }
    
    
    public func clearAll() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}


//public let 伝票番号キャッシュ = 伝票番号キャッシュ型()
//public final class 伝票番号キャッシュ型 {
//    let lock = NSLock()
//    var cache: [Int: 伝票番号型] = [:]
//
//    public func find(_ number: String) throws -> 伝票番号型? {
//        return try self.find(Int(number))
//    }
//
//    public func find(_ number: Int?) throws -> 伝票番号型? {
//        guard let number = number, 伝票番号型.isValidNumber(number) else { return nil }
//        lock.lock()
//        defer { lock.unlock() }
//        if let cache = self.cache[number] { return cache }
//        let orderNumber = try 伝票番号型(invalidNumber: number)
//        cache[number] = orderNumber
//        return orderNumber
//    }
//
//    public func isExists(_ number: String) throws -> Bool {
//        return try self.find(number) != nil
//    }
//
//    public func isExists(_ number: Int?) throws -> Bool {
//        return try self.find(number) != nil
//    }
//
//    public func clearAll() {
//        lock.lock()
//        cache.removeAll()
//        lock.unlock()
//    }
//}

public typealias 伝票番号キャッシュ型 = DMDBCache<Int, 伝票番号型>

public let 伝票番号キャッシュ = 伝票番号キャッシュ型(lifeTime: 4*60*60) { try 伝票番号型(invalidNumber: $0) }
extension 伝票番号キャッシュ型 {
    public func find(_ number: String) throws -> 伝票番号型? {
        return try self.find(Int(number))
    }
    public func find(_ number: Int?) throws -> 伝票番号型? {
        guard let number = number, 伝票番号型.isValidNumber(number) else { return nil }
        return try self.find(number)
    }
    
    public func isExists(_ number: String) throws -> Bool {
        return try self.find(number) != nil
    }
}
