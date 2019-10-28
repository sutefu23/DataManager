//
//  指示書変更内容履歴.swift
//  DataManager
//
//  Created by manager on 8/16/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public enum 変更履歴種類型 : Hashable {
    case 指示書承認
    case 校正開始
    case 校正終了
    case 保留開始
    case 保留解除
    case その他
    
    init(_ text:String) {
        switch text {
        case "指示書承認":
            self = .指示書承認
        case "校正開始":
            self = .校正開始
        case "校正終了":
            self = .校正終了
        case "保留開始":
            self = .保留開始
        case "保留解除":
            self = .保留解除
        default:
            self = .その他
        }
    }
}

public class 指示書変更内容履歴型 {
    let record : FileMakerRecord
    
    init?(_ record:FileMakerRecord) {
        self.record = record
    }

    public lazy var 種類 : 変更履歴種類型 = { 変更履歴種類型(self.内容) }()
    public lazy var 日時 : Date = { return record.date(dayKey: "日付", timeKey: "時刻")! }()
    public lazy var 内容 : String = { self.record.string(forKey: "内容")! }()
    public lazy var 社員名称 : String = { return record.string(forKey: "社員名称")! }()
    public lazy var 社員番号 : Int = { return record.integer(forKey: "社員番号")! }()
    public lazy var 作業者 : 社員型 = { return 社員型(社員番号: self.社員番号, 社員名称: self.社員名称) }()
}
