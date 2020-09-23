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
        guard 製品名称.contains("コイル") else { return }
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
        self.種類 = "コイル"
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
public let コイル優先度: [図番型: Double] = {
    var map: [図番型: Double] = [:]
    let baseValue = Double(coilList.count) * 2
    for (図番, 優先度) in coilList {
        map[図番] = baseValue - 優先度
    }
    return map
}()
public let コイル図番Set: Set<図番型> = Set<図番型>(coilList.map { $0.図番 })

public let コイル資材一覧: [資材型] = {
    return coilList.compactMap { 資材型(図番: $0.図番) }
}()

private let coilList: [(図番: 図番型, 優先度: Double)] = [
    ("992177",  1),
    ("992178",  2),
    ("992179",  3),
    ("992180",  4),
    ("992181",  5),
    ("992184",  6),
    ("992187",  7),
    ("992194",  8),
    ("992192",  9),
    ("992183", 10),
    ("992186", 11),
    ("992189", 12),
    ("992191", 13),
    ("992182", 14),
    ("992185", 15),
    ("992188", 16),
    ("992190", 17),
    ("991531", 18),
    ("991533", 19),
    ("991534", 20),
    ("991707", 21),
    ("991708", 22),
    ("991709", 23),
    ("991710", 24),
    ("991755", 25),
    ("991711", 26),
    ("991635", 27),
    ("991744", 28),
    ("991748", 29),
    ("991758", 30),
    ("991714", 31),
    ("991759", 32),
    ("991746", 33),
    ("991760", 34),
    ("991715", 35),
    ("991716", 36),
    ("991747", 37),
    ("991717", 38),
    ("991718", 39),
    ("991719", 40),
    ("991740", 41),
    ("991752", 42),
    ("991749", 43),
    ("991753", 44),
    ("991754", 45),
    ("991671", 46),
    ("991672", 47),
    ("991673", 48),
    ("991674", 49),
    ("991675", 50),
    ("991676", 51),
    ("991757", 52),
    ("997189", 53),
]
