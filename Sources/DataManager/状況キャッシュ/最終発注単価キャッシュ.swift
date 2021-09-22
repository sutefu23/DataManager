//
//  最終発注単価キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/14.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

class 最終発注単価キャッシュ型: DMDBCache<図番型, Double> {
    static let shared: 最終発注単価キャッシュ型 = 最終発注単価キャッシュ型(lifeTime: 4*60*60, nilCache: true) {
        let result: Double?
        let list = try 発注型.find(資材番号: $0).sorted { $0.登録日 < $1.登録日 }
        guard let order = list.last, let value = Double(order.金額), let num = order.発注数量, value > 0 && num > 0 else { return nil }
        return value / Double(num)
    }
    
    subscript(図番: String) -> Double? {
        return try? find(図番, noCache: false)
    }
}

extension 資材型 {
    public var 最終発注単価: Double? {
        return 最終発注単価キャッシュ型.shared[self.図番]
    }
}
