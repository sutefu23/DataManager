//
//  TestTextReader.swift
//  NCEngine
//
//  Created by 四熊 泰之 on H26/08/14.
//  Copyright (c) 平成26年 四熊 泰之. All rights reserved.
//

import Foundation
import XCTest
@testable import DataManager

class TestTextReader: XCTestCase {

    let bundle = Bundle.module

    func testInit() {
        let reader = TextReader()
        XCTAssertNil(reader.url)
        XCTAssert(reader.nextLine() == "")
    }
    
    func testInitWithData() {
        guard let url = bundle.url(forResource: "maru", withExtension: "ita") else {
            XCTAssert(false)
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            XCTAssert(false, "no file")
            return
        }
        XCTAssert(data.count > 0)
        do {
            let reader = try TextReader(data: data, encoding: String.Encoding.shiftJIS)
            XCTAssertNil(reader.url)
            let line = reader.nextLine()
            XCTAssert(line == "iBase:10000,iVer:1")
        } catch let error {
            XCTAssert(false, "\(error)")
        }
    }
    
    func testInitWithNullText() {
        let text = TextReader("")
        XCTAssertEqual(text.lines, [""])
    }
    
    func testInitWithURL() {
        guard let url = bundle.url(forResource: "maru", withExtension: "ita") else {
            XCTAssert(false)
            return
        }
        let reader: TextReader
        do {
            reader = try TextReader(url: url, encoding: String.Encoding.shiftJIS)
            let path = reader.url?.lastPathComponent;
            XCTAssertEqual(path, "maru.ita")
            XCTAssertEqual(url, reader.url)
            let line = reader.nextLine()
            XCTAssert(line == "iBase:10000,iVer:1")
        } catch let error {
            XCTAssert(false, "\(error)")
        }
    }
    
    func testNextLine() {
        var reader = TextReader(["abc", "def", "ghi"])
        let line0 = reader.nextLine()
        XCTAssert(line0 != nil)
        XCTAssertEqual(line0!, "abc")
        XCTAssertEqual(reader.nextLine()!, "def")
        XCTAssertEqual(reader.nextLine()!, "ghi")
        XCTAssert(reader.nextLine() == nil)
        XCTAssert(reader.nextLine() == nil)
        
        reader = TextReader(["", "a", ""])
        XCTAssertEqual(reader.nextLine()!, "")
        XCTAssertEqual(reader.nextLine()!, "a")
        XCTAssertEqual(reader.nextLine()!, "")
        XCTAssert(reader.nextLine() == nil)
    }
    
    func testInsertNextLine() {
        let reader = TextReader(["abc", "def", "ghi"])
        reader.insertNextLine("00");
        XCTAssertEqual(reader.nextLine()!, "00")
        XCTAssertEqual(reader.nextLine()!, "abc")
        reader.insertNextLine("11");
        XCTAssertEqual(reader.nextLine()!, "11")
        XCTAssertEqual(reader.nextLine()!, "def")
        reader.insertNextLine("33");
        reader.insertNextLine("44");
        XCTAssertEqual(reader.nextLine()!, "44")
        XCTAssertEqual(reader.nextLine()!, "33")
        XCTAssertEqual(reader.nextLine()!, "ghi")
        reader.insertNextLine("22");
        XCTAssertEqual(reader.nextLine()!, "22")
        XCTAssert(reader.nextLine() == nil)
        reader.insertNextLine("99");
        XCTAssertEqual(reader.nextLine()!, "99")
        XCTAssert(reader.nextLine() == nil)
    }
    
    func testInitText() {
        let reader = TextReader("abc\ndef\nghi\n")
        var line = reader.nextLine()
        XCTAssert(line != nil)
        XCTAssertEqual(line!, "abc")
        line = reader.nextLine()
        XCTAssert(line != nil)
        XCTAssertEqual(line!, "def")
        line = reader.nextLine()
        XCTAssert(line != nil)
        XCTAssertEqual(line!, "ghi")
        if let line = reader.nextLine() {
            XCTAssertEqual(line, "")
            let line2 = reader.nextLine()
            XCTAssert(line2 == nil)
        }
        
    }
    
}
