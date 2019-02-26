//
//  工程図.swift
//  DataManager
//
//  Created by manager on 2019/02/12.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 工程図型 {
    
    init(_ list:[作業型]) {
        
    }
    
    /// 工程図フォルダから工程読み出し
    public init(_ url:URL) throws {
        
    }
    
    public init(_ orders:[指示書型]) throws {
        var list : [(指示書型, [作業型])] = []
        for order in orders {
            let work = order.make作業ツリー()
            list.append((order, work))
        }
    }
    
    public func writeToURL(_ url:URL) throws {
        
    }
}
