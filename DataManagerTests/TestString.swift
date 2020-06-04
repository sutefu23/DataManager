//
//  TestString.swift
//  DataManagerTests
//
//  Created by manager on 2020/06/04.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestString: XCTestCase {

    func testMaru() {
        XCTAssertEqual(String(丸数字: -1), "(-1)")
        XCTAssertEqual(String(丸数字: 0), "⓪")
        XCTAssertEqual(String(丸数字: 10), "⑩")
        XCTAssertEqual(String(丸数字: 20), "⑳")
        XCTAssertEqual(String(丸数字: 21), "㉑")
        XCTAssertEqual(String(丸数字: 29), "㉙")
        XCTAssertEqual(String(丸数字: 35), "㉟")
        XCTAssertEqual(String(丸数字: 36), "㊱")
        XCTAssertEqual(String(丸数字: 50), "㊿")
        XCTAssertEqual(String(丸数字: 51), "(51)")
    }
    
}
