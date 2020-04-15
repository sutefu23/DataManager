//
//  資材(コイル情報).swift
//  DataManager
//
//  Created by manager on 2020/04/15.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 資材コイル情報 {
    public private(set) var 材質: String
    public private(set) var 板厚: Double
    public private(set) var 高さ: Double
    public private(set) var mm単価: Double
    
    public init?(_ item: 資材型) {
        self.init(製品名称: item.製品名称, 規格: item.規格)
    }
    
    public init?(製品名称: String, 規格: String) {
        return nil
    }
}
