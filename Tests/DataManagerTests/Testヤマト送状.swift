//
//  Testヤマト送状.swift
//  DataManagerTests
//
//  Created by manager on 2021/07/09.
//

import XCTest
@testable import DataManager

class TestYamatoOkurijou: XCTestCase {
    /// ヤマト送状元番号型のテスト
    func testNumbers() {
        let data = ヤマト送状元番号型(rawValue: 29963492439) // "299634924396"
        XCTAssertEqual(data.rawValue, 29963492439)
        XCTAssertEqual(data.送状番号, "299634924396")
        
        let data2 = data.next
        XCTAssertEqual(data.rawValue+1, data2.rawValue)
        XCTAssertEqual(data2.送状番号, "299634924400")
    }
}
