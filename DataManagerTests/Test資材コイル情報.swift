//
//  Test資材コイル情報.swift
//  DataManagerTests
//
//  Created by manager on 2020/05/08.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestSizaiCoil: XCTestCase {
    var info: 資材コイル情報型!

    func test1() {
        info = 資材コイル情報型(製品名称: "SUS304板　HL コイル　（片面青ﾃｰﾌﾟ）", 規格: "0.5ｔｘ18.5　")
        XCTAssertEqual(info.材質, "SUS304")
        XCTAssertEqual(info.表面, "HL")
        XCTAssertEqual(info.板厚, 0.5)
        XCTAssertEqual(info.高さ, 18.5)
        XCTAssertEqual(info.種類, "コイル")
        XCTAssertTrue(info.isValid)
    }
}
