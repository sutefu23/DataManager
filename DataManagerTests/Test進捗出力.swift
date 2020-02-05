//
//  TestOutputProgress.swift
//  DataManagerTests
//
//  Created by manager on 2019/12/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager


class TestOutputProgress: XCTestCase {
    let execDBTest = false

    func testOutputProgress() {
        if self.execDBTest == false { return }
        
        let num = 伝票番号型(validNumber: 1910_0011)
        let day = Day(2019, 10, 17)
        let time = Time(10, 15)
        let date = Date(day, time)
        let worker = 社員型(社員コード: "023")!
        let record = 進捗出力型(伝票番号: num, 工程: .レーザー, 作業内容: .完了, 社員: worker, 登録日時: date, 作業種別: .手直, 作業系列: .gx)
        let list = [record]
        
        XCTAssertNoThrow(try list.exportToDB())
    }
}

