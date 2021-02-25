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

}
