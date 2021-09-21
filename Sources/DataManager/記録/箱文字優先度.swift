//
//  箱文字優先度.swift
//  DataManager
//
//  Created by manager on 2020/02/26.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 箱文字優先度Data型: DMSystemRecordData, Equatable {
    public static let layout = "DataAPI_3"
    
    public var 伝票番号: 伝票番号型? = nil
    public var 優先設定: 優先設定型 = .自動判定
    public var 表示設定: 表示設定型 = .自動判定
    public var 表示設定日: Day? = nil
    public var 工程: 工程型? = nil
    
    var 修正情報タイムスタンプ: Date? = nil // 保存情報でない
    
    public init(_ record: FileMakerRecord) throws {
        if let number = record.integer(forKey: "伝票番号") {
            self.伝票番号 = 伝票番号型(validNumber: number)
        }
        if let code = record.string(forKey: "優先設定") {
            self.優先設定 = 優先設定型(code)
        }
        if let code = record.string(forKey: "表示設定") {
            self.表示設定 = 表示設定型(code)
        }
        if let code = record.string(forKey: "工程コード") {
            self.工程 = 工程型(code: code)
        }
        self.表示設定日 = record.day(forKey: "表示設定日")
        self.修正情報タイムスタンプ = record.date(forKey: "修正情報タイムスタンプ")
    }
    
    init() {}

    init(_ number: 伝票番号型, 工程: 工程型?) {
        self.伝票番号 = number
        self.工程 = 工程
    }
    
    public static func == (left: 箱文字優先度Data型, right: 箱文字優先度Data型) -> Bool {
        return left.伝票番号 == right.伝票番号 && left.優先設定 == right.優先設定 && left.表示設定 == right.表示設定 && left.表示設定日 == right.表示設定日 && left.工程 == right.工程
    }
    
    public var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        if let num = self.伝票番号 { data["伝票番号"] = String(num.整数値) }
        data["優先設定"] = 優先設定.code
        data["表示設定"] = 表示設定.code
        data["工程コード"] = 工程?.code
        data["表示設定日"] = 表示設定日?.fmString
        return data
    }
}

public final class 箱文字優先度型: DMSystemRecord<箱文字優先度Data型> {
    public static let 自動有効期限: Time = Time(15, 00)
    
//    public var 伝票番号: 伝票番号型? {
//        get { data.伝票番号 }
//        set { data.伝票番号 = newValue }
//    }
//    public var 優先設定: 優先設定型 {
//        get { data.優先設定 }
//        set { data.優先設定 = newValue }
//    }
    public var 表示設定: 表示設定型 {
        get {
            return data.表示設定
        }
        set {
            data.表示設定 = newValue
            if newValue == .自動判定 {
                data.表示設定日 = nil
            } else {
                data.表示設定日 = Day()
            }
        }
    }
    public var 表示設定日: Day {
        get { data.表示設定日 ?? data.修正情報タイムスタンプ?.day ?? Day() }
        set { data.表示設定日 = newValue }
    }
//    public var 工程: 工程型? {
//        get { data.工程 }
//        set { data.工程 = newValue }
//    }
    
    init(data: 箱文字優先度Data型, recordId: String) {
        super.init(data, recordId: recordId)
    }
    
    init(_ number: 伝票番号型, 工程: 工程型?) {
        let data = 箱文字優先度Data型(number, 工程: 工程)
        super.init(data, recordId: nil)
    }
    
    required public init(_ record: FileMakerRecord) throws {
        try super.init(record)
    }
    
    @discardableResult
    public func delete() throws -> Bool {
        return try generic_delete()
    }
    
    public func synchronize() throws {
        if try generic_synchronize() {
            箱文字優先度キャッシュ型.shared.update(self)
        }
    }
    
    public static func allRegistered(for 伝票番号: 伝票番号型) throws -> [箱文字優先度型] {
        return try find(query: ["伝票番号": "==\(伝票番号.整数値)"])
    }
    
    public static func findDirect(伝票番号: 伝票番号型, 工程: 工程型?) throws -> 箱文字優先度型? {
        var query = [String: String]()
        query["伝票番号"] = "==\(伝票番号.整数値)"
        if let process = 工程 {
            query["工程コード"] = process.code
        } else {
            query["工程コード"] = "="
        }
        return try find(query: query).first
    }
    
    public static func deleteOldData() -> [String] {
        var log: [String] = []
        do {
            let old = Day().prevWorkDay.prevWorkDay.prevWorkDay // ３営業日前
            let list = try findOld(date: Date(old))
            for data in list {
                guard let num = data.伝票番号, let order = try 指示書型.findDirect(伝票番号: num), order.出荷納期 <= old else { continue }
                if try data.delete() {
                    var mes = "\(num.表示用文字列) \(order.伝票種類.description.prefix(1)):\(order.品名.prefix(10))"
                    if let process = data.工程 { mes += " 工程:\(process.description)" }
                    if !data.優先設定.code.isEmpty { mes += " 優先:\(data.優先設定.code)" }
                    if !data.表示設定.code.isEmpty { mes += " 表示:\(data.表示設定.code)" }
                    mes += "を削除した"
                    log.append(mes)
                }
            }
        } catch {
            log = [error.localizedDescription]
        }
        return log
    }
    
    static func findOld(date: Date) throws -> [箱文字優先度型] {
        return try find(query: ["修正情報タイムスタンプ": "<\(date.fmDayTime)"])
    }
}

public enum 優先設定型 {
    case 優先あり
    case 優先なし
    case 自動判定
    
    init(_ code: String) {
        switch code {
        case "優先あり":
            self = .優先あり
        case "優先なし":
            self = .優先なし
        default:
            self = .自動判定
        }
    }
    
    public var code: String {
        switch self {
        case .優先あり: return "優先あり"
        case .優先なし: return "優先なし"
        case .自動判定: return ""
        }
    }
    
    public var description: String {
        switch self {
        case .優先あり: return "優先あり"
        case .優先なし: return "優先なし"
        case .自動判定: return "自動判定"
        }
    }
}

public enum 表示設定型 {
    case 白
    case 黒
    case 自動判定
    
    init(_ code: String) {
        switch code {
        case "白":
            self = .白
        case "黒":
            self = .黒
        default:
            self = .自動判定
        }
    }
    
    public var code: String {
        switch self {
        case .白: return "白"
        case .黒: return "黒"
        case .自動判定: return ""
        }
    }

    public var description: String {
        switch self {
        case .白: return "白"
        case .黒: return "黒"
        case .自動判定: return "自動判定"
        }
    }
}
