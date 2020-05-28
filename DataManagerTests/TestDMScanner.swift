//
//  TestDMScanner.swift
//  DataManagerTests
//
//  Created by manager on 2020/05/28.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestDMScanner: XCTestCase {

    func testScanString() {
        var scanner: DMScanner
        scanner = DMScanner("ボルトM5", normalizedFullHalf: true, upperCased: true, skipSpaces: true)
        scanner.scanString("ボルト")
        XCTAssertEqual(scanner.string, "M5")
        
        scanner = DMScanner("電源M5", normalizedFullHalf: true, upperCased: true, skipSpaces: true)
        scanner.skipMatchString("電源ボルト")
        XCTAssertEqual(scanner.string, "M5")
    }

}
