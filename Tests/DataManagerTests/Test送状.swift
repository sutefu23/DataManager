//
//  Test送状.swift
//  DataManagerTests
//
//  Created by manager on 2021/07/13.
//

import XCTest
@testable import DataManager

class TestOkurijou: XCTestCase {
    func testIsOUtput() {
        let order = try! 送状型.findDirect(送状管理番号: "4")!
        
        order.送り状番号 = 送り状番号型(状態: .入力なし)
        XCTAssertEqual(order.is送状未出力, true)
        
        order.送り状番号 = 送り状番号型(状態: .確定, 送り状番号: "565656565")
        XCTAssertEqual(order.is送状未出力, false)

        order.送り状番号 = 送り状番号型(状態: .運送会社割当待ち, 運送会社: .福山)
        XCTAssertEqual(order.is送状未出力, false)
    }

    func testUploadNumber() {
        let order = try! 送状型.findDirect(送状管理番号: "134784")!
        
        XCTAssertEqual(order.送り状番号.状態, .処理待ち)
        let original = order.送り状番号
        
        order.送り状番号 = 送り状番号型(状態: .運送会社割当待ち, 運送会社: .福山)
        try! order.upload送状番号()

        let order2 = try! 送状型.findDirect(送状管理番号: "134784")!
        XCTAssertEqual(order2.送り状番号.rawValue, "福山出力済")
        XCTAssertEqual(order2.送り状番号.状態, .運送会社割当待ち)

        order.送り状番号 = original
        try! order.upload送状番号()
    }
    
    func testOriginalNumber() {
        let number = 送り状番号型(状態: .仮設定, 送り状番号: "1234567890")
        XCTAssertEqual(number.ヤマト送状元番号, 123456789)
    }
}
