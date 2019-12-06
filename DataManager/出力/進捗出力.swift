//
//  進捗出力.swift
//  DataManager
//
//  Created by manager on 2019/12/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct 進捗出力型 {
    public let 登録日: Day
    public let 登録時間: Time

    public let 伝票番号: 伝票番号型
    public let 工程: 工程型
    public let 作業内容: 作業内容型
    public let 作業種別: 作業種別型

    public let 社員: 社員型
    public let 作業系列: 作業系列型?
    
    public init(伝票番号: 伝票番号型, 工程: 工程型, 作業内容: 作業内容型, 社員: 社員型, 登録日時間: Date, 作業種別: 作業種別型, 作業系列: 作業系列型?) {
        self.伝票番号 = 伝票番号
        self.工程 = 工程
        self.作業内容 = 作業内容
        self.社員 = 社員
        self.登録日 = 登録日時間.day
        self.登録時間 = 登録日時間.time
        self.作業種別 = 作業種別
        self.作業系列 = 作業系列
    }
    
    public init(_ progress: 進捗型) {
        self.伝票番号 = progress.伝票番号
        self.工程 = progress.工程
        self.作業内容 = progress.作業内容
        self.社員 = progress.作業者
        self.登録日 = progress.登録日
        self.登録時間 = progress.登録時間
        self.作業種別 = progress.作業種別
        self.作業系列 = progress.作業系列
    }
    
    func makeRecord(識別キー key: UUID) -> [String : String] {
        var record : [String : String] = [
            "識別キー" : key.uuidString,
            "登録日" : self.登録日.fmString,
            "登録時間" : self.登録時間.fmImportString,
            "伝票番号" : "\(self.伝票番号.整数値)",
            "工程コード" : self.工程.code,
            "作業内容コード" : self.作業内容.code,
            "社員コード" : self.社員.Hなし社員コード,
            "作業種別コード" : self.作業種別.code
        ]
        if let series = self.作業系列 {
            record["作業系列コード"] = series.系列コード
        }
        return record
    }
    
    /// 重複登録ならtrue
    func isDuplicate(to progress: 進捗出力型) -> Bool {
        if self.伝票番号 != progress.伝票番号 { return false }
        if self.工程 != progress.工程 { return false }
        if self.作業内容 != progress.作業内容 { return false }
        if self.作業種別 != progress.作業種別 { return false }
        if let series1 = self.作業系列, let series2 = progress.作業系列 {
            return series1 == series2
        } else {
            return self.社員 == progress.社員
        }
    }
    
    /// DB内に重複があればtrueを返す
    func isDuplicateInDB() -> Bool {
        guard let list = 進捗型.find(伝票番号: self.伝票番号, 工程: self.工程, 作業内容: self.作業内容)?.map({ 進捗出力型($0) }) else { return false }
        for progress in list {
            if progress.isDuplicate(to: self) { return true }
        }
        return false
    }
}

struct ProgressGroup : Hashable {
    let 伝票番号: Int
    let 工程: 工程型
    let 作業内容: 作業内容型
    let 作業種別: 作業種別型
    
    init(_ progress: 進捗出力型) {
        self.伝票番号 = progress.伝票番号.整数値
        self.工程 = progress.工程
        self.作業内容 = progress.作業内容
        self.作業種別 = progress.作業種別
    }
}

extension Array where Element == 進捗出力型 {
    public func exportToDB() {
        let uuid = UUID()
        
        let list = self.removeDuplicate().filter { !$0.isDuplicateInDB() }

        let db = FileMakerDB.pm_osakaname
        for progress in list {
            db.insert(layout: "DataAPI_ProcessInput", fields: progress.makeRecord(識別キー: uuid))
        }
        db.execute(layout: "DataAPI_ProcessInput", script: "DataAPI_ProcessInput_RecordSet", param: uuid.uuidString)
    }
    
    public func removeDuplicate() -> [進捗出力型] {
        let map = Dictionary(grouping: self) { ProgressGroup($0) }
        var result: [進捗出力型] = []
        for list in map.values {
            var list = list
            mainloop: while let test = list.first {
                list.remove(at: 0)
                for progress in list {
                    if test.isDuplicate(to: progress) {
                        continue mainloop
                    }
                }
                result.append(test)
            }
        }
        return result
    }
}
