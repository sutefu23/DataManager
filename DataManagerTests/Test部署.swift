//
//  Test部署.swift
//  DataManagerTests
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestSections: XCTestCase {

    func testAll() {
        let all = 部署型.部署一覧
        let someAll = 部署型.有効部署一覧
        XCTAssertFalse(all.isEmpty)
        XCTAssertFalse(someAll.isEmpty)
        XCTAssertTrue(all.count > someAll.count)
    }

}
