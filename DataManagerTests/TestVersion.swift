//
//  TestVersion.swift
//  DataManagerTests
//
//  Created by manager on 2020/06/18.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestVersion: XCTestCase {

    func testVersion() {
        let v100 = Version("1.00", "")
        let v100_2 = Version("1.00", "")
        let v099 = Version("0.99", "")
        let v1002 = Version("1.00.2", "")
        let v10010 = Version("1.00.10", "")
        
        XCTAssert(v100 == v100)
        XCTAssert(v100 == v100_2)
        XCTAssert(v099 < v100)
        XCTAssert(v100 < v1002)
        XCTAssert(v1002 < v10010)
    }
    
    func testBuild() {
        let v100 = Version("1.00", "57")
        let v100_2 = Version("1.00", "57")
        let v100_3 = Version("1.00", "59")
        let v100_4 = Version("1.00", "")
        XCTAssertEqual(v100, v100_2)
        XCTAssertNotEqual(v100, v100_3)
        XCTAssertEqual(v100, v100_4)

        let v099 = Version("0.99", "56")
        let v099_1 = Version("0.99", "57")
        let v099_2 = Version("0.99", "58")
        let v099_3 = Version("0.99", "")
        XCTAssertLessThan(v099, v100)
        XCTAssertEqual(v099_1, v100)
        XCTAssertGreaterThan(v099_2, v100)
        XCTAssertLessThan(v099_3, v100)
    }
    
    func testCompare() {
        let v102 = Version("1.02")
        let v1021 = Version("1.021")
        
        XCTAssertLessThan(v102, v1021)
    }
}
