//
//  TestEtc.swift
//  DataManagerTests
//
//  Created by manager on 8/21/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestEtc: XCTestCase {

    func testInteger() {
        let val = 1
        let str = val.description
        XCTAssertEqual(val.description, str)
    }
}
