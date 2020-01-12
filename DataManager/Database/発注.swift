//
//  発注.swift
//  DataManager
//
//  Created by manager on 8/9/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public class 発注型 {
    let record : FileMakerRecord
    
    init?(_ record:FileMakerRecord) {
        self.record = record
    }
    
    var 状態: String { return record.string(forKey: "状態")! }
    var 種類: String { return record.string(forKey: "種類")! }
}

public extension 発注型 {
    var 注文番号: String { return record.string(forKey: "注文番号")! }
    var 会社名: String { return record.string(forKey: "会社名")! }
    var 会社コード: String { return record.string(forKey: "会社コード")! }
    var 金額: String { return record.string(forKey: "金額")! }
    var 発注日: Date { return record.date(forKey: "発注日")! }
    var 図番: String { return record.string(forKey: "図番")! }
    var 版数: String { return record.string(forKey: "版数")! }
    var 製品名称: String { return record.string(forKey: "製品名称")! }
    var 規格: String { return record.string(forKey: "規格")! }
    var 規格2: String { return record.string(forKey: "規格2")! }
    var 納品日: Date { return record.date(forKey: "納品日")! }
    var 備考: String { return record.string(forKey: "備考")! }
    
    var 品名1: String { return self.製品名称 }
    var 品名2: String { return self.規格 }
    var 品名3: String { return self.規格2 }
    var 発注番号: String { return self.注文番号 }
}

extension 発注型 {
    
}
