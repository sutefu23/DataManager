//
//  資材使用記録.swift
//  DataManager
//
//  Created by manager on 2020/04/16.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

struct 資材使用記録Data型: Equatable {
    static let dbName = "DataAPI_5"
    var 登録日時: Date
    
    var 伝票番号: 伝票番号型
    var 工程: 工程型
    var 作業者: 社員型
    var 資材: 資材型
    var 単価: Double
    
    var 用途: String?
    var 使用量: String?
    var 使用面積: Double?
    var 金額: Double?
    
    init(登録日時: Date, 伝票番号: 伝票番号型, 工程: 工程型, 作業者: 社員型, 資材: 資材型, 単価: Double, 用途: String?, 使用量: String?, 使用面積: Double?, 金額: Double?) {
        self.登録日時 = 登録日時
        self.伝票番号 = 伝票番号
        self.工程 = 工程
        self.作業者 = 作業者
        self.資材 = 資材
        self.単価 = 単価
        self.用途 = 用途
        self.使用量 = 使用量
        self.使用面積 = 使用面積
        self.金額 = 金額
    }
    
    init?(_ record: FileMakerRecord) {
        guard let date = record.date(dayKey: "登録日", timeKey: "登録時間") else { return nil }
        guard let number = record.伝票番号(forKey: "伝票番号") else { return nil }
        guard let process = record.工程(forKey: "工程コード") else { return nil }
        guard let worker = record.社員(forKey: "作業者コード") else { return nil }
        guard let item = record.資材(forKey: "図番") else { return nil }
        
        self.登録日時 = date
        self.伝票番号 = number
        self.工程 = process
        self.作業者 = worker
        self.資材 = item
        self.単価 = record.double(forKey: "単価") ?? item.単価 ?? 0
        self.使用量 = record.string(forKey: "使用量")
        self.用途 = record.string(forKey: "用途")
        self.使用面積 = record.double(forKey: "使用面積")
        self.金額 = record.double(forKey: "金額")
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["登録日"] = 登録日時.day.fmString
        data["登録時間"] = 登録日時.time.fmImportString
        data["伝票番号"] = "\(伝票番号.整数値)"
        data["工程コード"] = 工程.code
        data["作業者コード"] = 作業者.Hなし社員コード
        data["図番"] = 資材.図番
        data["単価"] = "\(単価)"
        data["使用量"] = 使用量
        data["用途"] = 用途
        if let area = 使用面積 { data["使用面積"] = "\(area)" }
        if let charge = self.金額 { data["金額"] = "\(charge)" }
        return data
    }
}

public class 資材使用記録型 {
    var original: 資材使用記録Data型
    var data: 資材使用記録Data型
    var recordID: String?

    init(_ data: 資材使用記録Data型) {
        self.original = data
        self.data = data
    }
}
