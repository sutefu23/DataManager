//
//  供給資源情報.swift
//  DataManager
//
//  Created by manager on 8/20/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct 供給資源情報型: 工程図データ型 {
    public static let filename = "availability.tsv"
    public static let header = "資源ID\t供給開始日時\t供給終了日時\t供給量\tEOR"

    public var 資源ID: String
    public var 供給開始日時: Date
    public var 供給終了日時: Date
    public var 供給量: Double?
    
    public init(資源ID: String, 供給開始日時:Date, 供給終了日時: Date) {
        self.資源ID = 資源ID
        self.供給開始日時 = 供給開始日時
        self.供給終了日時 = 供給終了日時
    }
    
    public func makeColumns() -> [String?] {
        return [
            self.資源ID,
            self.供給開始日時.工程図日時,
            self.供給終了日時.工程図日時,
            self.供給量?.description
        ]
    }
}
