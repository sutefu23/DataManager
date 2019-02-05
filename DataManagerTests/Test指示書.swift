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
        
        let num = 19013047
        let order : 指示書型? = 指示書型.find(伝票番号: num)?.first
        XCTAssertEqual(num, order?.伝票番号)
    }

}
