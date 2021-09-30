//
//  Test資材使用記録.swift
//  DataManagerTests
//
//  Created by manager on 2020/04/17.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager
let execDBTest = false

private let item1 = try! 資材キャッシュ型.shared.キャッシュ資材(図番: "992133B")! // 1.2t 2B 4x8
private let worker1 = 社員型(社員コード: "023")! // 四熊
private let order1 = try! 伝票番号キャッシュ型.shared.find("20041413")!
private let date1 = Date(year: 2020, month: 04, day: 17, hour: 15, minute: 30)!

class TestUseItemRecord: XCTestCase {

    func testRegist() {
        let use = 資材使用記録型(登録日時: date1, 伝票番号: order1, 工程: .フォーミング, 作業者: .関_雄也, 図番: item1.図番, 表示名: item1.標準表示名, 単価: item1.単価, 用途: "天板", 使用量: "100x100 3枚", 使用面積: 156, 単位量: (100.0*100.0)/(1219.0*2438.0), 単位数: 3, 金額: 782, 印刷対象: .全て, 原因工程: .none)
        XCTAssertEqual(use.登録日時, date1)
        XCTAssertEqual(use.伝票番号, order1)
        XCTAssertEqual(use.工程, .フォーミング)
        XCTAssertEqual(use.作業者, .関_雄也)
        XCTAssertEqual(use.図番, item1.図番)
        XCTAssertEqual(use.単価, item1.単価)
        XCTAssertEqual(use.用途, "天板")
        XCTAssertEqual(use.使用面積, 156)
        XCTAssertEqual(use.使用量, "100x100 3枚")
        XCTAssertEqual(use.単位量, (100.0*100.0)/(1219.0*2438.0))
        XCTAssertEqual(use.単位数, 3)
        XCTAssertEqual(use.金額, 782)
        XCTAssertEqual(use.印刷対象, .全て)
        
        guard execDBTest else { return }
        try? use.upload()
    }
}

