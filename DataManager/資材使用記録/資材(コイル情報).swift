//
//  資材(コイル情報).swift
//  DataManager
//
//  Created by manager on 2020/04/15.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 資材コイル情報型: 資材情報型 {
    public private(set) var 材質: String = ""
    public private(set) var 表面: String = ""
    public private(set) var 板厚: Double = 0
    public private(set) var 高さ: Double = 0
    public private(set) var 種類: String = ""
    
    public init(製品名称: String, 規格: String) {
        var scanner = DMScanner(製品名称, normalizedFullHalf: true)
        let 製品名称 = scanner.string
        if 製品名称.contains("コイル") { self.種類 = "コイル" }
        guard let type = scanner.scanUpTo("板") else { return }
        self.材質 = type
        scanner.dropHeadSpaces()
        guard let surface = scanner.scanUpTo(" ") else { return }
        self.表面 = surface
        scanner = DMScanner(規格, normalizedFullHalf: true)
        guard let thin = scanner.scanDouble() else { return }
        self.板厚 = thin
        scanner.skip数字以外()
        guard let height = scanner.scanDouble() else { return }
        self.高さ = height
    }
    
    /// 有効ならtrue
    public var isValid: Bool {
        if 種類 != "コイル" { return false }
        if 材質.isEmpty { return false }
        if 表面.isEmpty { return false }
        if 板厚 <= 0 { return false }
        if 高さ <= 0 { return false }
        return true
    }
}

public var コイル資材一覧: [資材型] = {
    return coilList.compactMap { 資材型(図番: $0) }
}()

private var coilList: [String] = [
    "992177",
    "992178",
    "992179",
    "992180",
    "992181",
    "992184",
    "992187",
    "992194",
    "992192",
    "992183",
    "992186",
    "992189",
    "992191",
    "992182",
    "992185",
    "992188",
    "992190",
    "991531",
    "991533",
    "991534",
    "991707",
    "991708",
    "991709",
    "991710",
    "991755",
    "991711",
    "991635",
    "991744",
    "991748",
    "991714",
    "991746",
    "991715",
    "991716",
    "991747",
    "991717",
    "991718",
    "991719",
    "991740",
    "991752",
    "991749",
    "991753",
    "991757",
    "991754",
    "991671",
    "991672",
    "991673",
    "991674",
    "991675",
    "991676"
]
