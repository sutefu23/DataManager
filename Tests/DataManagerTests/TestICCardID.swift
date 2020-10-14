//
//  TestICCardID.swift
//  DataManagerTests
//
//  Created by manager on 2020/10/14.
//

import XCTest
@testable import DataManager

class TestICCardID: XCTestCase {
    var doTest = false
    
    func testReader() {
        guard doTest else { return }
        let reader = DMCardReader()
        let str = try! reader.scanCardID()
        XCTAssertNotNil(str)
    }

}
