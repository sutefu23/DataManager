//
//  TestMonth.swift
//  DataManagerTests
//
//  Created by manager on 2019/10/29.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestMonth: XCTestCase {
    
    func testAdv() {
        let month = Month(2019, 6)
        
        XCTAssertEqual(month.advanced(by: -7), Month(2018, 11))
        XCTAssertEqual(month.advanced(by: -1), Month(2019, 5))
        XCTAssertEqual(month.advanced(by: 1), Month(2019, 7))
        XCTAssertEqual(month.advanced(by: 7), Month(2020, 1))
    }

    func testDiff() {
        let month = Month(2019, 6)

        XCTAssertEqual(month.distance(to: Month(2018, 11)), -7)
        XCTAssertEqual(month.distance(to: Month(2019, 5)), -1)
        XCTAssertEqual(month.distance(to: Month(2019, 7)), 1)
        XCTAssertEqual(month.distance(to: Month(2020, 1)), 7)
    }
}
