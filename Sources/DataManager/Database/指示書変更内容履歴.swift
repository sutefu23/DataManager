//
//  指示書変更内容履歴.swift
//  DataManager
//
//  Created by manager on 8/16/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public enum 変更履歴種類型: Hashable {
    case 指示書承認
    case 校正開始
    case 校正終了
    case 保留開始
    case 保留解除
    case キャンセル
    case その他
    
    init(_ text: String) {
        switch text {
        case "指示書承認":
            self = .指示書承認
        case "校正開始":
            self = .校正開始
        case "校正終了":
            self = .校正終了
        case "保留開始":
            self = .保留開始
        case "保留解除":
            self = .保留解除
        default:
            if text.contains("キャンセル") {
                self = .キャンセル
            } else {
                self = .その他
            }
        }
    }
}

public struct 指示書変更内容履歴型: FileMakerImportRecord {
    public static let layout = "DataAPI_2"
    
    public let recordId: FileMakerRecordID?
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: Self.name, mes: key) }
        guard let 内容 = record.string(forKey: "内容") else { throw makeError("内容") }
        guard let 日時 = record.date(dayKey: "日付", timeKey: "時刻", optionDayKey: "修正日") else { throw makeError("日時") }
        guard let 社員名称 = record.string(forKey: "社員名称") else { throw makeError("社員名称") }
        guard let 社員番号 = record.integer(forKey: "社員番号") else { throw makeError("社員番号") }
        guard let 指示書UUIDStr = record.string(forKey: "指示書UUID"), let 指示書UUID = UUID(uuidString: 指示書UUIDStr) else { throw makeError("指示書UUID") }
        guard let 指示書 = try 指示書UUIDキャッシュ型.shared.find(指示書UUID) else { throw makeError("指示書") }
        self.recordId = record.recordId
        self.内容 = 内容
        self.日時 = 日時
        
        self.指示書 = 指示書
        self.種類 = 変更履歴種類型(内容)
        self.作業者 = prepare社員(社員番号: 社員番号, 社員名称: 社員名称)
    }
    public let 日時: Date
    public let 内容: String
    public let 作業者: 社員型
    public var 社員名称: String { 作業者.社員名称 }
    public var 社員番号: Int { 作業者.社員番号 }
    public let 指示書: 指示書型
    public let 種類: 変更履歴種類型
    
    public var memoryFootPrint: Int { return MemoryLayout<指示書変更内容履歴型>.stride } 

}

extension 指示書変更内容履歴型 {
    public static func find(指示書uuid: UUID) throws -> [指示書変更内容履歴型] {
        return try find(query: ["指示書UUID": 指示書uuid.uuidString])
    }
    
    public static func find(日付: Day, 伝票種類: 伝票種類型) throws -> [指示書変更内容履歴型] {
        var query = FileMakerQuery()
        query["日付"] = 日付.fmString
        query["エッチング指示書テーブル::伝票種類"] = 伝票種類.fmString
        return try find(query: query)
    }
}
