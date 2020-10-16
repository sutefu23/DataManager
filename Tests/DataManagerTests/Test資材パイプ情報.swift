//
//  Test資材パイプ情報.swift
//  DataManagerTests
//
//  Created by manager on 2020/10/14.
//

import XCTest
@testable import DataManager

class TestSizaiPipeInfo: XCTestCase {

    func testInit() {
        var info: 資材パイプ情報型
        
        info = 資材パイプ情報型(図番: "996567", 規格: "HL2.0t38.5角5")
        XCTAssertEqual(info.仕上, .HL)
        XCTAssertEqual(info.板厚, "2.0")
        XCTAssertEqual(info.サイズ, "38.5")
        XCTAssertEqual(info.種類, .角)
        XCTAssertEqual(info.長さ, "5")
        
        info = 資材パイプ情報型(図番: "990992", 規格: "F1.2t19×10×4")
        XCTAssertEqual(info.仕上, .F)
        XCTAssertEqual(info.板厚, "1.2")
        XCTAssertEqual(info.サイズ.toJapaneseNormal, "19x10")
        XCTAssertEqual(info.種類, .角)
        XCTAssertEqual(info.長さ, "4")
    }
    
    func testList() {
        let list = 資材パイプリスト
        XCTAssertEqual(list.isEmpty, false)
    }
    

}
