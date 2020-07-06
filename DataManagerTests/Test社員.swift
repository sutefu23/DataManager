//
//  Test社員.swift
//  DataManagerTests
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestMember: XCTestCase {

    func testFetchAll() {
        let all = 社員型.全社員一覧
        XCTAssertFalse(all.isEmpty)
        XCTAssertGreaterThan(all.count, 100)
    }
}
