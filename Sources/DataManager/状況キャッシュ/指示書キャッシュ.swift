//
//  指示書キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/02/12.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 指示書伝票番号キャッシュ型: DMDBCache<伝票番号型, 指示書型> {
    public static let shared: 指示書伝票番号キャッシュ型 = 指示書伝票番号キャッシュ型(lifeSpan: 10*60*60, nilCache: false) {
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
    public static let shared: 指示書UUIDキャッシュ型 = 指示書UUIDキャッシュ型(lifeSpan: 10*60*60, nilCache: false) {
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

public class 伝票番号キャッシュ型: DMDBCache<Int, 伝票番号型> {
    public static let shared: 伝票番号キャッシュ型 = 伝票番号キャッシュ型(lifeSpan: 30*60, nilCache: true) {
        let number = 伝票番号型(validNumber: $0)
        return try 伝票番号型.isExist(伝票番号: number) ? number : nil
    }
    
    public func find<S: StringProtocol>(_ number: S, noCache: Bool = false) throws -> 伝票番号型? {
        guard let number = Int(String(number.filter{ $0.isASCIINumber })) else { return nil }
        return try self.find(number, noCache: noCache)
    }

    public override func find(_ number: Int?, noCache: Bool = false) throws -> 伝票番号型? {
        guard let number = number, let orderNumber = 伝票番号型(invalidNumber: number) else { return nil }
        if 指示書伝票番号キャッシュ型.shared.isCaching(forKey: orderNumber) {
            self.regist(orderNumber, forKey: number)
            return orderNumber
        }
        return try super.find(number, noCache: noCache)
    }
    
    public func isExists(_ number: String) throws -> Bool {
        guard let orderNumber = 伝票番号型(invalidNumber: number) else { return false }
        return try isExists(orderNumber.整数値)
    }
    
    public func isExists(_ number: Int) throws -> Bool {
        if self.isCaching(forKey: number) { return true }
        guard let orderNumber = 伝票番号型(invalidNumber: number) else { return false }
        if 指示書伝票番号キャッシュ型.shared.isCaching(forKey: orderNumber) {
            self.regist(orderNumber, forKey: number)
            return true
        }
        return try self.find(number) != nil
    }
}
