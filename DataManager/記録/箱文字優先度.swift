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
    var 工程: 工程型? = nil
    
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
    }
    
    init() {}

    init(_ number: 伝票番号型) {
        self.伝票番号 = number
    }
    
    var fieldData: [String: String] {
        var data = [String: String]()
        if let num = self.伝票番号 { data["伝票番号"] = String(num.整数値) }
        data["優先設定"] = 優先設定.code
        data["表示設定"] = 表示設定.code
        data["工程コード"] = 工程?.code
        return data
    }
}

public class 箱文字優先度型 {
    var original: 箱文字優先度Data型 = 箱文字優先度Data型()
    var data: 箱文字優先度Data型
    var recordID: String?

    public var 伝票番号: 伝票番号型? {
        get { return data.伝票番号 }
        set { return data.伝票番号 = newValue }
    }
    public var 優先設定: 優先設定型 {
        get { return data.優先設定 }
        set { data.優先設定 = newValue }
    }
    public var 表示設定: 表示設定型 {
        get { return data.表示設定 }
        set { data.表示設定 = newValue }
    }
    public var 工程: 工程型? {
        get { return data.工程 }
        set { data.工程 = newValue }
    }
    
    init(data: 箱文字優先度Data型, recordID: String) {
        self.data = data
        self.original = data
        self.recordID = recordID
    }
    
    init(_ number: 伝票番号型) {
        let data = 箱文字優先度Data型(number)
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
    }
    
    public static func allRegistered(for 伝票番号: 伝票番号型) throws -> [箱文字優先度型] {
        let db = FileMakerDB.system
        var query = [String: String]()
        query["伝票番号"] = "==\(伝票番号.整数値)"
        let list: [FileMakerRecord] = try db.find(layout: 箱文字優先度Data型.dbName, query: [query])
        let orders: [箱文字優先度型] = list.compactMap {
            guard let recordID = $0.recordId, let data = 箱文字優先度Data型($0) else { return nil }
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
        do {
            let list: [FileMakerRecord] = try db.find(layout: 箱文字優先度Data型.dbName, query: [query])
            if let record = list.first, let recordId = record.recordId {
                if let data = 箱文字優先度Data型(record) {
                    return 箱文字優先度型(data: data, recordID: recordId)
                }
            }
            return nil
        } catch {
//            NSLog(error.localizedDescription)
            return nil
        }
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
