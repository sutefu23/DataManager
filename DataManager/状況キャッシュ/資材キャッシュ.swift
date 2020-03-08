//
//  資材キャッシュ.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/03/08.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation


public class 資材キャッシュ型 {
    public static let shared = 資材キャッシュ型()
    
    struct CacheKey: Hashable {
        var 図番: String
    }
    struct CacheValue {
        var result: 資材型?
    }
    
    let lock = NSLock()
    var cache: [CacheKey: CacheValue] = [:]
    
    public subscript(図番: String) -> 資材型? {
        let key = CacheKey(図番: 図番)
        if let value = cache[key] { return value.result }
        let result = try? 資材型.find(図番: 図番)
        cache[key] = CacheValue(result: result)
        return result
    }
}
