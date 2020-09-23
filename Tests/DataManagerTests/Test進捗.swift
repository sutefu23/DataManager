//
//  Test進捗.swift
//  DataManagerTests
//
//  Created by manager on 2019/03/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestProgress: XCTestCase {
    func testFind() {
        let day0331 = Day(2019, 3, 1)
        let state = 工程型.タップ
        
        let list = try? 進捗型.find(登録期間: day0331...day0331, 工程: state, 作業内容: .完了)
        XCTAssertNotNil(list)
        if let list = list {
            XCTAssertEqual(list.count, 3)
        }
    }

    func testNotFound() {
        do {
            let list = try 進捗型.find(登録期間: Day(1999, 7,1)...Day(1999, 7, 31))
            XCTAssert(list.isEmpty)
        } catch {
            fatalError()
        }
    }
//    func testFind2() {
//        let day0331 = Day(2019, 3, 1)
//
//        let list = try? 進捗型.find(登録期間: day0331...day0331, 作業内容: .完了)
//        XCTAssertNotNil(list)
//        if let list = list {
//            XCTAssertEqual(list.count, 3)
//        }
//    }

}
