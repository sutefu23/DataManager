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
    var data: (名称: String, サイズ: String, 種類: 資材種類型, ソート順: Double)?
    
    func testBolt() {
        data = try! scanSource(ボルト欄: "M6x60L", 伝票種類: .箱文字)
        if case .ボルト(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "6")
            XCTAssertEqual(length, 60)
        } else {
            XCTAssert(false)
        }
    }

    func testFB() {
        data = try! scanSource(ボルト欄: "FB2x10", 伝票種類: .箱文字)
        if case .FB(let thin, let height) = data?.種類 {
            XCTAssertEqual(thin, "2")
            XCTAssertEqual(height, 10)
        } else {
            XCTAssert(false)
        }
    }

    func test定番FB() {
        data = try! scanSource(ボルト欄: "FB3", 伝票種類: .箱文字)
        if case .定番FB(let size) = data?.種類 {
            XCTAssertEqual(size, "3")
        } else {
            XCTAssert(false)
        }
    }

    func testWasher() {
        data = try! scanSource(ボルト欄: "ワッシャー5φ", 伝票種類: .箱文字)
        if case .ワッシャー(let size) = data?.種類 {
            XCTAssertEqual(size, "5")
        } else {
            XCTAssert(false)
        }
    }

    func testSWasher() {
        data = try! scanSource(ボルト欄: "Sワッシャー5φ", 伝票種類: .箱文字)
        if case .Sワッシャー(let size) = data?.種類 {
            XCTAssertEqual(size, "5")
        } else {
            XCTAssert(false)
        }
    }

    func testNut() {
        data = try! scanSource(ボルト欄: "ナットM3", 伝票種類: .切文字)
        if case .ナット(let size) = data?.種類 {
            XCTAssertEqual(size, "3")
        } else {
            XCTAssert(false)
        }
        data = try! scanSource(ボルト欄: "ナットM3/8", 伝票種類: .箱文字)
        if case .ナット(サイズ: let size) = data?.種類 {
            XCTAssertEqual(size, "3/8")
        } else {
            XCTAssert(false)
        }
    }
    
    func testMPipe() {
        data = try! scanSource(ボルト欄: "6φx30L", 伝票種類: .箱文字)
        if case .丸パイプ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "6")
            XCTAssertEqual(length, 30)
        } else {
            XCTAssert(false)
        }
        data = try! scanSource(ボルト欄: "浮かし21.7φx27L", 伝票種類: .箱文字)
        if case .丸パイプ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "21.7")
            XCTAssertEqual(length, 27)
        } else {
            XCTAssert(false)
        }
        data = try! scanSource(ボルト欄: "配線10φx100L", 伝票種類: .箱文字)
        if case .丸パイプ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "10")
            XCTAssertEqual(length, 100)
        } else {
            XCTAssert(false)
        }
        data = try! scanSource(ボルト欄: "電源用 8φx76.2L", 伝票種類: .箱文字)
        if case .丸パイプ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "8")
            XCTAssertEqual(length, 76.2)
        } else {
            XCTAssert(false)
        }
    }
    
    func testTokusara() {
        data = try! scanSource(ボルト欄: "特皿M3*6L", 伝票種類: .箱文字)
        if case .特皿(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "3")
            XCTAssertEqual(length, 6)
        } else {
            XCTAssert(false)
        }
    }

    func testSara() {
        data = try! scanSource(ボルト欄: "皿M2x5L", 伝票種類: .箱文字)
        if case .皿(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "2")
            XCTAssertEqual(length, 5)
        } else {
            XCTAssert(false)
        }
    }
    
    func testSanrokutorau() {
        data = try! scanSource(ボルト欄: "サンロックトラスM4×10L", 伝票種類: .箱文字)
        if case .サンロックトラス(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 10)
        } else {
            XCTAssert(false)
        }
    }
    
    func testSanrokkutokusara() {
        data = try! scanSource(ボルト欄: "サンロック特皿M4×6L", 伝票種類: .箱文字)
        if case .サンロック特皿(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 6)
        } else {
            XCTAssert(false)
        }
    }

    func testtorasu() {
        data = try! scanSource(ボルト欄: "トラスm5x15l", 伝票種類: .箱文字)
        if case .トラス(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "5")
            XCTAssertEqual(length, 15)
        } else {
            XCTAssert(false)
        }
    }

    func testSurimuhead() {
        data = try! scanSource(ボルト欄: "スリムヘッドM4x6L", 伝票種類: .箱文字)
        if case .スリムヘッド(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 6)
        } else {
            XCTAssert(false)
        }
    }

    func testCtapping() {
        data = try! scanSource(ボルト欄: "CタッピングM4x6L", 伝票種類: .箱文字)
        if case .Cタッピング(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 6)
        } else {
            XCTAssert(false)
        }
    }
    
    func testNabe() {
        data = try! scanSource(ボルト欄: "ナベM4x10L", 伝票種類: .箱文字)
        if case .ナベ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 10)
        } else {
            XCTAssert(false)
        }
    }
    
    func testTekustNabe() {
        data = try! scanSource(ボルト欄: "テクスナベM4x19L", 伝票種類: .箱文字)
        if case .テクスナベ(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "4")
            XCTAssertEqual(length, 19)
        } else {
            XCTAssert(false)
        }
    }

    func testRokkaku() {
        data = try! scanSource(ボルト欄: "六角M3x10L", 伝票種類: .切文字)
        if case .六角(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "3")
            XCTAssertEqual(length, 10)
        } else {
            XCTAssert(false)
        }
    }
    
    func testStud() {
        data = try! scanSource(ボルト欄: "スタッドM5x30L", 伝票種類: .箱文字)
        if case .スタッド(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "5")
            XCTAssertEqual(length, 30)
        } else {
            XCTAssert(false)
        }
    }
    
    func testStarightStud() {
        data = try! scanSource(ボルト欄: "ストレートスタッドM3x10L", 伝票種類: .切文字)
        if case .ストレートスタッド(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "3")
            XCTAssertEqual(length, 10)
        } else {
            XCTAssert(false)
        }
    }

    func testALStud() {
        data = try! scanSource(ボルト欄: "ALスタッドM3x10L", 伝票種類: .箱文字)
        if case .ALスタッド(let size, let length) = data?.種類 {
            XCTAssertEqual(size, "3")
            XCTAssertEqual(length, 10)
        } else {
            XCTAssert(false)
        }
    }

//    func testCDStud() {
//        data = scanSource(ボルト欄: "CDスタッドM3x45L", 伝票種類: .箱文字)
//        if case .CDスタッド(let size, let length) = data?.種類 {
//            XCTAssertEqual(size, "3")
//            XCTAssertEqual(length, 45)
//        } else {
//            XCTAssert(false)
//        }
//    }

    func testTokuWasher() {
        data = try! scanSource(ボルト欄: "特寸ワッシャー2t×18φ×5.4φ", 伝票種類: .切文字)
        if case .特寸ワッシャー(サイズ: let size, 外径: let r1, 内径: let r2) = data?.種類 {
            XCTAssertEqual(size, "2")
            XCTAssertEqual(r1, 18)
            XCTAssertEqual(r2, 5.4)
        } else {
            XCTAssert(false)
        }
    }
}
