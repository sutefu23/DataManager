//
//  作業バー.swift
//  DataManager
//
//  Created by manager on 2019/02/12.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class 作業バー型 {
    var 工程 : 工程型
    var 開始時間 : Date
    var 完了時間 : Date
    var hasStart : Bool
    var hasComplete : Bool
    
    init(工程: 工程型, 開始時間:Date, 完了時間:Date, hasStart : Bool, hasComplete : Bool) {
        self.工程 = 工程
        self.開始時間 = 開始時間
        self.完了時間 = 完了時間
        self.hasStart = hasStart
        self.hasComplete = hasComplete
    }
}
