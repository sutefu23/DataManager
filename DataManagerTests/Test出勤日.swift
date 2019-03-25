//
//  Test出勤日.swift
//  DataManagerTests
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestIsHoliday: XCTestCase {
    func testDynamicIsHoliday() {
        XCTAssertTrue(Day(2019,1,1).isHoliday)
        XCTAssertFalse(Day(2019,1,7).isHoliday)
        XCTAssertTrue(Day(2019,1,1).dynamicIsHoliday)
        XCTAssertFalse(Day(2019,1,7).dynamicIsHoliday)
        XCTAssertTrue(Day(2019,1,1).dynamicIsHoliday)
        XCTAssertTrue(Day(2019,3,31).dynamicIsHoliday)
    }

}
