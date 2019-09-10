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
    var 社員名称 : String { return record.string(forKey: "社員名称")! }
    var 社員番号 : Int { return record.integer(forKey: "社員番号")! }
    var 作業者 : 社員型 { return 社員型(社員番号: self.社員番号, 社員名称: self.社員名称) }
}
