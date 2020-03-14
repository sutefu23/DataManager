//
//  最終発注単価キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/14.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

class 最終発注単価キャッシュ型 {
    static let shared = 最終発注単価キャッシュ型()
    
    struct Value {
        var value: Double?
    }

    private let lock = NSLock()
    private var map: [String: Value] = [:]
    
    subscript(図番: String) -> Double? {
        lock.lock()
        defer { lock.unlock() }
        if let cache = self.map[図番] {
            lock.unlock()
            return cache.value
        }
        lock.unlock()
        do {
            let result: Double?
            let list = try 発注型.find(資材番号: 図番).sorted { $0.登録日 < $1.登録日 }
            if let order = list.last, let value = Double(order.金額), let num = order.発注数量, value > 0 && num > 0 {
                result = value / Double(num)
            } else {
                result = nil
            }
            lock.lock()
            map[図番] = Value(value: result)
            lock.unlock()
            return result
        } catch {
            return nil
        }
    }
}

extension 資材型 {
    public var 最終発注単価: Double? {
        return 最終発注単価キャッシュ型.shared[self.図番]
    }
}
