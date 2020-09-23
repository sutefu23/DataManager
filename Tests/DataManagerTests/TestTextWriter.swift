//
//  TestTextWriter.swift
//  NCEngine
//
//  Created by 四熊 泰之 on 2014/11/05.
//  Copyright (c) 2014年 四熊 泰之. All rights reserved.
//

import Foundation
import XCTest
@testable import DataManager

class TestTextWriter: XCTestCase {

    func testInit() {
        let writer = TextWriter()
        XCTAssertEqual(writer.lines, [String]())
        XCTAssertEqual(writer.lines.count, 0)
        XCTAssertTrue(writer.isLineHead)
    }

    func testAppendString() {
        let writer = TextWriter()
        writer.appendString("ab")
        XCTAssertEqual(writer.lines.count, 1)
        XCTAssertEqual(writer.lines, ["ab"])
        XCTAssertFalse(writer.isLineHead)

        writer.appendString("cde")
        XCTAssertEqual(writer.lines.count, 1)
        XCTAssertEqual(writer.lines, ["abcde"])
        XCTAssertFalse(writer.isLineHead)
    }

    func testAppendLineEnd() {
        // テスト1
        var writer = TextWriter()
        writer.appendLineEnd()
        XCTAssertEqual(writer.lines, [""])
        XCTAssertEqual(writer.lines.count, 1)
        XCTAssertTrue(writer.isLineHead)

        // テスト2
        writer = TextWriter()
        writer.appendString("ab")
        writer.appendLineEnd()
        XCTAssertEqual(writer.lines, ["ab"])
        XCTAssertEqual(writer.lines.count, 1)

        writer.appendString("cde")
        XCTAssertEqual(writer.lines, ["ab", "cde"])
        XCTAssertEqual(writer.lines.count, 2)

        writer.appendString("f")
        XCTAssertEqual(writer.lines, ["ab", "cdef"])
        XCTAssertEqual(writer.lines.count, 2)

        writer.appendLineEnd()
        writer.appendString("g")
        XCTAssertEqual(writer.lines, ["ab", "cdef", "g"])
        XCTAssertEqual(writer.lines.count, 3)
        XCTAssertFalse(writer.isLineHead)
    }

    func testAppendLine() {
        // テスト1
        var writer = TextWriter()
        writer.appendLine("")
        XCTAssertEqual(writer.lines, [""])

        // テスト2
        writer = TextWriter()
        writer.appendLine("abc")
        writer.appendLine("def")
        writer.appendLine("ghi")
        XCTAssertEqual(writer.lines, ["abc", "def", "ghi"])
        XCTAssertTrue(writer.isLineHead)
        
        XCTAssertEqual(writer.lines[1], "def")
    }

    func testAppendLines() {
        let writer = TextWriter()
        writer.appendLines("abc", "def")
        writer.appendLines("ghi")
        XCTAssertEqual(writer.lines, ["abc", "def", "ghi"])
        XCTAssertTrue(writer.isLineHead)
    }

    func testAppendText() {
        var writer = TextWriter()
        writer.appendText("abc\ndef\nghi")
        XCTAssertEqual(writer.lines, ["abc", "def", "ghi"])
        XCTAssertFalse(writer.isLineHead)
        writer.appendText("\n")
        XCTAssertEqual(writer.lines, ["abc", "def", "ghi"])
        XCTAssertTrue(writer.isLineHead)
        // テスト2
        writer = TextWriter()
        writer.appendText("abc\ndef\nghi\n")
        XCTAssertEqual(writer.lines, ["abc", "def", "ghi"])
        XCTAssertTrue(writer.isLineHead)
        // テスト3
        writer = TextWriter()
        writer.appendText("\n\n\n")
        XCTAssertEqual(writer.lines, ["", "", ""])
        XCTAssertTrue(writer.isLineHead)
    }
    
    func testOutputStreamType() {
        var writer = TextWriter()
        print("abc", to:&writer)
        print("def", to:&writer)
        XCTAssertEqual(writer.lines.count, 2)
        XCTAssertEqual(writer.lines, ["abc", "def"])
    }
    
    func testAppendCharacter() {
        let writer = TextWriter()
        writer.appendCharacter("a", count:5)
        XCTAssertEqual(writer.lines, ["aaaaa"])
    }
    
    func testEncoding() {
        let writer = TextWriter()
        writer.appendLines("test", "漢字", "")
        var data : Data
        var reader : TextReader

        data = writer.dataWithEncoding(encoding: .shiftJIS, lineEndType: .crlf)
        reader = try! TextReader(data:data, encoding: .shiftJIS)
        XCTAssertEqual(reader.lines, writer.lines)

        data = writer.dataWithEncoding(encoding: .shiftJIS, lineEndType: .cr)
        reader = try! TextReader(data:data, encoding: .shiftJIS)
        XCTAssertEqual(reader.lines, writer.lines)

        data = writer.dataWithEncoding(encoding: .shiftJIS, lineEndType: .lf)
        reader = try! TextReader(data:data, encoding: .shiftJIS)
        XCTAssertEqual(reader.lines, writer.lines)
    }
}
