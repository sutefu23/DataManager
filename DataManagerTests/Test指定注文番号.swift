//
//  Test指定注文番号.swift
//  DataManagerTests
//
//  Created by manager on 2020/05/28.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestOrderDirectNumberTest: XCTestCase {

    func testInit() {
        var number: 指定注文番号型?
        
        number = 指定注文番号型("")
        XCTAssertEqual(number, nil)
        
        number = 指定注文番号型("Q18-070078")
        XCTAssertEqual(number?.テキスト, "Q18-070078")
        XCTAssertEqual(number?.注文番号, 注文番号型.箱文字_半田)

        // 小文字・全角
        number = 指定注文番号型("n1８-070053")
        XCTAssertEqual(number?.テキスト, "N18-070053")
        XCTAssertEqual(number?.注文番号, 注文番号型.レーザ･ウォーター)

        // 欠損
        number = 指定注文番号型("18-060151")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("L8-060151")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("L18060151")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("L180-0151")
        XCTAssertEqual(number, nil)
        // 余分
        number = 指定注文番号型("AC18-060162")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("C018-060162")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("C18--060162")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("C18-0060162")
        XCTAssertEqual(number, nil)
        // スペース
        number = 指定注文番号型(" P20-011130")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("P 20-011130")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("P2 0-011130")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("P20 -011130")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("P20- 011130")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("P20-011 130")
        XCTAssertEqual(number, nil)
        number = 指定注文番号型("P20-011130 ")
        XCTAssertEqual(number, nil)
    }
}
