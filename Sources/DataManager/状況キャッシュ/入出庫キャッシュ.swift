//
//  入出庫キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/23.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public func flush入出庫キャッシュ() {
    入出庫キャッシュ型.shared.removeAllCache()
}

struct 入出庫キャッシュData型: DMCacheElement {
    let array: [資材入出庫型]
    
    var memoryFootPrint: Int { array.reduce(16) { $0 + $1.memoryFootPrint }}
}

class 入出庫キャッシュ型: DMDBCache<図番型, 入出庫キャッシュData型> {
    static let shared: 入出庫キャッシュ型 = 入出庫キャッシュ型(lifeTime: 15*60, nilCache: false) {
        return 入出庫キャッシュData型(array: try 資材入出庫型.find(図番: $0))
    }
    
    func 現在入出庫(of item: 資材型) throws -> [資材入出庫型] {
        return try find(item.図番, noCache: true)?.array ?? []
    }
    
    func キャッシュ入出庫(of item: 資材型) throws -> [資材入出庫型] {
        return try find(item.図番, noCache: false)?.array ?? []
    }
}
