//
//  Test指示書.swift
//  DataManagerTests
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestOrder : XCTestCase {
    func testFind1() {
        var order : 指示書型?
        let num = 19013047
        order = 指示書型.find(伝票番号: num)?.first
        XCTAssertEqual(num, order?.伝票番号)
        
        let day = Day(year: 2019, month: 2, day: 7)
        let date = Date(day)
        order = 指示書型.find(製作納期: date)?.first
        XCTAssertEqual(order?.製作納期, date)
        
        order = 指示書型.find(伝票種類: .箱文字, 製作納期: date)?.first
        XCTAssertEqual(order?.製作納期, date)
    }

}
