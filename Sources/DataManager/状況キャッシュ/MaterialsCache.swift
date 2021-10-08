//
//  資材キャッシュ.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/03/08.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

public class 資材キャッシュ型: DMDBCache<図番型, 資材型> {
    public static let shared = 資材キャッシュ型(lifeSpan: 4*60*60, nilCache: false) {
        return try 資材型.find(図番: $0) ?? 資材型.find新図番資材(元図番: $0).last
    }
    
    public func 現在資材(図番: 図番型) throws -> 資材型? {
        if 図番.isEmpty { return nil }
        return try find(図番, noCache: true)
    }
    public func キャッシュ資材(図番: 図番型) throws -> 資材型? {
        if 図番.isEmpty { return nil }
        return try find(図番, noCache: false)
    }
}
