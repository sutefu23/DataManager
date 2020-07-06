//
//  記録.swift
//  DataManager
//
//  Created by manager on 2020/03/25.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

protocol 記録Data型: Equatable {
    static var dbName: String { get }
    init?(_ record: FileMakerRecord)
    var fieldData: FileMakerQuery { get }
}

public class 記録型 {
    
}
