//
//  カレンダ情報.swift
//  DataManager
//
//  Created by manager on 8/20/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct カレンダ情報型: 工程図データ型 {
    public static let filename = "calendar.tsv"
    public static let header = "カレンダID\tカレンダ名称\t適用開始日\t適用終了日\t開始時刻\t終了時刻\t曜日\tEOR"

    public var カレンダID: Int
    public var カレンダ名称: String
    public var 適用開始日: Day?
    public var 適用終了日: Day?
    public var 開始時刻: Time?
    public var 終了時刻: Time?
    public var 曜日 : 工程図型.曜日型?

    public init(カレンダID: Int, カレンダ名称: String, 適用開始日 : Day? = nil, 適用終了日 : Day?  = nil, 開始時刻 : Time? = nil, 終了時刻 : Time? = nil, 曜日 : 工程図型.曜日型? = nil) {
        self.カレンダID = カレンダID
        self.カレンダ名称 = カレンダ名称
        self.適用開始日 = 適用開始日
        self.適用終了日 = 適用終了日
        self.開始時刻 = 開始時刻
        self.終了時刻 = 終了時刻
        self.曜日 = 曜日
    }
    
    public func makeColumns() -> [String?] {
        return [
            "\(self.カレンダID)",
            self.カレンダ名称,
            self.適用開始日?.工程図年月日,
            self.適用終了日?.工程図年月日,
            self.開始時刻?.工程図時分,
            self.終了時刻?.工程図時分,
            self.曜日?.code
        ]
    }
}

public func makeカレンダー(from: Date, to: Date) -> [カレンダ情報型] {
    let from = from.day, to = to.day
    let cal0 = カレンダ情報型(カレンダID: 0, カレンダ名称: "デフォルト", 適用開始日: from, 適用終了日: to, 曜日:.土曜日)
    let cal1 = カレンダ情報型(カレンダID: 0, カレンダ名称: "デフォルト", 適用開始日: from, 適用終了日: to, 曜日:.日曜日)
    let cal2 = カレンダ情報型(カレンダID: 0, カレンダ名称: "デフォルト", 適用開始日: from, 適用終了日: to, 開始時刻: Time(0,0), 終了時刻: Time(8, 30))
    let cal3 = カレンダ情報型(カレンダID: 0, カレンダ名称: "デフォルト", 適用開始日: from, 適用終了日: to, 開始時刻: Time(12,0), 終了時刻: Time(13, 30))
    let cal4 = カレンダ情報型(カレンダID: 0, カレンダ名称: "デフォルト" ,適用開始日: from, 適用終了日: to, 開始時刻: Time(19,0), 終了時刻: Time(24, 0))
    return [cal0, cal1, cal2, cal3, cal4]
}
