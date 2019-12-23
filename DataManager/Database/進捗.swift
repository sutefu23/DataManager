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
    public var 登録日 : Day
    public var 登録時間 : Time

    public lazy var 伝票番号 : 伝票番号型 = {
        guard let number = self.record.integer(forKey: "伝票番号") else {
            fatalError()
        }
        return 伝票番号型(validNumber: number)
    }()

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
    
    public lazy var 作業種別: 作業種別型 = {
//        guard let str = self.record.string(forKey: "作業種別コード") else { return .通常 }
//        return 作業種別型(str)
        作業種別型(self.record.string(forKey: "作業種別コード") ?? "")
    }()
    
    public lazy var 作業系列: 作業系列型? = {
        作業系列型(系列コード: self.record.string(forKey: "作業系列コード") ?? "")
    }()
}

public extension 進捗型 {
    var 伝票種類 : 伝票種類型? {
        return record.伝票種類(forKey: "伝票種類")
    }
    
    var 社員番号 : Int? {
        return record.integer(forKey: "社員番号")
    }
    
    var 作業者 : 社員型 {
        return 社員型(社員番号: self.社員番号 ?? 0, 社員名称:self.社員名称)
    }
    
    var 製作納期 : Day? {
        return record.day(forKey: "製作納期")
    }
    
    var 指示書 : 指示書型? {
        return (try? 指示書型.find(伝票番号: self.伝票番号))?.first
    }
    
    var レーザー加工機 : レーザー加工機型? {
        switch self.作業系列 {
        case 作業系列型.gx:    return .gx
        case 作業系列型.ex:    return .ex
        case 作業系列型.hp:    return .hp
        case 作業系列型.water: return .sws
        default:
            break
        }
        guard self.工程 == .レーザー || self.工程 == .レーザー（アクリル） else { return nil }
        if self.登録日 >= Day(2019, 12, 6) { return nil }
        guard let number = self.社員番号 else { return nil }
        switch number {
        case 61:
            return self.登録日 < Day(2019, 11, 10) ? .hv : .gx
        case 84:
            return .ex
        case 38:
            return .hp
        case 920:
            return .sws
        default:
            return nil
        }
    }
}

public extension Array where Element == 進捗型 {
    func 作業内容(工程:工程型, 日時:Day? = nil) -> 作業内容型? {
        var state : 作業内容型? = nil
        for progress in self where progress.工程 == 工程 {
            if let day = 日時, progress.登録日 >= day { continue }
            state = progress.作業内容
        }
        return state
    }
    
//    func 作業内容(工程:[工程型], 日時:Day? = nil) -> 作業内容型? {
//        var state : 作業内容型? = nil
//        for progress in self where 工程.contains(progress.工程) {
//            if let day = 日時, progress.登録日 >= day { continue }
//            state = progress.作業内容
//        }
//        return state
//    }
}

public extension Sequence where Element == 進捗型 {
    func contains(工程: 工程型, 作業内容: 作業内容型) -> Bool {
        return self.contains { $0.工程 == 工程 && $0.作業内容 == 作業内容}
    }
    
    func findFirst(工程: 工程型, 作業内容: 作業内容型) -> 進捗型? {
        return self.first { $0.工程 == 工程 && $0.作業内容 == 作業内容 }
    }
}

// MARK: - 検索
public extension 進捗型 {
    static func find(伝票番号 num:伝票番号型, 工程 state:工程型? = nil, 作業内容 work:作業内容型? = nil) throws -> [進捗型] {
    var query = [String:String]()
        query["伝票番号"] = "\(num)"
    if let state = state {
        query["工程コード"] = "\(state.code)"
    }
    if let work = work {
        query["進捗コード"] = "\(work.code)"
    }
    let db = FileMakerDB.pm_osakaname
    let list : [FileMakerRecord] = try db.find(layout: "DataAPI_進捗", query: [query])
    return list.compactMap { 進捗型($0) }

    }
    
    static func find(製作納期 range:ClosedRange<Day>, 伝票種類 type:伝票種類型? = nil, 工程 state:工程型? = nil, 作業内容 work:作業内容型? = nil) throws -> [進捗型] {
        var query = [String:String]()
        query["製作納期"] = makeQueryDayString(range)
        if let type = type {
            query["伝票種類"] = type.fmString
        }
        if let state = state {
            query["工程コード"] = "\(state.code)"
        }
        if let work = work {
            query["進捗コード"] = "\(work.code)"
        }
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord] = try db.find(layout: "DataAPI_進捗", query: [query])
        //        let list : [FileMakerRecord]? = db.find(layout: "指示書進捗テーブル一覧", query: [query])
        return list.compactMap { 進捗型($0) }
    }
    
    static func find(登録期間 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil, 工程 state: 工程型? = nil, 作業内容 work: 作業内容型? = nil) throws -> [進捗型] {
        var query = [String:String]()
        query["登録日"] = makeQueryDayString(range)
        if let type = type {
            query["伝票種類"] = type.fmString
        }
        if let state = state {
            query["工程コード"] = "\(state.code)"
        }
        if let work = work {
            query["進捗コード"] = "\(work.code)"
        }
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord] = try db.find(layout: "DataAPI_進捗", query: [query])
        return list.compactMap { 進捗型($0) }
    }
    
    static func find(伝票作業期間 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil, 工程 state: 工程型? = nil, 作業内容 work: 作業内容型? = nil) throws -> [進捗型] {
        let list = try 進捗型.find(登録期間: range, 伝票種類: type, 工程: state, 作業内容: work)
        
        var numbers = Set<伝票番号型>()
        for progress in list {
            let num = progress.伝票番号
            numbers.insert(num)
        }
        
        var result : [進捗型] = []
        for num in numbers {
            let tmp = try 進捗型.find(伝票番号: num)
            result.append(contentsOf: tmp)
        }
        return result
    }
    
    static func find(工程 state: 工程型?, 登録日 day: Day) throws -> [進捗型] {
        var query = [String:String]()
        query["登録日"] = day.fmString
        if let state = state {
            query["工程コード"] = "\(state.code)"
        }
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord] = try db.find(layout: "DataAPI_進捗", query: [query])
        return list.compactMap { 進捗型($0) }
    }
}

