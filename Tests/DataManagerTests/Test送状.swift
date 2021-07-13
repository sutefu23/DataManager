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
        
        order.送り状番号 = ""
        XCTAssertEqual(order.is送状未出力, true)
        
        order.送り状番号 = "565656565"
        XCTAssertEqual(order.is送状未出力, false)

        order.送り状番号 = "福山出力済"
        XCTAssertEqual(order.is送状未出力, false)
    }

    func testUploadNumber() {
        let order = try! 送状型.findDirect(送状管理番号: "134784")!
        
        XCTAssertEqual(order.送り状番号, "0")
        let original = order.送り状番号
        
        order.送り状番号 = "福山送状出力済"
        try! order.upload送状番号()

        let order2 = try! 送状型.findDirect(送状管理番号: "134784")!
        XCTAssertEqual(order2.送り状番号, "福山送状出力済")

        order.送り状番号 = original
        try! order.upload送状番号()
    }
}
