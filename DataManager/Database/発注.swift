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
}

public extension 発注型 {
    var 金額合計 : String {
        return record.string(forKey: "金額合計") ?? ""
    }
    
    var 金額 : String {
        return record.string(forKey: "金額") ?? ""
    }

}
