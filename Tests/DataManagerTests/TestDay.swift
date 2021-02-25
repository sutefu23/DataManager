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

    func testAppendWorkDays() {
        let day = Day(2020, 9,2)
        XCTAssertEqual(day.appendWorkDays(0), day)
        XCTAssertEqual(day.appendWorkDays(-1), day.prevWorkDay)
        XCTAssertEqual(day.appendWorkDays(-5), day.prevWorkDay.prevWorkDay.prevWorkDay.prevWorkDay.prevWorkDay)
        XCTAssertEqual(day.appendWorkDays(5), day.nextWorkDay.nextWorkDay.nextWorkDay.nextWorkDay.nextWorkDay)
    }
    
    func testRange() {
        let day = Day()
        let year = day.year
        XCTAssertEqual(ClosedRange<Day>("2020/10/11"), Day(2020,10,11)...Day(2020,10,11))
        XCTAssertEqual(ClosedRange<Day>("2020/10/11-2020/10/13"), Day(2020,10,11)...Day(2020,10,13))
        XCTAssertEqual(ClosedRange<Day>("2020/10/11-11/13"), Day(2020,10,11)...Day(2020,11,13))
        XCTAssertEqual(ClosedRange<Day>("10/11-13"), Day(year,10,11)...Day(year,10,13))
        XCTAssertEqual(ClosedRange<Day>("10/21-5"), Day(year,10,21)...Day(year,11,5))
    }
    func testInit422() {
        var day: Day?
        day = Day(yyyymmdd: "20210514")
        XCTAssertEqual(day?.year, 2021)
        XCTAssertEqual(day?.month, 5)
        XCTAssertEqual(day?.day, 14)
    }
    
    func testInitNumber() {
        XCTAssertEqual(Day(numbers: "0310"), Day(Day().year, 3, 10))
        XCTAssertEqual(Day(numbers: "211201"), Day(2021, 12, 1))
    }
}
