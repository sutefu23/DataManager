//
//  Test指示書.swift
//  DataManagerTests
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestOrder : XCTestCase {
    func testFind1() {
        let db = FileMakerDB.pm_osakaname
        
        let order : 指示書詳細型? = db.find(伝票番号: 19013047)?.first
        XCTAssertNotNil(order)
    }

}
