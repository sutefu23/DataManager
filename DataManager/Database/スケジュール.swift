//
//  スケジュール管理詳細型.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

class スケジュール型 {
    let record : FileMakerRecord
    
    init?(_ record:FileMakerRecord) {
        self.record = record
    }
    
    var 種類 : String { return record.string(forKey: "種類")! }
    var 開始日 : Day { return record.day(forKey: "開始日")! }
    var 開始時刻 : Time? { return record.time(forKey: "開始時刻") }
    var 終了日 : Day? { return record.day(forKey: "終了日") }
    var 終了時刻 : Time? { return record.time(forKey: "終了時刻") }
}

private let tableName = "スケジュール管理テーブル"

extension FileMakerDB {
    func find(at day:Day) -> [スケジュール型] {
        let str = day.fmString
//        let list = find(layout: "スケジュール管理詳細", query: [["開始日" : str, "終了日" : "="], ["開始日" : "<=\(str)", "終了日" : ">=\(str)"]])
        let list = find(layout: "DataAPI_スケジュール", query: [["開始日" : str, "終了日" : "="], ["開始日" : "<=\(str)", "終了日" : ">=\(str)"]])
        let result = list?.compactMap { スケジュール型($0) } ?? []
        return result
//        let list = find(layout: "スケジュール管理詳細", query: [["開始日" : str, "終了日" : "="]]) ?? []
//        let list2 = find(layout: "スケジュール管理詳細", query: [["開始日" : "<=\(str)", "終了日" : "<=\(str)"]]) ?? []
//        var data = list.compactMap { スケジュール型($0) }
//        let data2 = list2.compactMap { スケジュール型($0) }
//        data.append(contentsOf: data2)
//        return data
    }
    
}

