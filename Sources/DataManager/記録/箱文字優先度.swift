//
//  箱文字優先度.swift
//  DataManager
//
//  Created by manager on 2020/02/26.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

struct 箱文字優先度Data型: Equatable {
    static let dbName = "DataAPI_3"
    
    var 伝票番号: 伝票番号型? = nil
    var 優先設定: 優先設定型 = .自動判定
    var 表示設定: 表示設定型 = .自動判定
    var 表示設定日: Day? = nil
    var 工程: 工程型? = nil
    
    var 修正情報タイムスタンプ: Date? = nil // 保存情報でない
    private var recordId: String?
    
    init?(_ record: FileMakerRecord) {
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
        self.recordId = record.recordID
    }
    
    init() {}

    init(_ number: 伝票番号型, 工程: 工程型?) {
        self.伝票番号 = number
        self.工程 = 工程
    }
    
    static func == (left: 箱文字優先度Data型, right: 箱文字優先度Data型) -> Bool {
        return left.伝票番号 == right.伝票番号 && left.優先設定 == right.優先設定 && left.表示設定 == right.表示設定 && left.表示設定日 == right.表示設定日 && left.工程 == right.工程
    }
    
    var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        if let num = self.伝票番号 { data["伝票番号"] = String(num.整数値) }
        data["優先設定"] = 優先設定.code
        data["表示設定"] = 表示設定.code
        data["工程コード"] = 工程?.code
        data["表示設定日"] = 表示設定日?.fmString
        return data
    }
    
    func delete() throws -> Bool {
        guard let recordId = self.recordId else { return false }
        let db = FileMakerDB.system
        try db.delete(layout: 箱文字優先度Data型.dbName, recordId: recordId)
        return true
    }

    static func findOld(date: Date) throws -> [箱文字優先度Data型] {
        let db = FileMakerDB.system
        var query = [String: String]()
        query["修正情報タイムスタンプ"] = "<\(date.fmDayTime)"
        let list: [FileMakerRecord] = try db.find(layout: 箱文字優先度Data型.dbName, query: [query])
        return list.compactMap { 箱文字優先度Data型($0) }
    }
    
}

public final class 箱文字優先度型 {
    public static let 自動有効期限: Time = Time(15, 00)
    
    var original: 箱文字優先度Data型 = 箱文字優先度Data型()
    var data: 箱文字優先度Data型
    var recordID: String?

    public var 伝票番号: 伝票番号型? {
        get { data.伝票番号 }
        set { data.伝票番号 = newValue }
    }
    public var 優先設定: 優先設定型 {
        get { data.優先設定 }
        set { data.優先設定 = newValue }
    }
    public var 表示設定: 表示設定型 {
        get {
//            guard let day = data.表示設定日, day.isToday else { return .自動判定 }
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
    public var 工程: 工程型? {
        get { data.工程 }
        set { data.工程 = newValue }
    }
    
    init(data: 箱文字優先度Data型, recordID: String) {
        self.data = data
        self.original = data
        self.recordID = recordID
    }
    
    init(_ number: 伝票番号型, 工程: 工程型?) {
        let data = 箱文字優先度Data型(number, 工程: 工程)
        self.original = data
        self.data = data
        self.recordID = nil
    }
    
    public func delete() {
        guard let recordId = self.recordID else { return }
        let db = FileMakerDB.system
        try? db.delete(layout: 箱文字優先度Data型.dbName, recordId: recordId)
        self.recordID = nil
    }
    
    public func synchronize() {
        if self.data == self.original { return }
        let data = self.data.fieldData
        let db = FileMakerDB.system
        do {
            if let recordID = self.recordID {
                try db.update(layout: 箱文字優先度Data型.dbName, recordId: recordID, fields: data)
            } else {
                let db = FileMakerDB.system
                let recordID = try db.insert(layout: 箱文字優先度Data型.dbName, fields: data)
                self.recordID = recordID
            }
            self.original = self.data
        } catch {
            NSLog(error.localizedDescription)
        }
        箱文字優先度キャッシュ型.shared.update(self)
    }
    
    public static func allRegistered(for 伝票番号: 伝票番号型) throws -> [箱文字優先度型] {
        let db = FileMakerDB.system
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号.整数値)"
        let list: [FileMakerRecord] = try db.find(layout: 箱文字優先度Data型.dbName, query: [query])
        let orders: [箱文字優先度型] = list.compactMap {
            guard let recordID = $0.recordID, let data = 箱文字優先度Data型($0) else { return nil }
            return 箱文字優先度型(data: data, recordID: recordID)
        }
        return orders
    }
    
    public static func findDirect(伝票番号: 伝票番号型, 工程: 工程型?) throws -> 箱文字優先度型? {
        let db = FileMakerDB.system
        var query = [String: String]()
        query["伝票番号"] = "==\(伝票番号.整数値)"
        if let process = 工程 {
            query["工程コード"] = process.code
        } else {
            query["工程コード"] = "="
        }
        let list: [FileMakerRecord] = try db.find(layout: 箱文字優先度Data型.dbName, query: [query])
        if let record = list.first, let recordId = record.recordID {
            if let data = 箱文字優先度Data型(record) {
                return 箱文字優先度型(data: data, recordID: recordId)
            }
        }
        return nil
    }
    
    public static func deleteOldData() -> [String] {
        var log: [String] = []
        do {
            let old = Day().prevWorkDay.prevWorkDay.prevWorkDay // ３営業日前
            let list = try 箱文字優先度Data型.findOld(date: Date(old))
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
