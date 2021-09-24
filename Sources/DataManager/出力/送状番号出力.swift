//
//  送状番号出力.swift
//  DataManager
//
//  Created by manager on 2021/07/08.
//

import Foundation

public enum 送状CheckError: String, LocalizedError {
    case 送り主郵便番号が空欄
    case 送り主電話番号が空欄
    case 送り主住所1が空欄
    case 届け先郵便番号が空欄
    case 届け先郵便番号が存在しない
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
    case 福山マスタに住所が存在しない
    case 福山マスタの住所と異なる
    case 福山依頼主コードが空欄
    case 指示書が不正
    case 着指定日が不正
    case 送り状管理番号が不明
    case 古い住所で出力
    public var errorDescription: String? { self.rawValue }
}

extension 送状型 {
    public var ヤマトCSV出力待ち: Bool {
        guard self.運送会社 == .ヤマト else { return false }
        switch self.送り状番号.状態 {
        case .処理待ち, .仮設定:
            return true
        case .確定, .仮番号印刷済み, .入力なし, .運送会社割当待ち:
            return false
        }
    }

    public var 福山CSV出力待ち: Bool {
        guard self.運送会社 == .福山 else { return false }
        switch self.送り状番号.状態 {
        case .処理待ち:
            return true
        case .確定, .仮設定, .仮番号印刷済み, .入力なし, .運送会社割当待ち:
            return false
        }
    }

    public var ヤマト出荷実績戻し待ち: Bool {
        guard self.運送会社 == .ヤマト else { return false }
        switch self.送り状番号.状態 {
        case .仮番号印刷済み:
            return true
        case .確定, .入力なし, .運送会社割当待ち, .処理待ち, .仮設定:
            return false
        }
    }
    
    public var is送状未出力: Bool {
        switch self.送り状番号.状態 {
        case .処理待ち, .入力なし, .運送会社割当待ち:
            return true
        case .仮設定, .確定, .仮番号印刷済み:
            return false
        }
    }
    
    public var is送り状番号設定済: Bool { // 予定も含む
        switch self.送り状番号.状態 {
        case .入力なし, .運送会社割当待ち, .処理待ち:
            return false
        case .確定, .仮設定, .仮番号印刷済み:
            return true
        }
    }
    
    /// 送状番号をアップロードする
    public func upload送状番号() throws {
        guard let recordId = self.recordId, !recordId.isEmpty else { throw FileMakerError.update(message: "送状管理番号:\(self.管理番号) レコードIDが見つからない")}
        var fieldData = FileMakerQuery()
        let data = self.送り状番号.ハイフンなし生データ
        fieldData["送り状番号"] = data

        let db = 送状型.db
        db.log("送り状番号変更", detail: "管理番号=\(recordId), 送り状番号=\(data)", level: .information)
        try db.update(layout: 送状型.layout, recordId: recordId, fields: fieldData)
    }
    
    /// サーバーの送状番号欄を「出力済」にする
    public func update送状番号欄出力済() throws {
        guard self.is送状未出力 && self.recordId != nil else { return }
        self.送り状番号 = 送り状番号型(状態: .運送会社割当待ち, 運送会社: self.運送会社)
        try self.upload送状番号()
    }
}
