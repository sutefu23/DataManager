//
//  資材出庫用紙.swift
//  DataManager
//
//  Created by manager on 2020/03/17.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 資材出庫用紙型 {
    public var 注文番号: 注文番号型
    public var 内訳: [資材出庫用紙内訳型]

}

public struct 資材出庫用紙内訳型 {
    public var 資材: 資材型
    public var 数量: Int?
}
