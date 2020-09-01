//
//  Test伝票番号.swift
//  DataManagerTests
//
//  Created by manager on 2020/05/08.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestOrderNumber: XCTestCase {

    func testString() {
        var number: 伝票番号型

        number = 伝票番号型(validNumber: 2004_15510)
        XCTAssertEqual(number.表示用文字列, "2004-15510")
                
        number = 伝票番号型(validNumber: 2004_5510)
        XCTAssertEqual(number.表示用文字列, "2004-5510")
        
        number = 伝票番号型(validNumber: 2004_0510)
        XCTAssertEqual(number.表示用文字列, "2004-0510")
        
        number = 伝票番号型(validNumber: 2004_0010)
        XCTAssertEqual(number.表示用文字列, "2004-0010")
        
        number = 伝票番号型(validNumber: 2004_0001)
        XCTAssertEqual(number.表示用文字列, "2004-0001")
        
        number = 伝票番号型(validNumber: 358491) // 2007/09/04受注
        XCTAssertEqual(number.表示用文字列, "07-358491")
        XCTAssertEqual(number.yearMonth, Month(2007, 09))
    }
}
