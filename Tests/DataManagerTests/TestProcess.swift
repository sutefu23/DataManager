//
//  Test工程.swift
//  DataManagerTests
//
//  Created by manager on 2019/02/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

import XCTest
@testable import DataManager

class TestState : XCTestCase {
    func testMake() {
        var p : 工程型?
        p = 工程型("付属品準備")
        XCTAssertNotNil(p)
    }
    func testMiddleTime1() {
        let d = Date().day
        let from = Time(8, 00)
        let to = Time(18, 00)
        let middle = d.middleTime(from: from, to: to)
        XCTAssertEqual(middle, Time(13, 00), "8:00と18:00中間時間の取得:13:00時想定")
    }
    
    func testMiddleTime2() {
        let d = Date().day
        let from = Time(9, 30)
        let to = Time(17, 40)
        let middle = d.middleTime(from: from, to: to)
        XCTAssertEqual(middle, Time(13, 35), "9:30と17:40中間時間の取得:13:35想定")
    }
    
    func test作業日() {
        let tm1 = 工程型.管理.calc作業日(from: Date(year: 2021, month: 6, day: 1)!, to: Date(year: 2021, month: 6, day: 1)!)
        XCTAssertEqual(tm1, 0.5, "2021/6/1 8:40から6/1 17:30の作業日数をAM・PMの0.5刻みで算出:0.5を想定")
        let tm2 = 工程型.管理.calc作業日(from: Date(year: 2021, month: 6, day: 1)!, to: Date(year: 2021, month: 6, day: 2)!)
        XCTAssertEqual(tm2, 1.5, "2021/6/1 8:40から6/2 17:30の作業日数をAM・PMの0.5刻みで算出:1.5を想定")

    }
}

