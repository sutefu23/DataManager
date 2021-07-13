//
//  送状番号出力.swift
//  DataManager
//
//  Created by manager on 2021/07/08.
//

import Foundation

enum 送状CheckError: String, LocalizedError {
    case 送り主郵便番号が空欄
    case 送り主電話番号が空欄
    case 送り主住所1が空欄
    case 届け先郵便番号が空欄
    case 届け先電話番号が空欄
    case 届け先住所1が空欄
    case 送り主住所1の文字数が多い
    case 送り主住所2の文字数が多い
    case 送り主名称の文字数が多い
    case 届け先住所1の文字数が多い
    case 届け先住所2の文字数が多い
    case 届け先住所3の文字数が多い
    case 届け先名称の文字数が多い
    case 品名の文字数が多い
    case 記事の文字数が多い
    case 着指定日が未入力
    case 福山依頼主コードが空欄

    var errorDescription: String? { self.rawValue }
}

extension 送状型 {
    public var recordID: String? { record.recordID }
    
    public var is送状未出力: Bool {
        let 送り状番号 = self.送り状番号.dropHeadSpaces
        if 送り状番号.contains("出力済") { return false } // 出力済の文言を含む場合、出力済みと考える
        return !self.is送り状番号設定済
    }
    
    public var is送り状番号設定済: Bool {
        guard let value = Int(送り状番号), value > 0 else { return false } // 数字にできないか数字が0以下の時は未出力
        return true
    }
    
    /// 送状番号をアップロードする
    public func upload送状番号() throws {
        guard let recordID = self.recordID, !recordID.isEmpty else { throw FileMakerError.update(message: "送状管理番号:\(self.管理番号) レコードIDが見つからない")}
        var fieldData = FileMakerQuery()
        fieldData["送り状番号"] = self.送り状番号

        let db = FileMakerDB.pm_osakaname
        try db.update(layout: 送状型.dbName, recordId: recordID, fields: fieldData)
    }
    
    /// サーバーの送状番号欄を「出力済」にする
    public func update送状番号欄出力済() throws {
        guard self.is送状未出力 && self.recordID != nil else { return }
        self.送り状番号 = "\(self.運送会社)出力済"
        try self.upload送状番号()
    }
}
