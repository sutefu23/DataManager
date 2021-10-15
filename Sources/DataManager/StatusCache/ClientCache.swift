//
//  取引先キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 取引先キャッシュ型: DMDBCache<会社コード型, 取引先型> {
    public static let shared: 取引先キャッシュ型 = 取引先キャッシュ型(lifeSpan: 1*60*60, nilCache: false) {
        return try 取引先型.find(会社コード: $0)
    }
    
    func 現在取引先(会社コード: 会社コード型) throws -> 取引先型? {
        return try find(会社コード, noCache: true)
    }
    
    func キャッシュ取引先(会社コード: 会社コード型) throws -> 取引先型? {
        return try find(会社コード, noCache: false)
    }
}
