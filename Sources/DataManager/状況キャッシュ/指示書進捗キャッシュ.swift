//
//  指示書進捗キャッシュ.swift
//  DataManager
//
//  Created by manager on 2019/12/10.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

final class 進捗一覧Data型 {
    let 進捗一覧: [進捗型]
    public lazy var 工程別進捗一覧: [工程型: [進捗型]] = { Dictionary(grouping: self.進捗一覧, by: { $0.工程 }) }()
    public lazy var 作業進捗一覧: [進捗型] = { self.進捗一覧.filter { $0.作業種別 != .その他 } }()

    init(_ list: [進捗型]) {
        self.進捗一覧 = list
    }
}

public final class 指示書進捗キャッシュ型 {
    public static func 工程別進捗一覧(伝票番号: 伝票番号型, update: Bool = false) throws -> [工程型: [進捗型]] {
        return try update ? 指示書進捗キャッシュ型.shared.現在一覧(伝票番号).工程別進捗一覧 : 指示書進捗キャッシュ型.shared.キャッシュ一覧(伝票番号).工程別進捗一覧
    }
    
    public var expire: TimeInterval = 5*60 // ５分
    public static let shared = 指示書進捗キャッシュ型()
    
    private let lock = NSLock()
    private var cache: [伝票番号型: (expire: Date, data: 進捗一覧Data型)] = [:]
    
    func 現在一覧(_ 伝票番号: 伝票番号型) throws -> 進捗一覧Data型 {
        let expire = Date(timeIntervalSinceNow: self.expire)
        let list = try 進捗型.find2(伝票番号: 伝票番号)
        let data = 進捗一覧Data型(list)
        lock.lock()
        self.cache[伝票番号] = (expire, data)
        lock.unlock()
        return data
    }
    
    func キャッシュ一覧(_ 伝票番号: 伝票番号型) throws -> 進捗一覧Data型 {
        lock.lock()
        let cache = self.cache[伝票番号]
        lock.unlock()
        if let cache = cache, Date() < cache.expire { return cache.data }
        return try 現在一覧(伝票番号)
    }
    
    public func flushAllCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
    public func flushCache(伝票番号: 伝票番号型) {
        lock.lock()
        cache[伝票番号] = nil
        lock.unlock()
    }
    
    // MARK: -
    public func has受取(number: 伝票番号型, process: 工程型, member: 社員型?) throws -> Bool {
        return try hasComplete(number: number, process: process, work: .受取, member: member)
    }

    public func has開始(number: 伝票番号型, process: 工程型, member: 社員型?) throws -> Bool {
        return try hasComplete(number: number, process: process, work: .開始, member: member)
    }

    public func has完了(number: 伝票番号型, process: 工程型, member: 社員型?) throws -> Bool {
        return try hasComplete(number: number, process: process, work: .完了, member: member)
    }
    
    public func hasComplete(number: 伝票番号型, process: 工程型, work: 作業内容型, member: 社員型? = nil) throws -> Bool {
        var hasHigh: Bool = false
        let list = try self.キャッシュ一覧(number).進捗一覧
        for progress in list.reversed() where progress.工程 == process {
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
}
