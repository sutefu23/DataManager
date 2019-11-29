//
//  Test指示書文字数.swift
//  DataManagerTests
//
//  Created by manager on 2019/11/26.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestOrderCounter: XCTestCase {
    func testInsertAndFind() {
        let num = 15011234
        let hnum = 5
        let ynum = 10
        let tnum = 15

        // 存在しないのを確認
        let objectx = 指示書文字数Data型.find(伝票番号: num)
        XCTAssertNil(objectx)
        if objectx != nil { return }
            
        // 新規登録
        let object0 = 指示書文字数Data型(伝票番号: num, 半田文字数: hnum, 溶接文字数: ynum, 総文字数: tnum)
        XCTAssertNotNil(object0)
        object0?.insert()

        // 検索
        guard let object = 指示書文字数Data型.find(伝票番号: num) else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(object.半田文字数, hnum)
        XCTAssertEqual(object.溶接文字数, ynum)
        XCTAssertEqual(object.総文字数, tnum)
        XCTAssertNotNil(object.recordId)
        
        // 編集
        object.半田文字数 = hnum+1
        object.溶接文字数 = nil
        object.総文字数 = tnum+3
        let result = object.update()
        XCTAssertTrue(result)

        // 検索2
        guard let object2 = 指示書文字数Data型.find(伝票番号: num) else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(object2.半田文字数, object.半田文字数)
        XCTAssertEqual(object2.溶接文字数, ynum.溶接文字数)
        XCTAssertEqual(object2.総文字数, tnum.総文字数)
        XCTAssertNotNil(object2.recordId)

        // 削除
        let response = object.delete()
        XCTAssertTrue(response)
    }

}
