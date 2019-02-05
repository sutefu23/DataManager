//
//  進捗.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 進捗型 {
    let record : FileMakerRecord
    public let 工程 : 工程型
    public let 作業内容 : 作業内容型
    public let 登録日時 : Date
    
    init?(_ record:FileMakerRecord) {
        guard let process = record.工程(forKey: "工程名称") else { return nil }
        guard let state = record.作業内容(forKey: "進捗コード") else { return nil }
        guard let date = record.date(dayKey: "登録日", timeKey: "登録時間") else { return nil }
        self.工程 = process
        self.作業内容 = state
        self.登録日時 = date
        self.record = record
    }
    
    public var 社員名称 : String { return record.string(forKey: "社員名称")! }
    public var 工程名称 : String { return record.string(forKey: "工程名称")! }
    var 登録日 : Day { return record.day(forKey: "登録日")! }
    var 登録時間 : Time { return record.time(forKey: "登録時間")! }
}

public extension Array where Element == 進捗型 {
    func 作業内容(工程:工程型, 日時:Date? = nil) -> 作業内容型? {
        var state : 作業内容型? = nil
        for progress in self where progress.工程 == 工程 {
            if let date = 日時, progress.登録日時 > date { continue }
            state = progress.作業内容
        }
        return state
    }
}
