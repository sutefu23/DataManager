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

    func testMake2dig() {
        XCTAssertEqual(make2dig(0), "00")
        XCTAssertEqual(make2dig(9), "09")
        XCTAssertEqual(make2dig(10), "10")
        XCTAssertEqual(make2dig(-1), "-1")
        XCTAssertEqual(make2dig(100), "100")
        
        XCTAssertEqual(make2digS(0), " 0")
        XCTAssertEqual(make2digS(9), " 9")
        XCTAssertEqual(make2digS(10), "10")
        XCTAssertEqual(make2digS(-1), "-1")
        XCTAssertEqual(make2digS(100), "100")
    }
    
    func testMake4dig() {
        XCTAssertEqual(make4dig(0), "0000")
        XCTAssertEqual(make4dig(9), "0009")
        XCTAssertEqual(make4dig(10), "0010")
        XCTAssertEqual(make4dig(99), "0099")
        XCTAssertEqual(make4dig(100), "0100")
        XCTAssertEqual(make4dig(999), "0999")
        XCTAssertEqual(make4dig(1000), "1000")
        XCTAssertEqual(make4dig(9999), "9999")
        XCTAssertEqual(make4dig(10000), "10000")
        XCTAssertEqual(make4dig(99999), "99999")
        XCTAssertEqual(make4dig(-1), "-1")
    }
    
    func test26base(){
        XCTAssertEqual(from数字to26進数(1), "a")
        XCTAssertEqual(from数字to26進数(2), "b")
        XCTAssertEqual(from数字to26進数(26), "z")
        XCTAssertEqual(from数字to26進数(27), "aa")
        XCTAssertEqual(from数字to26進数(28), "ab")
        XCTAssertEqual(from数字to26進数(52), "az")
        XCTAssertEqual(from数字to26進数(53), "ba")
        XCTAssertEqual(from数字to26進数(0), "")
        XCTAssertEqual(from数字to26進数(-1), "")

        XCTAssertEqual(from26進数to数字("a"), 1)
        XCTAssertEqual(from26進数to数字("b"), 2)
        XCTAssertEqual(from26進数to数字("z"), 26)
        XCTAssertEqual(from26進数to数字("aa"), 27)
        XCTAssertEqual(from26進数to数字("ab"), 28)
        XCTAssertEqual(from26進数to数字("az"), 52)
        XCTAssertEqual(from26進数to数字("ba"), 53)
        XCTAssertEqual(from26進数to数字("あ"), 0)
        XCTAssertEqual(from26進数to数字("1"), 0)

        XCTAssertTrue("zdc2578".is26進数付きID())
        XCTAssertTrue("ab11".is26進数付きID())
        XCTAssertFalse("ab".is26進数付きID())
        XCTAssertFalse("11".is26進数付きID())

        XCTAssertEqual("abc11".filter26進数ID(), "abc")
        XCTAssertEqual("11".filter26進数ID(), "")
        XCTAssertEqual("a11".filter26進数ID(), "a")
        XCTAssertEqual("abc11zz".filter26進数ID(), "abc")

        XCTAssertEqual("abc11".filter26進数除外ID(), "11")
        XCTAssertEqual("11".filter26進数除外ID(), "11")
        XCTAssertEqual("a11".filter26進数除外ID(), "11")
        XCTAssertEqual("abc11zz".filter26進数除外ID(), "")
        
    }
    
    func test26baseNextId(){
        let codeSet1:Set = ["a123","b123","c4","321","d123"]
        XCTAssertEqual(next26進数コード("123", codeSet: codeSet1), "e123")

        let codeSet2:Set = ["c123","a123","354","321","d123","e123"]
        XCTAssertEqual(next26進数コード("123", codeSet: codeSet2), "f123")
    }
}
