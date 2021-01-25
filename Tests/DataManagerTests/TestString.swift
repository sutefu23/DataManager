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
        XCTAssertEqual("ｱﾙｺｰﾙ".toJapaneseNormal, "アルコール")
        XCTAssertEqual("A-10".toJapaneseNormal, "A-10")
        XCTAssertEqual("ＢＣーＤ".toJapaneseNormal, "BC-D")
    }
    
    func testHeadNumber() {
        XCTAssertEqual("".headNumber, "")
        XCTAssertEqual("012".headNumber, "012")
        XCTAssertEqual("345a".headNumber, "345")
        XCTAssertEqual("a".headNumber, "")
        XCTAssertEqual("a55".headNumber, "")
    }
    
    func testIsASCIIXXX() {
        XCTAssertEqual(isASCIINumberValue(Character("/").asciiValue!), false)
        XCTAssertEqual(isASCIINumberValue(Character("0").asciiValue!), true)
        XCTAssertEqual(isASCIINumberValue(Character("5").asciiValue!), true)
        XCTAssertEqual(isASCIINumberValue(Character("9").asciiValue!), true)
        XCTAssertEqual(isASCIINumberValue(Character(":").asciiValue!), false)
        
        XCTAssertEqual(isASCIISpaceValue(Character(" ").asciiValue!), true)
        XCTAssertEqual(isASCIISpaceValue(Character("\t").asciiValue!), true)

        XCTAssertEqual(isASCIISignValue(Character("+").asciiValue!), true)
        XCTAssertEqual(isASCIISignValue(Character("-").asciiValue!), true)

        XCTAssertEqual(isASCIIDotValue(Character(".").asciiValue!), true)

        XCTAssertEqual(isASCIIExpValue(Character("e").asciiValue!), true)
        XCTAssertEqual(isASCIIExpValue(Character("E").asciiValue!), true)
        
        XCTAssertEqual(isASCIIAlphabetValue(Character("@").asciiValue!), false)
        XCTAssertEqual(isASCIIAlphabetValue(Character("A").asciiValue!), true)
        XCTAssertEqual(isASCIIAlphabetValue(Character("K").asciiValue!), true)
        XCTAssertEqual(isASCIIAlphabetValue(Character("Z").asciiValue!), true)
        XCTAssertEqual(isASCIIAlphabetValue(Character("[").asciiValue!), false)

        XCTAssertEqual(isASCIIAlphabetValue(Character("`").asciiValue!), false)
        XCTAssertEqual(isASCIIAlphabetValue(Character("a").asciiValue!), true)
        XCTAssertEqual(isASCIIAlphabetValue(Character("l").asciiValue!), true)
        XCTAssertEqual(isASCIIAlphabetValue(Character("z").asciiValue!), true)
        XCTAssertEqual(isASCIIAlphabetValue(Character("{").asciiValue!), false)
    }
    
    func testCSVColumns() {
        var columns: [String]
        
        // "なし
        columns = "".csvColumns
        XCTAssertEqual(columns, [""])

        columns = "dx".csvColumns
        XCTAssertEqual(columns.count, 1)
        XCTAssertEqual(columns[0], "dx")

        columns = ",".csvColumns
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0], "")
        XCTAssertEqual(columns[1], "")

        columns = "123,aadc".csvColumns
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0], "123")
        XCTAssertEqual(columns[1], "aadc")
        
        columns = "123,aadc,".csvColumns
        XCTAssertEqual(columns.count, 3)
        XCTAssertEqual(columns[0], "123")
        XCTAssertEqual(columns[1], "aadc")
        XCTAssertEqual(columns[2], "")

        // "あり
        columns = "\"\"".csvColumns
        XCTAssertEqual(columns, [""])

        columns = "\"dx\"".csvColumns
        XCTAssertEqual(columns.count, 1)
        XCTAssertEqual(columns[0], "dx")

        columns = "\"d,x\"".csvColumns
        XCTAssertEqual(columns.count, 1)
        XCTAssertEqual(columns[0], "d,x")

        columns = "\"\",\"\"".csvColumns
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0], "")
        XCTAssertEqual(columns[1], "")

        columns = "\"123\",\"aadc\"".csvColumns
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0], "123")
        XCTAssertEqual(columns[1], "aadc")
        
        columns = "\"123\",\"aad,c\",".csvColumns
        XCTAssertEqual(columns.count, 3)
        XCTAssertEqual(columns[0], "123")
        XCTAssertEqual(columns[1], "aad,c")
        XCTAssertEqual(columns[2], "")
        
        // 左のみ"
        columns = "\"123\",\"aadc".csvColumns
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0], "123")
        XCTAssertEqual(columns[1], "aadc")
    }
    
    func testTSVColumns() {
        var columns: [String]
        
        // "なし
        columns = "".tsvColumns
        XCTAssertEqual(columns, [""])

        columns = "dx".tsvColumns
        XCTAssertEqual(columns.count, 1)
        XCTAssertEqual(columns[0], "dx")

        columns = "\t".tsvColumns
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0], "")
        XCTAssertEqual(columns[1], "")

        columns = "123\taadc".tsvColumns
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0], "123")
        XCTAssertEqual(columns[1], "aadc")
        
        columns = "123\taadc\t".tsvColumns
        XCTAssertEqual(columns.count, 3)
        XCTAssertEqual(columns[0], "123")
        XCTAssertEqual(columns[1], "aadc")
        XCTAssertEqual(columns[2], "")
    }

}
