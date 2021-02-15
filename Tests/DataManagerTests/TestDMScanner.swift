//
//  TestDMScanner.swift
//  DataManagerTests
//
//  Created by manager on 2020/05/28.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestDMScanner: XCTestCase {
    func testDropFirst() {
        var scanner: DMScanner
        
        scanner = DMScanner("abcde")
        scanner.dropFirst(3)
        XCTAssertEqual(scanner.substring, "de")
        
        scanner = DMScanner("abcde")
        scanner.dropFirst(0)
        XCTAssertEqual(scanner.substring, "abcde")
        
        scanner = DMScanner("abcde")
        scanner.dropFirst(-3)
        XCTAssertEqual(scanner.substring, "abcde")
        
        scanner = DMScanner("abcde")
        scanner.dropFirst(5)
        XCTAssertEqual(scanner.substring, "")
        
        scanner = DMScanner("abcde")
        scanner.dropFirst(6)
        XCTAssertEqual(scanner.substring, "")
        
    }
    
    func testDropLast() {
        var scanner: DMScanner
        
        scanner = DMScanner("abcde")
        scanner.dropLast(3)
        XCTAssertEqual(scanner.substring, "ab")
        
        scanner = DMScanner("abcde")
        scanner.dropLast(0)
        XCTAssertEqual(scanner.substring, "abcde")
        
        scanner = DMScanner("abcde")
        scanner.dropLast(-3)
        XCTAssertEqual(scanner.substring, "abcde")
        
        scanner = DMScanner("abcde")
        scanner.dropLast(5)
        XCTAssertEqual(scanner.substring, "")
        
        scanner = DMScanner("abcde")
        scanner.dropLast(6)
        XCTAssertEqual(scanner.substring, "")
        
    }
    
    func testHasPrefix() {
        var scanner: DMScanner
        
        scanner = DMScanner("test.ita")
        XCTAssertEqual(scanner.hasPrefix(".ita"), false)
        XCTAssertEqual(scanner.hasPrefix("test"), true)
        XCTAssertEqual(scanner.hasPrefix("tesa"), false)
        
        XCTAssertEqual(scanner.hasPrefix("TEST", upperCased: true), true)
        XCTAssertEqual(scanner.hasPrefix("test", upperCased: true), false)
    }
    
    func testHasSuffix() {
        var scanner: DMScanner
        
        scanner = DMScanner("test.ita")
        XCTAssertEqual(scanner.hasSuffix(".ita"), true)
        XCTAssertEqual(scanner.hasSuffix("sita"), false)
        
        XCTAssertEqual(scanner.hasSuffix(".ITA", upperCased: true), true)
        XCTAssertEqual(scanner.hasSuffix(".ita", upperCased: true), false)
        XCTAssertEqual(scanner.hasSuffix("SITA", upperCased: true), false)
        
    }
    
    func testDropHeadSpaces() {
        var scanner: DMScanner
        scanner = DMScanner("asd"); scanner.dropHeadSpaces()
        XCTAssertEqual("asd", scanner.substring)
        
        scanner = DMScanner("  asd"); scanner.dropHeadSpaces()
        XCTAssertEqual("asd", scanner.substring)
        
        scanner = DMScanner("\t  asd"); scanner.dropHeadSpaces()
        XCTAssertEqual("asd", scanner.substring)
    }
    
    func testDropTailSpaces() {
        var scanner: DMScanner
        scanner = DMScanner("asd"); scanner.dropTailSpaces()
        XCTAssertEqual("asd", scanner.substring)
        
        scanner = DMScanner("asd "); scanner.dropTailSpaces()
        XCTAssertEqual("asd", scanner.substring)
        
        scanner = DMScanner("asd\t  "); scanner.dropTailSpaces()
        XCTAssertEqual("asd", scanner.substring)
    }
    
    func testScanCharacter() {
        var scanner: DMScanner
        var isOk: Bool
        
        scanner = DMScanner("abc:02")
        isOk = scanner.scanCharacter("a")
        XCTAssertEqual(isOk, true)
        XCTAssertEqual(scanner.substring, "bc:02")
        
        scanner = DMScanner("abc:02")
        isOk = scanner.scanCharacter("A")
        XCTAssertEqual(isOk, false)
        XCTAssertEqual(scanner.substring, "abc:02")
        
        scanner = DMScanner("abc:02")
        isOk = scanner.scanCharacter("c")
        XCTAssertEqual(isOk, false)
        XCTAssertEqual(scanner.substring, "abc:02")
    }
    
    func testScanUpTo() {
        var scanner: DMScanner
        var string: String?
        
        scanner = DMScanner("abc:02")
        string = scanner.scanUpTo(":")
        XCTAssertEqual(scanner.substring, "02")
        XCTAssertEqual(string, "abc")
        
        scanner = DMScanner("abc:02")
        string = scanner.scanUpTo("a")
        XCTAssertEqual(scanner.substring, "bc:02")
        XCTAssertEqual(string, "")
        
        scanner = DMScanner("abc:02")
        string = scanner.scanUpTo("?")
        XCTAssertEqual(scanner.substring, "abc:02")
        XCTAssertEqual(string, nil)
        
        scanner = DMScanner(" abc:02")
        scanner.skipSpaces = true
        string = scanner.scanUpTo("?")
        XCTAssertEqual(scanner.substring, "abc:02")
        XCTAssertEqual(string, nil)
    }
    
    func testScanInteger() {
        var scanner: DMScanner
        var value: Int?
        
        scanner = DMScanner("150")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, 150)
        
        scanner = DMScanner(" 150")
        XCTAssertEqual(scanner.skipSpaces, false)
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, " 150")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner(" 150", skipSpaces: true)
        XCTAssertEqual(scanner.skipSpaces, true)
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, 150)
        
        scanner = DMScanner("150.1")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, ".1")
        XCTAssertEqual(value, 150)
        
        scanner = DMScanner("+150,")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, ",")
        XCTAssertEqual(value, 150)
        
        scanner = DMScanner("-150  ")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "  ")
        XCTAssertEqual(value, -150)
        
        scanner = DMScanner("")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner("abc")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "abc")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner("+-150")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "+-150")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner("000x")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "x")
        XCTAssertEqual(value, 0)
        
        scanner = DMScanner("-150-")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "-")
        XCTAssertEqual(value, -150)
        
        scanner = DMScanner(" 150.1")
        scanner.skipSpaces = true
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, ".1")
        XCTAssertEqual(value, 150)
        
        scanner = DMScanner("+")
        value = scanner.scanInteger()
        XCTAssertEqual(scanner.substring, "+")
        XCTAssertEqual(value, nil)
    }
    
    func testScanDouble() {
        var scanner: DMScanner
        var value: Double?
        
        scanner = DMScanner("150")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, 150)
        
        scanner = DMScanner(" 150", skipSpaces: false)
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, " 150")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner(" 150")
        scanner.skipSpaces = true
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, 150)
        
        scanner = DMScanner("150.5")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, 150.5)
        
        scanner = DMScanner("+150,")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, ",")
        XCTAssertEqual(value, 150)
        
        scanner = DMScanner("-150  ")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "  ")
        XCTAssertEqual(value, -150)
        
        scanner = DMScanner("")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner("abc")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "abc")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner("+-150")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "+-150")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner("000x")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "x")
        XCTAssertEqual(value, 0)
        
        scanner = DMScanner("-150-")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "-")
        XCTAssertEqual(value, -150)
        
        scanner = DMScanner(" 150.5")
        scanner.skipSpaces = true
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, 150.5)
        
        scanner = DMScanner("+")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "+")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner(".")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, ".")
        XCTAssertEqual(value, nil)
        
        scanner = DMScanner(".5")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, 0.5)
        
        scanner = DMScanner("-5.")
        value = scanner.scanDouble()
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(value, -5)
        
    }
    
    func testScanParen() {
        var scanner: DMScanner
        var result: (left: String, contents:String)?
        
        scanner = DMScanner("asd")
        result = scanner.scanParen("(", ")")
        XCTAssertEqual(scanner.substring, "asd")
        XCTAssertNil(result)
        
        scanner = DMScanner(" (asd)", skipSpaces: false)
        result = scanner.scanParen("(", ")")
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(result?.left, " ")
        XCTAssertEqual(result?.contents, "asd")
        
        scanner = DMScanner("   (asd)", skipSpaces: true)
        result = scanner.scanParen("(", ")")
        XCTAssertEqual(scanner.substring, "")
        XCTAssertEqual(result?.left, "")
        XCTAssertEqual(result?.contents, "asd")
        
        scanner = DMScanner(" (asd)s", skipSpaces: false)
        result = scanner.scanParen("(", ")")
        XCTAssertEqual(scanner.substring, "s")
        XCTAssertEqual(result?.left, " ")
        XCTAssertEqual(result?.contents, "asd")
        
        scanner = DMScanner("x(ag(sg)gd))")
        result = scanner.scanParen("(", ")")
        XCTAssertEqual(scanner.substring, ")")
        XCTAssertEqual(result?.left, "x")
        XCTAssertEqual(result?.contents, "ag(sg)gd")
        
        scanner = DMScanner(" )a(sd)s")
        scanner.skipSpaces = true
        result = scanner.scanParen("(", ")")
        XCTAssertEqual(scanner.substring, ")a(sd)s")
        XCTAssertNil(result)
        
        scanner = DMScanner(" a c (sd)s")
        scanner.skipSpaces = true
        result = scanner.scanParen("(", ")")
        XCTAssertEqual(scanner.substring, "s")
        XCTAssertEqual(result?.left, "a c")
        XCTAssertEqual(result?.contents, "sd")
        
        scanner = DMScanner("x( a g(s g)g d))")
        result = scanner.scanParen("(", ")")
        XCTAssertEqual(scanner.substring, ")")
        XCTAssertEqual(result?.left, "x")
        XCTAssertEqual(result?.contents, " a g(s g)g d")
    }
    
    func testScanString() {
        var scanner: DMScanner
        var isMatch: Bool
        
        scanner = DMScanner("abcdefg")
        isMatch = scanner.scanString("abc")
        XCTAssertEqual(isMatch, true)
        XCTAssertEqual(scanner.substring, "defg")
        
        scanner = DMScanner("abcdefg", upperCased: true)
        isMatch = scanner.scanString("ABC")
        XCTAssertEqual(isMatch, true)
        XCTAssertEqual(scanner.substring, "DEFG")
        //        XCTAssertEqual(scanner.originalSubstring, "defg")
        
        scanner = DMScanner("cdefg")
        isMatch = scanner.scanString("abc")
        XCTAssertEqual(isMatch, false)
        XCTAssertEqual(scanner.substring, "cdefg")
        
        scanner = DMScanner("cdefg")
        isMatch = scanner.scanString("cdefgh")
        XCTAssertEqual(isMatch, false)
        XCTAssertEqual(scanner.substring, "cdefg")
    }
    
    func testScanString2() {
        var scanner: DMScanner
        scanner = DMScanner("ボルトM5", normalizedFullHalf: true, upperCased: true, skipSpaces: true)
        scanner.scanString("ボルト")
        XCTAssertEqual(scanner.string, "M5")
        
        scanner = DMScanner("電源M5", normalizedFullHalf: true, upperCased: true, skipSpaces: true)
        scanner.skipMatchString("電源ボルト")
        XCTAssertEqual(scanner.string, "M5")
    }
    
    func testScanTime() {
        var scanner: DMScanner
        scanner = DMScanner("17:03")
        XCTAssertEqual(scanner.scanTime(), Time(17, 3))

        scanner = DMScanner("00:00")
        XCTAssertEqual(scanner.scanTime(), Time(0, 0))

        scanner = DMScanner("1:49")
        XCTAssertEqual(scanner.scanTime(), Time(1, 49))

        scanner = DMScanner(" 1:49", skipSpaces: true)
        XCTAssertEqual(scanner.scanTime(), Time(1, 49))

        scanner = DMScanner(" 1:49")
        XCTAssertEqual(scanner.scanTime(), nil)

        scanner = DMScanner("17:3")
        XCTAssertEqual(scanner.scanTime(), nil)

        scanner = DMScanner("17:003")
        XCTAssertEqual(scanner.scanTime(), nil)

        scanner = DMScanner("24:03")
        XCTAssertEqual(scanner.scanTime(), nil)

        scanner = DMScanner("012:03")
        XCTAssertEqual(scanner.scanTime(), nil)

        scanner = DMScanner("07:60")
        XCTAssertEqual(scanner.scanTime(), nil)

        scanner = DMScanner("A17:03")
        XCTAssertEqual(scanner.scanTime(), nil)

        scanner = DMScanner("17:03:53")
        XCTAssertEqual(scanner.scanTime(), Time(17, 3, 53))

        scanner = DMScanner("17:03:53:")
        XCTAssertEqual(scanner.scanTime(), nil)
        scanner = DMScanner("17:03:3")
        XCTAssertEqual(scanner.scanTime(), nil)
        scanner = DMScanner("17:03:003")
        XCTAssertEqual(scanner.scanTime(), nil)
        
        scanner = DMScanner("23:59OCN")
        XCTAssertEqual(scanner.scanTime(), Time(23, 59))
        XCTAssertEqual(scanner.string, "OCN")
    }
    
    func testScanUpToTime() {
        var scanner: DMScanner
        scanner = DMScanner("G01C9:2H17:03ZZZ")
        var result = scanner.scanUpToTime()
        XCTAssertEqual(result?.left, "G01C9:2H")
        XCTAssertEqual(result?.time, Time(17, 03))
        XCTAssertEqual(scanner.string, "ZZZ")

        scanner = DMScanner("ICE34:60Cre")
        result = scanner.scanUpToTime()
        XCTAssertNil(result)
        XCTAssertEqual(scanner.string, "ICE34:60Cre")

        scanner = DMScanner(" G01 C 9:2H17:03Z ZZ", skipSpaces: true)
        result = scanner.scanUpToTime()
        XCTAssertEqual(result?.left, "G01C9:2H")
        XCTAssertEqual(result?.time, Time(17, 03))
        XCTAssertEqual(scanner.string, "Z ZZ")
    }
    
    func testScanUpToString() {
        var scanner: DMScanner
        scanner = DMScanner("abcQWEgg2")
        XCTAssertEqual(scanner.scanUpToString("WE2"), nil)
        XCTAssertEqual(scanner.scanUpToString("WEg"), "abcQ")
        XCTAssertEqual(scanner.string, "g2")
    }
    
    // MARK: - 逆方向スキャン
    func testReverseInteger() {
        var scanner: DMScanner
        scanner = DMScanner("aaa-100c")
        XCTAssertEqual(scanner.reverseScanInteger(), nil)
        XCTAssertEqual(scanner.scanString("aaa-100"), true)
        XCTAssertEqual(scanner.reverseScanInteger(), -100)
        
        scanner = DMScanner("aaa-100c")
        XCTAssertEqual(scanner.scanString("aaa-100c"), true)
        XCTAssertEqual(scanner.reverseScanInteger(), nil)
    }
    
    func testReverseScanCharacter() {
        var scanner: DMScanner
        scanner = DMScanner("aaa-100c")
        XCTAssertEqual(scanner.reverseScanCharacter("a"), false)

        scanner.scanString("aaa-")
        let index = scanner.startIndex
        
        XCTAssertEqual(scanner.reverseScanCharacter("a"), false)
        XCTAssertEqual(index, scanner.startIndex)

        XCTAssertEqual(scanner.string, "100c")
        XCTAssertEqual(scanner.reverseScanCharacter("-"), true)
        XCTAssertNotEqual(index, scanner.startIndex)
    }
    
    func testReverseScanDay() {
        var scanner: DMScanner
        scanner = DMScanner("a10/9 sa")
        scanner.skipSpaces = true
        scanner.scanString("a10/9")
        scanner.dropHeadSpaces()
        XCTAssertEqual(scanner.string, "sa")

        XCTAssertEqual(scanner.reverseScanDay(), Day(10,9))
        XCTAssertEqual(scanner.string, "10/9 sa")
    }
    
    func test全角2文字() {
        var scanner: DMScanner

        scanner = DMScanner("a漢字bbc")
        XCTAssertEqual(scanner.drop(全角2文字: 0), "")
        XCTAssertEqual(scanner.string, "a漢字bbc")

        scanner = DMScanner("a漢字bbc")
        XCTAssertEqual(scanner.drop(全角2文字: 1), "a")
        XCTAssertEqual(scanner.string, "漢字bbc")

        scanner = DMScanner("a漢字bbc")
        XCTAssertEqual(scanner.drop(全角2文字: 2), "a")
        XCTAssertEqual(scanner.string, "漢字bbc")

        scanner = DMScanner("a漢字bbc")
        XCTAssertEqual(scanner.drop(全角2文字: 3), "a漢")
        XCTAssertEqual(scanner.string, "字bbc")

        scanner = DMScanner("a漢字bbc")
        XCTAssertEqual(scanner.drop(全角2文字: 4), "a漢")
        XCTAssertEqual(scanner.string, "字bbc")
        
        scanner = DMScanner("a漢字bbc")
        XCTAssertEqual(scanner.drop(全角2文字: 5), "a漢字")
        XCTAssertEqual(scanner.string, "bbc")

        scanner = DMScanner("a漢字bbc")
        XCTAssertEqual(scanner.drop(全角2文字: 6), "a漢字b")
        XCTAssertEqual(scanner.string, "bc")
        
        scanner = DMScanner("a漢字bbc")
        XCTAssertEqual(scanner.drop(全角2文字: 100), "a漢字bbc")
        XCTAssertEqual(scanner.string, "")
    }
    
    func testScanSuffix() {
        var scanner: DMScanner
        
        scanner = DMScanner("HLよこ")
        XCTAssertEqual(scanner.scanSuffix("たて"), false)
        XCTAssertEqual(scanner.string, "HLよこ")

        XCTAssertEqual(scanner.scanSuffix("よこ"), true)
        XCTAssertEqual(scanner.string, "HL")
    }
}
