//
//  Test管理資材型.swift
//  DataManagerTests
//
//  Created by manager on 2020/03/27.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestKanriSizai: XCTestCase {

    func testAnalyze() {
        var obj: 管理板材型
        // 1.0t　4×8
        obj = 管理板材型(資材: 資材型(図番: "990173M")!)
        XCTAssertEqual(obj.板厚, "1.0")
        XCTAssertEqual(obj.サイズ, "4x8")
        XCTAssertEqual(obj.高さ, 1219)
        XCTAssertEqual(obj.横幅, 2438)
//        // 2.0t　4×10(1250×2500)
//        obj = 管理板材型(資材: 資材型(図番: "992074")!)
//        XCTAssertEqual(obj.板厚, "2.0")
//        XCTAssertEqual(obj.サイズ, "4×10")
//        XCTAssertEqual(obj.高さ, 1250)
//        XCTAssertEqual(obj.横幅, 2500)
        // ST-4　4×8
//        obj = 管理板材型(資材: 資材型(図番: "880214")!)
//        XCTAssertEqual(obj.板厚, "1.5")
//        XCTAssertEqual(obj.サイズ, "4×8")
//        XCTAssertEqual(obj.高さ, 1219)
//        XCTAssertEqual(obj.横幅, 2438)
        // スミペックス透明　4.0t　1100×1350
        obj = 管理板材型(資材: 資材型(図番: "990772")!)
        XCTAssertEqual(obj.板厚, "4.0")
        XCTAssertEqual(obj.サイズ, "1100×1350")
        XCTAssertEqual(obj.高さ, 1100)
        XCTAssertEqual(obj.横幅, 1350)
    }

}
