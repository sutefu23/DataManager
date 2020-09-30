//
//  TestString.swift
//  DataManagerTests
//
//  Created by manager on 2020/06/04.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestString: XCTestCase {

    func testMaru() {
        XCTAssertEqual(String(丸数字: -1), "(-1)")
        XCTAssertEqual(String(丸数字: 0), "⓪")
        XCTAssertEqual(String(丸数字: 10), "⑩")
        XCTAssertEqual(String(丸数字: 20), "⑳")
        XCTAssertEqual(String(丸数字: 21), "㉑")
        XCTAssertEqual(String(丸数字: 29), "㉙")
        XCTAssertEqual(String(丸数字: 35), "㉟")
        XCTAssertEqual(String(丸数字: 36), "㊱")
        XCTAssertEqual(String(丸数字: 50), "㊿")
        XCTAssertEqual(String(丸数字: 51), "(51)")
    }
    
    func testKabuYUUJogai() {
        XCTAssertEqual("".remove㈱㈲, "")
        XCTAssertEqual("ＭＩ万世ステンレス ㈱".remove㈱㈲, "ＭＩ万世ステンレス")
        XCTAssertEqual("㈱ 松下商店".remove㈱㈲, "松下商店")
        XCTAssertEqual("㈱ 菊浜　九州支店".remove㈱㈲, "菊浜　九州支店")
    }
    
    func testToJaoaneseNormal() {
        XCTAssertEqual("abcde".toJapaneseNormal, "abcde")
        XCTAssertEqual("aｂcde".toJapaneseNormal, "abcde")
        XCTAssertEqual("あいうえお".toJapaneseNormal, "あいうえお")
        XCTAssertEqual("アイウエオ".toJapaneseNormal, "アイウエオ")
        XCTAssertEqual("アイウエｵ".toJapaneseNormal, "アイウエオ")
    }
    
}
