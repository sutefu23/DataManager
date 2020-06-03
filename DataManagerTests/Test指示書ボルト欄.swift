//
//  Test指示書ボルト欄.swift
//  DataManagerTests
//
//  Created by manager on 2020/05/18.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestOrderBoltField: XCTestCase {
    var data: (名称: String, サイズ: String, 種類: 資材種類型, ソート順: Int)?
    
    func testBolt() {
        data = scanSource(ボルト欄: "M6x60L")
        if case .ボルト(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "6")
            XCTAssertEqual(length, 60)
        } else {
            XCTAssert(false)
        }
    }
    
    func testWasher() {
        data = scanSource(ボルト欄: "ワッシャー5φ")
        if case .ワッシャー(let size) = data?.種類 {
            XCTAssertEqual(size, "5")
        } else {
            XCTAssert(false)
        }
    }

    func testSWasher() {
        data = scanSource(ボルト欄: "Sワッシャー5φ")
        if case .Sワッシャー(let size) = data?.種類 {
            XCTAssertEqual(size, "5")
        } else {
            XCTAssert(false)
        }
    }

    func testNut() {
        data = scanSource(ボルト欄: "ナットM3")
        if case .ナット(let size) = data?.種類 {
            XCTAssertEqual(size, "3")
        } else {
            XCTAssert(false)
        }
    }
    
    func testPipe() {
        data = scanSource(ボルト欄: "6φx30L")
        if case .丸パイプ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "6")
            XCTAssertEqual(length, 30)
        } else {
            XCTAssert(false)
        }
        data = scanSource(ボルト欄: "浮かし21.7φx27L")
        if case .丸パイプ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "21.7")
            XCTAssertEqual(length, 27)
        } else {
            XCTAssert(false)
        }
        data = scanSource(ボルト欄: "配線10φx100L")
        if case .丸パイプ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "10")
            XCTAssertEqual(length, 100)
        } else {
            XCTAssert(false)
        }
        data = scanSource(ボルト欄: "電源用 8φx76.2L")
        if case .丸パイプ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "8")
            XCTAssertEqual(length, 76.2)
        } else {
            XCTAssert(false)
        }
    }
    
    func testTokusara() {
        data = scanSource(ボルト欄: "特皿M3*6L")
        if case .特皿(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "3")
            XCTAssertEqual(length, 6)
        } else {
            XCTAssert(false)
        }
    }
    
    func testSanrokutorau() {
        data = scanSource(ボルト欄: "サンロックトラスM4×10L")
        if case .サンロックトラス(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 10)
        } else {
            XCTAssert(false)
        }
    }
    
    func testSanrokkutokusara() {
        data = scanSource(ボルト欄: "サンロック特皿M4×6L")
        if case .サンロックトラス(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 6)
        } else {
            XCTAssert(false)
        }
    }

    func testtorasu() {
        data = scanSource(ボルト欄: "トラス5x15l")
        if case .トラス(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "5")
            XCTAssertEqual(length, 15)
        } else {
            XCTAssert(false)
        }
    }

    func testSurimuhead() {
        data = scanSource(ボルト欄: "スリムヘッドM4x6L")
        if case .スリムヘッド(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 6)
        } else {
            XCTAssert(false)
        }
    }

    func testCtapping() {
        data = scanSource(ボルト欄: "CタッピングM4x6L")
        if case .Cタッピング(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 6)
        } else {
            XCTAssert(false)
        }
    }

    
}
