//
//  Test使用資材.swift
//  DataManagerTests
//
//  Created by manager on 2021/07/01.
//

import XCTest
@testable import DataManager

class TestShiyouShizai: XCTestCase {
    func testFind() {
        let day = Day(2020, 4, 22) // 登録がある日
        let list = try! 使用資材型.find(登録日: day)
        
        XCTAssertNotEqual(list.count, 0)
    }
    
    func testExportDB() {
        let order = 伝票番号型(validNumber: 2005_1590)
        var list = try! 使用資材型.find(伝票番号: order)
        let count = list.count
        
        let export = 使用資材出力型(登録日時: Date(), 伝票番号: order, 作業者: .川﨑_誠, 工程: .レーザー, 用途: nil, 図番: "309", 表示名: "SUSボルト", 使用量: "10本", 印刷対象: nil, 単位量: 1.0, 単位数: 10.0, 金額: 123, 原因工程: nil)
        try! [export].exportToDB()

        list = try! 使用資材型.find(伝票番号: order)
        XCTAssertEqual(list.count, count+1)
    }
}
