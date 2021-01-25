//
//  Test板加工在庫.swift
//  DataManagerTests
//
//  Created by manager on 2021/01/22.
//

import XCTest
@testable import DataManager

class TestItaKakouZaiko: XCTestCase {

    func testItiran() {
        let list = 板加工在庫一覧
        XCTAssertEqual(list.isEmpty, false)
    }

}
