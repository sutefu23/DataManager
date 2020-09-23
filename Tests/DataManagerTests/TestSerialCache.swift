//
//  TestSerialCache.swift
//  DataManagerTests
//
//  Created by 四熊泰之 on R 2/09/14.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestSerialCache: XCTestCase {
    func testGetAndSet() {
        let key = "test"
        let cache = SerialCache<String, Int>()
        XCTAssertNil(cache[key])
        cache[key] = 13
        XCTAssertEqual(cache[key], 13)
        cache[key] = 15
        XCTAssertEqual(cache[key], 15)
        cache[key] = nil
        XCTAssertNil(cache[key])
    }

    func testRemoveAll() {
        let cache = SerialCache<String, Int>()
        cache["test1"] = 10
        cache["tt"] = 12
        XCTAssertEqual(cache["test1"], 10)
        XCTAssertFalse(cache.isEmpty)
        cache.flush()
        XCTAssertTrue(cache.isEmpty)
        XCTAssertNil(cache["test1"])
        XCTAssertNil(cache["tt"])
    }
    
    func testIsEmpty() {
        let cache = SerialCache<Int, String>()
        XCTAssertTrue(cache.isEmpty)
        cache[6] = "a"
        XCTAssertFalse(cache.isEmpty)
        cache[6] = nil
        XCTAssertTrue(cache.isEmpty)
    }

}
