//
//  Test発注.swift
//  DataManagerTests
//
//  Created by manager on 2020/02/13.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestHattyuu: XCTestCase {
    let execDBTest = false

    func testFind2() {
        if execDBTest == false { return }
        let day = Day(2020, 2,12)
        let type = "N"
        let member = 社員型(社員番号: 023)
        let order = "5904"
        let volume = 2
        
        var result: [発注型] = []
        XCTAssertNoThrow(result = try 発注型.find(登録日: day))
        XCTAssertTrue(!result.isEmpty)
        XCTAssertNoThrow(result = try 発注型.find(注文番号: type))
        XCTAssertTrue(!result.isEmpty)
        XCTAssertNoThrow(result = try 発注型.find(社員: member))
        XCTAssertTrue(!result.isEmpty)
        XCTAssertNoThrow(result = try 発注型.find(資材番号: order))
        XCTAssertNoThrow(result = try 発注型.find(数量: volume))
    }

}
