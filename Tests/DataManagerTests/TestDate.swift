//
//  TestDate.swift
//  DataManagerTests
//
//  Created by manager on 2019/04/15.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager


class TestDate: XCTestCase {

    func testMonthFirstDay() {
        let date = Date(fmDate: "2018/4/15")!
        let date1 = date.monthFirstDay
        let day = date1.day
        XCTAssertEqual(day.year, 2018)
        XCTAssertEqual(day.month, 4)
        XCTAssertEqual(day.day, 1)
    }
    
}
