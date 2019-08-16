//
//  指示書変更内容履歴.swift
//  DataManager
//
//  Created by manager on 8/16/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public class 指示書変更内容履歴型 {
    let record : FileMakerRecord
    
    init?(_ record:FileMakerRecord) {
        self.record = record
    }
    
    var 日時 : Date { return record.date(dayKey: "日付", timeKey: "時刻")! }
    var 内容 : String { return record.string(forKey: "内容")! }
    var 社員名 : String { return record.string(forKey: "社員名")! }
}
