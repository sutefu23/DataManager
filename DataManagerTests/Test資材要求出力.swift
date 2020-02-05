//
//  Test資材要求出力.swift
//  DataManagerTests
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestExportOrder: XCTestCase {
    let execDBTest = false

    func testOutput() {
        if self.execDBTest == false { return }
        
//        let order1 = "N"
//        let client1 = 社員型(社員番号: 23)!
//        let number1 = "990180M" // Cut 1.5t 1x2
//        let count1  = 3
//        let limit1 = Day(2020, 2, 16)
//        let memo1 = "発注登録テスト"
//        let record1 = 資材要求出力型(注文番号: order1, 社員: client1, 資材番号: number1, 数量: count1, 希望納期: limit1, 備考: memo1)

        let day2 = Day(year: 2020, month: 1, day: 30)
        let time2 = Time(8, 00)
        let order2 = "C"
        let client2 = 社員型(社員番号: 953)!
        let number2 = "5904" // セメダイン
        let count2 = 15
        let limit2 = Day(2020, 2, 16)
        let memo2 = "テスト出力発注登録"
        let record2 = 資材要求出力型(登録日: day2, 登録時間: time2, 注文番号: order2, 社員: client2, 資材番号: number2, 数量: count2, 希望納期: limit2, 備考: memo2)

//        let list = [record1, record2]
        let list = [record2]
        XCTAssertNoThrow(try list.exportToDB())
    }
}

