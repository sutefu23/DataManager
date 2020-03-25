//
//  Test資材.swift
//  DataManagerTests
//
//  Created by manager on 2019/03/19.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestItem: XCTestCase {

    let doTest = false
    func testFetch() {
        if doTest == false { return }
        guard let items = (try? 資材型.fetch()) else {
            XCTAssert(false)
            return
        }
        
        let firstItem = items[0]
        XCTAssertFalse(firstItem.製品名称.isEmpty)
        XCTAssertFalse(firstItem.図番.isEmpty)
        XCTAssertFalse(firstItem.版数.isEmpty)
        return
    }

}
