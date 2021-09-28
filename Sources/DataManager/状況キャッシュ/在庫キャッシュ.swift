//
//  在庫キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/18.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 在庫数キャッシュ型: DMDBCache<図番型, Int> {
    public static let shared: 在庫数キャッシュ型 = 在庫数キャッシュ型(lifeSpan: 10*60, nilCache: true) {
        guard let item2 = try 資材型.find(図番: $0) else {
            throw FileMakerError.notFound(message: " 資材 図番:\($0)")
        }
        return item2.レコード在庫数
    }
    
    func 現在在庫(of item: 資材型) throws -> Int {
        return try find(item.図番, noCache: true) ?? 0
    }
    
    func キャッシュ在庫数(of item: 資材型) throws -> Int {
        return try find(item.図番, noCache: false) ?? 0
    }
    
    public func flushCache(_ item: 図番型, 暫定個数: Int? = nil) {
        if let count = 暫定個数 {
            regist(count, forKey: item)
        } else {
            removeCache(forKey: item)
        }
    }
}
