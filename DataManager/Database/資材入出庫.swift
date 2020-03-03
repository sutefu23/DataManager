//
//  資材入出庫.swift
//  DataManager
//
//  Created by manager on 2020/03/03.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 資材入出庫型 {
    let record: FileMakerRecord
    var 登録日: Day
    var 登録時間: Time
    var 社員: 社員型
    var 入力区分: 入力区分型
    var 資材: 資材型
    var 入庫数: Int
    var 出庫数: Int

    init?(_ record: FileMakerRecord) {
        self.record = record
        guard let day = record.day(forKey: "登録日") else { return nil }
        guard let time = record.time(forKey: "登録時間") else { return nil }
        guard let worker = record.社員(forKey: "社員番号") else { return nil }
        guard let type = record.入力区分(forKey: "入力区分") else { return nil }
        guard let item = record.資材(forKey: "資材番号") else { return nil }
        guard let input = record.integer(forKey: "入庫数") else { return nil }
        guard let output = record.integer(forKey: "出庫数") else { return nil }
        self.登録日 = day
        self.登録時間 = time
        self.社員 = worker
        self.入力区分 = type
        self.資材 = item
        self.入庫数 = input
        self.出庫数 = output
    }

}

extension 資材入出庫型 {
    public static let dbName = "DataAPI_12"
    
}
