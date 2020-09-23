//
//  取引先キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

final class 取引先キャッシュ型 {
    static let shared = 取引先キャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [会社コード型: (有効期限: Date, 取引先: 取引先型?)] = [:]

    func 現在取引先(会社コード: 会社コード型) throws -> 取引先型? {
        let list = try 取引先型.find(会社コード: 会社コード)
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[会社コード] = (expire, list)
        lock.unlock()
        return list
    }

    func キャッシュ取引先(会社コード: 会社コード型) throws -> 取引先型? {
        lock.lock()
        let data = self.cache[会社コード]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.取引先
        }
        return try self.現在取引先(会社コード: 会社コード)
    }

    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }
}
