//
//  進捗.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 進捗型 : Equatable {
    let record : FileMakerRecord

    public let 工程 : 工程型
    public let 作業内容 : 作業内容型
    public let 登録日時 : Date
    public var 社員名称 : String
    var 登録日 : Day
    var 登録時間 : Time

    init?(_ record:FileMakerRecord) {
        guard let state = record.工程(forKey: "工程コード") ?? record.工程(forKey: "工程名称") else {
            if record.string(forKey: "工程名称")?.isEmpty == true { return nil }
//            return nil
            fatalError()
        }
        self.record = record
        guard let type = record.作業内容(forKey: "進捗コード") else { return nil }
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
    
    public static func ==(left:進捗型, right:進捗型) -> Bool {
        return left.工程 == right.工程 && left.作業内容 == right.作業内容 && left.社員名称 == right.社員名称 && left.登録日時 == right.登録日時
    }
}

public extension 進捗型 {
    var 伝票種類 : 伝票種類型? {
        return record.伝票種類(forKey: "伝票種類")
    }
    
    var 社員番号 : Int? {
        return record.integer(forKey: "社員番号")
    }
    
    var 伝票番号 : Int? {
        return record.integer(forKey: "伝票番号")
    }
    
    var 製作納期 : Date? {
        return record.date(forKey: "製作納期")
    }
    
    var 指示書 : 指示書型? {
        guard let number = self.伝票番号 else { return nil }
        return 指示書型.find(伝票番号: number)?.first
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
    
    func 作業内容(工程:[工程型], 日時:Date? = nil) -> 作業内容型? {
        var state : 作業内容型? = nil
        for progress in self where 工程.contains(progress.工程) {
            if let date = 日時, progress.登録日時 > date { continue }
            state = progress.作業内容
        }
        return state
    }
}

public extension 進捗型 {
    static func find(検索期間 range:ClosedRange<Date>, 工程 state:工程型, 作業内容 type:作業内容型) -> [進捗型]? {
        var query = [String:String]()
        query["登録日"] = makeQueryDayString(range)
        query["工程コード"] = "\(state.code)"
        query["進捗コード"] = "\(type.code)"
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_進捗", query: [query])
//        let list : [FileMakerRecord]? = db.find(layout: "指示書進捗テーブル一覧", query: [query])
        return list?.compactMap { 進捗型($0) }
    }
}

public extension Sequence where Element == 進捗型 {
    func contains(工程: 工程型, 作業内容: 作業内容型) -> Bool {
        return self.contains { $0.工程 == 工程 && $0.作業内容 == 作業内容}
    }
    
    func findFirst(工程: 工程型, 作業内容: 作業内容型) -> 進捗型? {
        return self.first { $0.工程 == 工程 && $0.作業内容 == 作業内容 }
    }
}
