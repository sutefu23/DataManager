//
//  進捗.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 進捗型 {
    public let 工程 : 工程型
    public let 作業内容 : 作業内容型
    public let 登録日時 : Date
    public var 社員名称 : String
    var 登録日 : Day
    var 登録時間 : Time

    init?(_ record:FileMakerRecord) {
        guard let state = record.工程(forKey: "工程名称") else {
            if record.string(forKey: "工程名称")?.isEmpty == true { return nil }
            fatalError()
        }
        guard let type = record.作業内容(forKey: "進捗コード") else { fatalError() }
        guard let name = record.string(forKey: "社員名称") else { fatalError() }
        guard let day = record.day(forKey: "登録日") else { fatalError() }
        guard let time = record.time(forKey: "登録時間") else { fatalError() }
        self.工程 = state
        self.作業内容 = type
        self.社員名称 = name
        self.登録日 = day
        self.登録時間 = time
        self.登録日時 = Date(day, time)
    }
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
