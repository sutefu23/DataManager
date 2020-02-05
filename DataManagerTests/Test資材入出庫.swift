//
//  Test資材入出庫.swift
//  DataManagerTests
//
//  Created by manager on 2020/02/05.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestInOutObjects: XCTestCase {
    let execDBTest = false

    func testInput() {
        if self.execDBTest == false { return }

        
    }
}

private func makeTest1() -> 資材入出庫出力型 {
    let sizai = 資材型(図番: "990180M")
    let busyo = 部署型.加工
    let inCount = 5
    let outCount = 0
    let member = 社員型(社員番号: 23)!
    let type = 入力区分型.通常入出庫
    return 資材入出庫出力型(資材: sizai, 部署: busyo, 入庫数: inCount, 出庫数: outCount, 社員: member, 入力区分: type)
}
