//
//  必要資源情報.swift
//  DataManager
//
//  Created by manager on 8/20/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct 必要資源情報型: 工程図データ型 {
    public static let filename = "requirement.tsv"
    public static let header = "工程ID\t資源ID\t必要量\tタイプ\tEOR"

    public var 工程ID: String
    public var 資源ID: String
    public var 必要量: Double
    public var タイプ: 工程図型.必要資源情報タイプ型?
    
    public init(工程ID: String , 資源ID: String, 必要量: Double) {
        self.工程ID = 工程ID
        self.資源ID = 資源ID
        self.必要量 = 必要量
    }
    
    public func makeColumns() -> [String?] {
        return [
            self.工程ID,
            self.資源ID,
            self.必要量.description,
            self.タイプ?.code
        ]
    }
}
