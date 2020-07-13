//
//  Test資材要求情報.swift
//  DataManagerTests
//
//  Created by manager on 2020/06/04.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestSizaiYoukyuujouhou: XCTestCase {

    func testInit() {
        var info: 資材要求情報型?
        info = 資材要求情報型(ボルト欄: "M6x60L", 数量欄: "30", セット数: 1, 伝票種類: .箱文字)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.is附属品, true)
        
        info = 資材要求情報型(ボルト欄: "+M6x60L", 数量欄: "30", セット数: 1, 伝票種類: .箱文字)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.is附属品, false)
        
        info = 資材要求情報型(ボルト欄: "特寸ワッシャー2t×18φ×5.4φ", 数量欄: "25", セット数: 1, 伝票種類: .箱文字)
        XCTAssertNotNil(info)
    }

}
