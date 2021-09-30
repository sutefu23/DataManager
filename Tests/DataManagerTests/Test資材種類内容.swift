//
//  Test資材種類内容.swift
//  DataManagerTests
//
//  Created by manager on 2021/09/30.
//

import XCTest
@testable import DataManager

class TestItemInfo: XCTestCase {
    func test1() {
        var info: 資材種類内容型
        
        info = 資材種類内容型(種類: "")
        XCTAssertEqual(info.ボルト等種類, nil)
        XCTAssertEqual(info.旧図番, nil)
        XCTAssertEqual(info, 資材種類内容型(種類: " "))
        XCTAssertEqual(info.hashValue, 資材種類内容型(種類: " ").hashValue)

        info = 資材種類内容型(種類: "[991873M]")
        XCTAssertEqual(info.ボルト等種類, nil)
        XCTAssertEqual(info.旧図番, ["991873M"])

        
    }
    
}
