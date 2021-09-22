//
//  資材キャッシュ.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/03/08.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

public class 資材キャッシュ型: DMDBCache<図番型, 資材型> {
    public static let shared = 資材キャッシュ型(lifeTime: 4*60*60, nilCache: false) {
//        if $0 == "996068" {
//            return try 資材型.find(図番: "990120")
//        } else {
            return try 資材型.find(図番: $0)
//        }
    }
    
    public func 現在資材(図番: 図番型) throws -> 資材型? { try find(図番, noCache: true) }
    public func キャッシュ資材(図番: 図番型) throws -> 資材型? { try find(図番, noCache: false) }
}
