//
//  使用資材キャッシュ.swift
//  DataManager
//
//  Created by manager on 2021/07/05.
//

import Foundation

public func flush使用資材キャッシュ() {
    使用資材キャッシュ型.shared.flushAllCache()
}

private struct 使用資材キャッシュKey: Hashable {
    let 伝票番号: 伝票番号型
}

final class 使用資材キャッシュ型 {
    static let shared = 使用資材キャッシュ型()
    var expireTime: TimeInterval = 1*60*60 // 1時間
    private let lock = NSLock()
    private var cache: [使用資材キャッシュKey: (有効期限: Date, 一覧: [使用資材型])] = [:]
    
    func 現在使用資材一覧(伝票番号: 伝票番号型) throws -> [使用資材型] {
        let key = 使用資材キャッシュKey(伝票番号: 伝票番号)
        let list = try 使用資材型.find(伝票番号: 伝票番号)
        let expire = Date(timeIntervalSinceNow: self.expireTime)
        lock.lock()
        cache[key] = (expire, list)
        lock.unlock()
        return list
    }
    
    func キャッシュ使用資材一覧(伝票番号: 伝票番号型) throws -> [使用資材型] {
        let key = 使用資材キャッシュKey(伝票番号: 伝票番号)

        lock.lock()
        let data = self.cache[key]
        lock.unlock()
        if let data = data, Date() <= data.有効期限 {
            return data.一覧
        }
        return try self.現在使用資材一覧(伝票番号: 伝票番号)
    }
    
    func flushCache(伝票番号: 伝票番号型) {
        lock.lock()
        self.cache[使用資材キャッシュKey(伝票番号: 伝票番号)] = nil
        lock.unlock()
    }
    
    func flushAllCache() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
    }
}

