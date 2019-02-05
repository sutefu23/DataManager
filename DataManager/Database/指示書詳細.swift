//
//  指示書詳細.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 指示書詳細型 : FileMakerRecord {
    public var 表示用伝票番号 : String { return string(forKey: "表示用伝票番号")! }
    public var 伝票種類 : 伝票種類型 { return 伝票種類(forKey: "伝票種類")! }
    public var 伝票状態 : 伝票状態型 { return 伝票状態(forKey: "伝票状態")! }
    public var 工程状態 : 工程状態型 { return 工程状態(forKey: "工程状態")! }
    
    public lazy var 進捗情報 : [指示書進捗型] = {
        guard let list : [指示書進捗型] = self.portal(forKey: "指示書進捗内訳テーブル") else { return [] }
        return list
    }()
}

public class 指示書進捗型 : FileMakerRecord {
    public var 社員名称 : String { return string(forKey: "社員名称")! }
    public var 工程名称 : String { return string(forKey: "工程名称")! }
    var 登録日 : Day { return day(forKey: "登録日")! }
    var 登録時間 : Time { return time(forKey: "登録時間")! }
    public var 登録日時 : Date { return date(dayKey: "登録日", timeKey: "登録時間")! }
}

extension FileMakerDB {
    func find(伝票番号:Int? = nil, 伝票種類:伝票種類型? = nil, 製作納期:Date? = nil) -> [指示書詳細型]? {
        var items = [FileMakerSearchItem]()
        if let num = 伝票番号 {
            let item = FileMakerSearchItem(fieldName:"伝票番号", fieldData:"\(num)")
            items.append(item)
        }
        if let type = 伝票種類 {
            let item = FileMakerSearchItem(fieldName:"伝票種類", fieldData:"\(type.fmString)")
            items.append(item)
        }
        if let date = 製作納期 {
            let item = FileMakerSearchItem(fieldName:"製作納期", fieldData:"\(date.day.fmString)")
            items.append(item)
        }
        if items.isEmpty { return nil }
        let list : [指示書詳細型]? = find(layout: "エッチング指示書テーブル詳細", searchItems: items)
        return list
    }
}
