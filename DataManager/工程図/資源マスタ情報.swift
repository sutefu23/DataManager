//
//  資源マスタ情報.swift
//  DataManager
//
//  Created by manager on 8/20/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct 資源マスタ情報型: 工程図データ型 {
    public static let filename = "resource.tsv"
    public static let header = "資源ID\t資源名称\t山積みグラフ表示\tEOR"
    
    public var 資源ID: String
    public var 資源名称: String
    public var 山積みグラフ表示: 工程図型.山積みグラフ表示型? = nil
    
    public init(資源ID: String, 資源名称: String) {
        self.資源ID = 資源ID
        self.資源名称 = 資源名称
    }
    
    public func makeColumns() -> [String?] {
        return [
            self.資源ID,
            self.資源名称,
            self.山積みグラフ表示?.code
        ]
    }
}
