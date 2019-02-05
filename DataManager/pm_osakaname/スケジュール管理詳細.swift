//
//  スケジュール管理詳細型.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class スケジュール管理詳細型 : FileMakerRecord {
    var 種類 : String { return string(forKey: "種類")! }
    var 開始日 : Day { return day(forKey: "開始日")! }
    var 開始時刻 : Time? { return time(forKey: "開始時刻") }
    var 終了日 : Day? { return day(forKey: "終了日") }
    var 終了時刻 : Time? { return time(forKey: "終了時刻") }
}

private let tableName = "スケジュール管理テーブル"

extension FileMakerDB {
    func find(at day:Day) -> [スケジュール管理詳細型] {
        let str = day.fmString
        var result : [スケジュール管理詳細型] = []
        if let list : [スケジュール管理詳細型] = find(layout: "スケジュール管理詳細", searchItems: [FileMakerSearchItem(fieldName:"開始日", fieldData:str), FileMakerSearchItem(fieldName: "終了日ソート", fieldData: "=")]) {
            result.append(contentsOf: list)
        }
        if let list :[スケジュール管理詳細型] = find(layout: "スケジュール管理詳細2", searchItems: [FileMakerSearchItem(fieldName:"開始日", fieldData:">=\(str)"), FileMakerSearchItem(fieldName: "終了日", fieldData: "<=\(str)")]) {
            result.append(contentsOf: list)
        }
        return result
    }
}
