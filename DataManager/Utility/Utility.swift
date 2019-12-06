//
//  Utility.swift
//  DataManager
//
//  Created by manager on 2019/12/06.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class DataManagerController {
    public func flushAllCache() {
        clear伝票番号Cache()
        flush工程名称DB()
        出勤日DB型.shared.flushCache()
        flush作業系列Cache()
    }
}

public let dataManager = DataManagerController()
