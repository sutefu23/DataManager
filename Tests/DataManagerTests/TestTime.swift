//
//  TestTime.swift
//  DataManagerTests
//
//  Created by manager on 2021/02/26.
//

import XCTest
@testable import DataManager

class TestTime: XCTestCase {
    func testInitNumbers() {
        XCTAssertEqual(Time(numbers: "2359"), Time(23, 59))
        XCTAssertEqual(Time(numbers: "0000"), Time(0, 0))
    }

    func testAppendMinutes() {
        var time: Time
        time = Time(0, 15).appendMinutes(0)
        XCTAssertEqual(time.hour, 0)
        XCTAssertEqual(time.minute, 15)

        time = Time(3, 15).appendMinutes(60)
        XCTAssertEqual(time.hour, 4)
        XCTAssertEqual(time.minute, 15)

        time = Time(3, 15).appendMinutes(1)
        XCTAssertEqual(time.hour, 3)
        XCTAssertEqual(time.minute, 16)

        time = Time(3, 15).appendMinutes(150)
        XCTAssertEqual(time.hour, 5)
        XCTAssertEqual(time.minute, 45)

        time = Time(23, 15).appendMinutes(50)
        XCTAssertEqual(time.hour, 0)
        XCTAssertEqual(time.minute, 5)

        time = Time(23, 15).appendMinutes(150)
        XCTAssertEqual(time.hour, 1)
        XCTAssertEqual(time.minute, 45)
        
        time = Time(0, 15).appendMinutes(25*60+50)
        XCTAssertEqual(time.hour, 2)
        XCTAssertEqual(time.minute, 5)
    }
}
