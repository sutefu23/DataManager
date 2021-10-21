//
//  DataManagerTests.swift
//  DataManagerTests
//
//  Created by 四熊泰之 on 2019/01/27.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

extension XCTestCase {
    var readTestEnabled: Bool { false }
    var writeTestEnabled: Bool { readTestEnabled && false }
}

class DataManagerTests: XCTestCase {
    
    func testConnect() {
        guard readTestEnabled else { return }
        XCTAssertNotNil(社員型(社員番号: 23))
    }

    static var allTests = [
        ("testConnect", testConnect),
    ]    
}
