//
//  TestDay.swift
//  DataManagerTests
//
//  Created by 四熊泰之 on R 2/01/16.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestDay: XCTestCase {
    
    func testDiff() {
        let day0 = Day(year: 2020, month: 10, day: 10)
        let day1 = Day(year: 2020, month: 10, day: 17)
        let day2 = Day(year: 2020, month: 10, day: 24)
        
        var days = 0
        days = day1.distance(to: day0)
        XCTAssertEqual(days, -7)
        days = day1.distance(to: day2)
        XCTAssertEqual(days, 7)
    }
    
    func testAdv() {
        let day0 = Day(year: 2020, month: 10, day: 10)
        let day1 = Day(year: 2020, month: 10, day: 17)
        let day2 = Day(year: 2020, month: 10, day: 24)

        var day: Day
        day = day1.advanced(by: -7)
        XCTAssertEqual(day, day0)
        day = day1.advanced(by: 7)
        XCTAssertEqual(day, day2)
        
        XCTAssertEqual(day1.advanced(by: -1), Day(year: 2020, month: 10, day: 16))
        XCTAssertEqual(day1.advanced(by: 1), Day(year: 2020, month: 10, day: 18))
    }

}
