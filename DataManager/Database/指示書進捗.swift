//
//  指示書進捗.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

class 指示書型 {
    let record : FileMakerRecord
    
    init?(_ record:FileMakerRecord) {
        guard let numstr = record.string(forKey: "表示用伝票番号"), numstr.count >= 6 else { return nil }
        self.表示用伝票番号 = numstr
        let div = numstr.split(separator: "-")
        if div.count != 2 { return nil }
        if div[0].count >= 4 {
            guard let num = Int(div[0]+div[1]), num >= 100000 else { return nil }
            self.伝票番号 = num
        } else {
            guard let num = Int(div[1]), num >= 1 else { return nil }
            self.伝票番号 = num
        }
        self.record = record
    }
    
    let 伝票番号 : Int
    let 表示用伝票番号 : String
    var 伝票種類 : 伝票種類型 { return record.伝票種類(forKey: "伝票種類")! }
    var 伝票状態 : 伝票状態型 { return record.伝票状態(forKey: "伝票状態")! }
    var 工程状態 : 工程状態型 { return record.工程状態(forKey: "工程状態")! }
    
    lazy var 進捗情報 : [進捗型] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "指示書進捗内訳テーブル") else { return [] }
        return list.compactMap { 進捗型($0) }
    }()

}

class 進捗型 {
    let record : FileMakerRecord
    
    init?(_ record:FileMakerRecord) {
        self.record = record
    }
    
    var 社員名称 : String { return record.string(forKey: "社員名称")! }
    var 工程名称 : String { return record.string(forKey: "工程名称")! }
    var 作業内容 : 作業内容型 { return record.作業内容(forKey: "進捗コード")! }
    var 登録日 : Day { return record.day(forKey: "登録日")! }
    var 登録時間 : Time { return record.time(forKey: "登録時間")! }
    var 登録日時 : Date { return record.date(dayKey: "登録日", timeKey: "登録時間")! }

}

extension FileMakerDB {
    func find(伝票番号:Int? = nil, 伝票種類:伝票種類型? = nil, 製作納期:Day? = nil) -> [指示書型]? {
        var items = [FileMakerSearchItem]()
        if let num = 伝票番号 {
            let item = FileMakerSearchItem(fieldName:"伝票番号", fieldData:"\(num)")
            items.append(item)
        }
        if let type = 伝票種類 {
            let item = FileMakerSearchItem(fieldName:"伝票種類", fieldData:"\(type.fmString)")
            items.append(item)
        }
        if let day = 製作納期 {
            let item = FileMakerSearchItem(fieldName:"製作納期", fieldData:"\(day.fmString)")
            items.append(item)
        }
        if items.isEmpty { return nil }
        let list : [FileMakerRecord]? = find(layout: "エッチング指示書テーブル詳細", searchItems: items)
        return list?.compactMap { 指示書型($0) }
    }
}
