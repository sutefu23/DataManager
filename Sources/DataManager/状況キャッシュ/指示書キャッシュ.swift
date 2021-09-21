//
//  指示書キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/02/12.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 指示書伝票番号キャッシュ型: DMDBCache<伝票番号型, 指示書型> {
    public static let shared: 指示書伝票番号キャッシュ型 = 指示書伝票番号キャッシュ型(lifeTime: 10*60*60) {
        guard let order = try 指示書型.findDirect(伝票番号: $0) else { return nil }
        指示書UUIDキャッシュ型.shared.regist(order, forKey: order.uuid)
        伝票番号キャッシュ型.shared.regist(order.伝票番号, forKey: order.伝票番号.整数値)
        return order
    }
    
    public func regist(_ order: 指示書型) {
        self.regist(order, forKey: order.伝票番号)
        指示書UUIDキャッシュ型.shared.regist(order, forKey: order.uuid)
        伝票番号キャッシュ型.shared.regist(order.伝票番号, forKey: order.伝票番号.整数値)
    }
}

public class 指示書UUIDキャッシュ型: DMDBCache<UUID, 指示書型> {
    public static let shared: 指示書UUIDキャッシュ型 = 指示書UUIDキャッシュ型(lifeTime: 10*60*60) {
        guard let order = try 指示書型.findDirect(uuid: $0) else { return nil }
        指示書伝票番号キャッシュ型.shared.regist(order, forKey: order.伝票番号)
        伝票番号キャッシュ型.shared.regist(order.伝票番号, forKey: order.伝票番号.整数値)
        return order
    }
    
    public func regist(_ order: 指示書型) {
        self.regist(order, forKey: order.uuid)
        指示書伝票番号キャッシュ型.shared.regist(order, forKey: order.伝票番号)
        伝票番号キャッシュ型.shared.regist(order.伝票番号, forKey: order.伝票番号.整数値)
    }
}

//public final class 指示書キャッシュ型 {
//    public static let shared = 指示書キャッシュ型()
//    let lock = NSLock()
//    var cache: [伝票番号型 : 指示書型?] = [:]
//    var cache2: [UUID: 指示書型] = [:]
//
//    public func find(_ number: 伝票番号型) throws -> 指示書型? {
//        lock.lock()
//        defer { lock.unlock() }
//        if let cache = self.cache[number] { return cache }
//        let order = try 指示書型.findDirect(伝票番号: number)
//        cache[number] = order
//        if let order = order {
//            cache2[order.uuid] = order
//        }
//        return order
//    }
//    public func find(_ uuid: UUID) throws -> 指示書型? {
//        lock.lock()
//        defer { lock.unlock() }
//        if let cache = self.cache2[uuid] { return cache }
//        let order = try 指示書型.findDirect(uuid: uuid)
//        if let order = order {
//            cache[order.伝票番号] = order
//            cache2[order.uuid] = order
//        }
//        return order
//    }
//
//    public func regist(_ order: 指示書型) {
//        lock.lock()
//        cache[order.伝票番号] = order
//        cache2[order.uuid] = order
//        lock.unlock()
//    }
//
//
//    public func clearAll() {
//        lock.lock()
//        cache.removeAll()
//        lock.unlock()
//    }
//}

public class 伝票番号キャッシュ型: DMDBCache<Int, 伝票番号型> {
    public static let shared: 伝票番号キャッシュ型 = 伝票番号キャッシュ型(lifeTime: 4*60*60) {
        try 伝票番号型(invalidNumber: $0)
    }
    
    public func find(_ number: String) throws -> 伝票番号型? {
        guard let number = Int(String(number.filter{ $0.isASCIINumber })) else { return nil }
        return try self.find(Int(number))
    }
    public func find(_ number: Int?) throws -> 伝票番号型? {
        guard let number = number, 伝票番号型.isValidNumber(number) else { return nil }
        let orderNumber = 伝票番号型(validNumber: number)
        if 指示書伝票番号キャッシュ型.shared.isCaching(forKey: orderNumber) {
            self.regist(orderNumber, forKey: number)
            return orderNumber
        }
        return try self.find(number)
    }
    
    public func isExists(_ number: String) throws -> Bool {
        guard let number = Int(String(number.filter{ $0.isASCIINumber })) else { return false }
        if self.isCaching(forKey: number) { return true }
        let orderNumber = 伝票番号型(validNumber: number)
        guard orderNumber.isValidNumber else { return false }
        if 指示書伝票番号キャッシュ型.shared.isCaching(forKey: orderNumber) {
            self.regist(orderNumber, forKey: number)
            return true
        }
        return try self.find(number) != nil
    }
}
