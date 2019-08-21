//
//  カレンダ情報.swift
//  DataManager
//
//  Created by manager on 8/20/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct カレンダ情報型 : 工程図データ型 {
    public static let filename = "calendar.tsv"
    public static let header = "カレンダID\tカレンダ名称\t適用開始日\t適用終了日\t開始時刻\t終了時刻\t曜日\tEOR"

    public var カレンダID : Int
    public var カレンダ名称 : String
    public var 適用開始日 : Day?
    public var 適用終了日 : Day?
    public var 開始時刻 : Time?
    public var 終了時刻 : Time?
    public var 曜日 : 工程図型.曜日型?

    public init(カレンダID: Int, カレンダ名称: String) {
        self.カレンダID = カレンダID
        self.カレンダ名称 = カレンダ名称
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
