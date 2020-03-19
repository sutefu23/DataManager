//
//  進捗状態.swift
//  DataManager
//
//  Created by manager on 2019/12/10.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 進捗キャッシュ型 {
    let lock = NSLock()
    
    var cache: [伝票番号型: [進捗型]] = [:]
    let 工程: 工程型
    
    public init(工程: 工程型) {
        self.工程 = 工程
    }
    
    subscript(_ number: 伝票番号型) -> [進捗型] {
        do {
            lock.lock()
            if let list = cache[number] {
                lock.unlock()
                return list
            }
            lock.unlock()
            guard let order = try 指示書型.findDirect(伝票番号: number) else { return [] }
            let list = order.進捗一覧
            if list.isEmpty { return [] }
            lock.lock()
            cache[number] = list
            lock.unlock()
            return list
        } catch {
            return []
        }
    }

    public func append(_ order: 指示書型) {
        let list = order.進捗一覧
        lock.lock()
        cache[order.伝票番号] = list
        lock.unlock()
    }
    
    public func has受取(number: 伝票番号型, member: 社員型?) -> Bool {
        return hasComplete(number: number, work: .受取, member: member)
    }

    public func has完了(number: 伝票番号型, member: 社員型?) -> Bool {
        return hasComplete(number: number, work: .完了, member: member)
    }
    
    public func hasComplete(number: 伝票番号型, work: 作業内容型, member: 社員型? = nil) -> Bool {
        var hasHigh: Bool = false
        for progress in self[number].filter({ $0.工程 == 工程 }).reversed() {
            if let member = member, progress.作業者 != member { continue }
            let current = progress.作業内容
            if current == work { return true }
            if current > work {
                hasHigh = true
            } else {
                if hasHigh { return true }
            }
        }
        return false
    }
    
    public func flushCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
    
    public func removeCache(number: 伝票番号型) {
        self.cache.removeValue(forKey: number)
    }
}
