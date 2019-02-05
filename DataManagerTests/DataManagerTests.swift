//
//  DataManagerTests.swift
//  DataManagerTests
//
//  Created by 四熊泰之 on 2019/01/27.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class DataManagerTests: XCTestCase {

    func test接続() {
        let file = FileMakerDB(server: "192.168.1.153", filename: "laser" ,user: "admin", password: "ws")
        XCTAssertNil(file.activeToken)
        XCTAssertFalse(file.isConnect)
        let token = file.prepareToken()
        XCTAssertNotNil(token)
        let result = file.logout()
        XCTAssertNil(file.activeToken)
        XCTAssertTrue(result)
    }
    
    func test読み出し() {
        let file = FileMakerDB(server: "192.168.1.153", filename: "laser" ,user: "admin", password: "ws")
        XCTAssertNil(file.activeToken)
        guard let records : [FileMakerRecord] = file.fetch(layout: "窒素ガスタンク記録一覧") else {
            XCTAssert(false)
            return
        }
        XCTAssertFalse(records.isEmpty)
        let data = records.first?.string(forKey: "点検日時")
        XCTAssertNotNil(data)
        XCTAssert(data?.isEmpty == false)
        let result = file.logout()
        XCTAssertTrue(result)
    }

    func test検索() {
        let file = FileMakerDB(server: "192.168.1.153", filename: "laser" ,user: "admin", password: "ws")
        guard let records : [FileMakerRecord] = file.find(layout: "窒素ガスタンク記録一覧", searchItems:[
            FileMakerSearchItem(fieldName: "点検日時", fieldData: ">01/13/2019")
            ]) else {
                XCTAssert(false)
                return
        }
        XCTAssertFalse(records.isEmpty)
        let data = records.first?.string(forKey: "点検日時")
        XCTAssertNotNil(data)
        XCTAssert(data?.isEmpty == false)
        let result = file.logout()
        XCTAssertTrue(result)
    }
    
    func testRecord() {
        let file = FileMakerDB.laser
        guard let records : [FileMakerRecord] = file.find(layout: "三菱レーザー加工条件一覧", searchItems:[
            FileMakerSearchItem(fieldName: "材質", fieldData: "ソーダガラス")
            ]) else {
                XCTAssert(false)
                return
        }
        XCTAssertEqual(records.count, 1)
        let thin = records[0].double(forKey: "板厚")
        let power = records[0].integer(forKey: "出力")
        let date = records[0].date(forKey: "作成日")
        let material = records[0].string(forKey: "材質")
        XCTAssertNotNil(date)
        XCTAssertNotNil(material)
        XCTAssertNotNil(thin)
        XCTAssertNotNil(power)
    }

}
