//
//  スケジュール管理詳細型.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

struct スケジュール型: FileMakerImportObject {
    static let layout: String = "DataAPI_6" 
    
    let recordId: FileMakerRecordID?
    
    init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "スケジュール", mes: key) }
        guard let 種類 = record.string(forKey: "種類") else { throw makeError("種類") }
        self.種類 = 種類
        guard let 開始日 = record.day(forKey: "開始日") else { throw makeError("開始日") }
        self.開始日 = 開始日
        self.開始時刻 = record.time(forKey: "開始時刻")
        self.終了日 = record.day(forKey: "終了日")
        self.終了時刻 = record.time(forKey: "終了時刻")
        self.recordId = record.recordId
    }
    let 種類: String
    let 開始日: Day
    let 開始時刻: Time?
    let 終了日: Day?
    let 終了時刻: Time?
    
    var memoryFootPrint: Int { return MemoryLayout<スケジュール型>.stride }
}

private let tableName = "スケジュール管理テーブル"

extension スケジュール型 {
    static func find(at day: Day) throws -> [スケジュール型] {
        let daystr = day.fmString
        return try self.find(querys: [
            ["開始日" : daystr, "終了日" : "="],
            ["開始日" : "<=\(daystr)", "終了日" : ">=\(daystr)"]
        ])
    }
}
