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

        XCTAssertNotNil(order?.ボルト等1)
        XCTAssertNotNil(order?.ボルト等2)
        XCTAssertNotNil(order?.ボルト等3)
        XCTAssertNotNil(order?.ボルト等4)
        XCTAssertNotNil(order?.ボルト等5)
        XCTAssertNotNil(order?.ボルト等6)
        XCTAssertNotNil(order?.ボルト等7)
        XCTAssertNotNil(order?.ボルト等8)
        XCTAssertNotNil(order?.ボルト等9)
        XCTAssertNotNil(order?.ボルト等10)
        XCTAssertNotNil(order?.ボルト等11)
        XCTAssertNotNil(order?.ボルト等12)
        XCTAssertNotNil(order?.ボルト等13)
        XCTAssertNotNil(order?.ボルト等14)
        XCTAssertNotNil(order?.ボルト等15)

        XCTAssertNotNil(order?.ボルト本数1)
        XCTAssertNotNil(order?.ボルト本数2)
        XCTAssertNotNil(order?.ボルト本数3)
        XCTAssertNotNil(order?.ボルト本数4)
        XCTAssertNotNil(order?.ボルト本数5)
        XCTAssertNotNil(order?.ボルト本数6)
        XCTAssertNotNil(order?.ボルト本数7)
        XCTAssertNotNil(order?.ボルト本数8)
        XCTAssertNotNil(order?.ボルト本数9)
        XCTAssertNotNil(order?.ボルト本数10)
        XCTAssertNotNil(order?.ボルト本数11)
        XCTAssertNotNil(order?.ボルト本数12)
        XCTAssertNotNil(order?.ボルト本数13)
        XCTAssertNotNil(order?.ボルト本数14)
        XCTAssertNotNil(order?.ボルト本数15)

        let list = order?.進捗一覧
        XCTAssertNotNil(list)
        XCTAssert(list!.count > 0)
        
        let list2 = order?.変更一覧
        XCTAssertNotNil(list2)
        
//        let list3 = order?.添付資料一覧
//        XCTAssertNotNil(list3)
//
//        let list4 = order?.集荷時間一覧
//        XCTAssertNotNil(list4)

        let list5 = order?.外注一覧
        XCTAssertNotNil(list5)

        let picURL = order?.図URL
        XCTAssertNotNil(picURL)
        
        let pic = order?.図
        XCTAssertNotNil(pic)
    }
    
    var doTest2 = true
    func testDate2() {
        if doTest2 == false { return }
        let order = try! 指示書型.findDirect(伝票番号: 伝票番号型(validNumber: 2004_17486))!
        let date1: Date? = order.最終完了日時([.裏加工, .裏加工_溶接])
        let date2: Date? = order.最速開始日時([.研磨, .表面仕上, .塗装])
        XCTAssertEqual(date1?.day, Day(2020,5,11))
        XCTAssertEqual(date2?.day, Day(2020,5,11))

    }
}
