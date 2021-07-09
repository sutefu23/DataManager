//
//  送状番号出力.swift
//  DataManager
//
//  Created by manager on 2021/07/08.
//

import Foundation

extension 送状型 {
    public var recordID: String? { record.recordID }
    
    /// 送状番号をアップロードする
    public func upload送状番号() throws {
        guard let recordID = self.recordID, !recordID.isEmpty else { throw FileMakerError.update(message: "レコードIDが見つからない")}
        var fieldData = FileMakerQuery()
        fieldData["送り状番号"] = self.送り状番号

        let db = FileMakerDB.system
        try db.update(layout: 送状型.dbName, recordId: recordID, fields: fieldData)
    }
}
