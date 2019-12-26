//
//  Test指示書.swift
//  DataManagerTests
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestOrder : XCTestCase {
    func testFind1() {
        var order : 指示書型?
        let num = 伝票番号型(validNumber: 19013047)
        order = (try? 指示書型.find(伝票番号: num))?.first
        XCTAssertEqual(num, order?.伝票番号)
        
        let day = Day(year: 2019, month: 2, day: 7)
        order = (try? 指示書型.find(製作納期: day))?.first
        XCTAssertEqual(order?.製作納期, day)
        
        order = (try? 指示書型.find(伝票種類: .箱文字, 製作納期: day))?.first
        XCTAssertEqual(order?.製作納期, day)
    }

    func testProperty() {
        var order : 指示書型?
        let num = 伝票番号型(validNumber: 19013047)
        order = (try? 指示書型.find(伝票番号: num))?.first
        
        XCTAssertEqual(num, order?.伝票番号)
        XCTAssertNotNil(order?.表示用伝票番号)
        XCTAssertNotNil(order?.略号)

        XCTAssertNotNil(order?.受注日)
        XCTAssertNotNil(order?.伝票種類)
        XCTAssertNotNil(order?.伝票状態)
        XCTAssertNotNil(order?.工程状態)
        XCTAssertNotNil(order?.承認状態)
        XCTAssertNotNil(order?.製作納期)
        XCTAssertNotNil(order?.出荷納期)

        XCTAssertNotNil(order?.社名)
        XCTAssertNotNil(order?.品名)
        XCTAssertNotNil(order?.仕様)
        XCTAssertNotNil(order?.文字数)
        XCTAssertNotNil(order?.セット数)
        XCTAssertNotNil(order?.管理用メモ)

        XCTAssertNotNil(order?.材質1)
        XCTAssertNotNil(order?.材質2)
        XCTAssertNotNil(order?.表面仕上1)
        XCTAssertNotNil(order?.表面仕上2)

        XCTAssertNotNil(order?.上段左)
        XCTAssertNotNil(order?.上段中央)
        XCTAssertNotNil(order?.上段右)
        XCTAssertNotNil(order?.下段左)
        XCTAssertNotNil(order?.下段中央)
        XCTAssertNotNil(order?.下段右)
        
        let list = order?.進捗一覧
        XCTAssertNotNil(list)
        XCTAssert(list!.count > 0)
        
        let list2 = order?.変更一覧
        XCTAssertNotNil(list2)
        
        let list3 = order?.添付資料一覧
        XCTAssertNotNil(list3)

        let list4 = order?.集荷時間一覧
        XCTAssertNotNil(list4)

        let list5 = order?.外注一覧
        XCTAssertNotNil(list5)

        let picURL = order?.図URL
        XCTAssertNotNil(picURL)
        
        let pic = order?.図
        XCTAssertNotNil(pic)
    }
}
