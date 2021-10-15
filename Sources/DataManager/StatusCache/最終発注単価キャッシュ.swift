//
//  最終発注単価キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/14.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 発注キャッシュ型: DMDBCache<図番型, [発注型]> {
    public static let shared: 発注キャッシュ型 = 発注キャッシュ型(lifeSpan: 4*60*60, nilCache: true) {
        let list = try 発注型.find(資材番号: $0).sorted { $0.登録日 < $1.登録日 }
        return list
    }
    
    public func 最終発注単価(_ itemId: 図番型, noCache: Bool = false) throws -> Double? {
        let list = try self.find(itemId, noCache: noCache)
        guard let order = list?.last, let value = order.金額, let num = order.発注数量, value > 0 && num > 0 else { return nil }
        return value / Double(num)
    }
}

//class 最終発注単価キャッシュ型: DMDBCache<図番型, Double> {
//    static let shared: 最終発注単価キャッシュ型 = 最終発注単価キャッシュ型(lifeSpan: 4*60*60, nilCache: true) {
//        let result: Double?
//        let list = try 発注型.find(資材番号: $0).sorted { $0.登録日 < $1.登録日 }
//        guard let order = list.last, let value = Double(order.金額), let num = order.発注数量, value > 0 && num > 0 else { return nil }
//        return value / Double(num)
//    }
//
//    subscript(図番: String) -> Double? {
//        return try? find(図番, noCache: false)
//    }
//}

extension 資材型 {
    public var 最終発注単価: Double? {
        return try? 発注キャッシュ型.shared.最終発注単価(self.図番)
    }
}
