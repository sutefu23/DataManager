//
//  Test板加工在庫.swift
//  DataManagerTests
//
//  Created by manager on 2020/06/04.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestItaKakouZaikoGata: XCTestCase {

    func testList() {
        let list = 板加工在庫一覧
        XCTAssertNotEqual(list.count, 0)
    }

}
