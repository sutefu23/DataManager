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

class 記録型<D: 記録Data型> {
    var original: D?
    var data: D
    public internal(set) var recordId: String?

    init?(_ record: FileMakerRecord) {
        guard let data = D(record) else { return nil }
        self.original = data
        self.data = data
        self.recordId = record.recordID
    }
    
    public var isChanged: Bool { original != data }

}
