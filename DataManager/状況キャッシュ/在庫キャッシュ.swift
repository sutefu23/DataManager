//
//  在庫キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/18.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

class 在庫数キャッシュ型 {
    static let shared = 在庫数キャッシュ型()
    
    private let lock = NSLock()
    private var cache: [String: Int] = [:]
    
    func 現在在庫(of item: 資材型) throws -> Int {
        guard let item = try 資材型.find(図番: item.図番) else { return 0 }
        let num = item.レコード在庫数
        lock.lock()
        self.cache[item.図番] = num
        lock.unlock()
        return num
    }
    
    func キャッシュ在庫数(of item: 資材型) throws -> Int {
        lock.lock()
        if let cache = self.cache[item.図番] {
            lock.unlock()
            return cache
        }
        lock.unlock()
        return try 現在在庫(of: item)
    }
}

