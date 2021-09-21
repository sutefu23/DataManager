//
//  指示書進捗キャッシュ.swift
//  DataManager
//
//  Created by manager on 2019/12/10.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public final class 進捗一覧Data型: DMCacheElement {
    let 進捗一覧: [進捗型]
    public lazy var 工程別進捗一覧: [工程型: [進捗型]] = { Dictionary(grouping: self.進捗一覧, by: { $0.工程 }) }()
    public lazy var 作業進捗一覧: [進捗型] = { self.進捗一覧.filter { $0.作業種別 != .その他 } }()

    init(_ list: [進捗型]) {
        self.進捗一覧 = list
    }
    
    public var memoryFootPrint: Int {
        return 進捗一覧.count * 22 * 8 * 3
    }
}

public class 指示書進捗キャッシュ型: DMDBCache<伝票番号型, 進捗一覧Data型> {
    public static func 工程別進捗一覧(伝票番号: 伝票番号型, update: Bool = false) throws -> [工程型: [進捗型]]? {
        return try shared.find(伝票番号, noCache: update)?.工程別進捗一覧
    }
    public static let shared: 指示書進捗キャッシュ型 = 指示書進捗キャッシュ型(lifeTime: 5*60) {
        let list = try 進捗型.find2(伝票番号: $0)
        let data = 進捗一覧Data型(list)
        return data
    }

    public var expire: TimeInterval {
        get { return self.lifeTime }
        set { self.lifeTime = newValue }
        
    }
    func 現在一覧(_ 伝票番号: 伝票番号型) throws -> 進捗一覧Data型? {
        return try self.find(伝票番号, noCache: true)
    }
    func キャッシュ一覧(_ 伝票番号: 伝票番号型) throws -> 進捗一覧Data型? {
        return try self.find(伝票番号, noCache: false)
    }
    
    public func cutExpire(伝票番号: 伝票番号型, maxExpire: TimeInterval) {
        self.changeExpire(maxExpire, forKey: 伝票番号)
    }

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
        guard let list = try self.find(number)?.進捗一覧 else { return false }
        var hasHigh: Bool = false
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
