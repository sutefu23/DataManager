//
//  Test工程.swift
//  DataManagerTests
//
//  Created by manager on 2019/02/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

import XCTest
@testable import DataManager

class TestState : XCTestCase {
    func testMake() {
        var p : 工程型?
        p = 工程型("付属品準備")
        XCTAssertNotNil(p)
    }
}

