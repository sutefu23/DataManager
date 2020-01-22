//
//  スケジュール管理詳細型.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

class スケジュール型 {
    static let dbName = "DataAPI_6"

    let record: FileMakerRecord
    
    init?(_ record: FileMakerRecord) {
        self.record = record
    }
    
    var 種類 : String { return record.string(forKey: "種類")! }
    var 開始日 : Day { return record.day(forKey: "開始日")! }
    var 開始時刻 : Time? { return record.time(forKey: "開始時刻") }
    var 終了日 : Day? { return record.day(forKey: "終了日") }
    var 終了時刻 : Time? { return record.time(forKey: "終了時刻") }
}

private let tableName = "スケジュール管理テーブル"

extension スケジュール型 {
    static func find(at day: Day) throws -> [スケジュール型] {
        let db = FileMakerDB.pm_osakaname
        let str = day.fmString
        let list = try db.find(layout: スケジュール型.dbName, query: [["開始日" : str, "終了日" : "="], ["開始日" : "<=\(str)", "終了日" : ">=\(str)"]])
        return list.compactMap { スケジュール型($0) }
    }

}

