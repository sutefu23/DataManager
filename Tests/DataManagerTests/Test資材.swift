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
        guard let items = (try? 資材型.fetchAll()) else {
            XCTAssert(false)
            return
        }
        
        let firstItem = items[0]
        XCTAssertFalse(firstItem.製品名称.isEmpty)
        XCTAssertFalse(firstItem.図番.isEmpty)
        XCTAssertFalse(firstItem.版数.isEmpty)
        return
    }

    func testItemBarcode() {
        var code: String

        code = "01"
        XCTAssertEqual(code.図番バーコード, code)
        
        code = "12"
        XCTAssertEqual(code.図番バーコード, code)
        
        code = "123"
        XCTAssertEqual(code.図番バーコード, code)
        
        code = "1234"
        XCTAssertEqual(code.図番バーコード, code)
        
        code = "12345"
        XCTAssertEqual(code.図番バーコード, code)
        
        code = "123456"
        XCTAssertEqual(code.図番バーコード, code)
        

        code = "1234567"
        XCTAssertEqual(code.図番バーコード, code)

        code = "12345678"
        XCTAssertEqual(code.図番バーコード, "I"+code)

        code = "123456789"
        XCTAssertEqual(code.図番バーコード, "I"+code)

        code = "1234567890"
        XCTAssertEqual(code.図番バーコード, code)
        //
        
        code = "1234-5678"
        XCTAssertEqual(code.図番バーコード, nil)

        code = "12345678B"
        XCTAssertEqual(code.図番バーコード, code)
        
        code = "1234-56789"
        XCTAssertEqual(code.図番バーコード, nil)

        code = "12345678B9"
        XCTAssertEqual(code.図番バーコード, code)
        //
        code = "123456B"
        XCTAssertEqual(code.図番バーコード, code)
        
        code = "1234567B"
        XCTAssertEqual(code.図番バーコード, code)

    }
}
