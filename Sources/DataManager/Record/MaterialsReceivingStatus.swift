//
//  資材入庫状況.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 資材入庫状況状態型 {
    case 入庫済
    
    init?(_ text: String) {
        switch text {
        case "入庫済":
            self = .入庫済
        default:
            return nil
        }
    }
    
    var text: String {
        switch self {
        case .入庫済: return "入庫済"
        }
    }
}
extension FileMakerRecord {
    func 資材入庫状況状態(forKey key: String) -> 資材入庫状況状態型? {
        guard let string = self.string(forKey: key) else { return nil }
        return 資材入庫状況状態型(string)
    }
}

public struct 資材入庫状況Data型: FileMakerSyncData, Equatable, DMCacheElement {
    public static let layout = "DataAPI_4"
    public static var db: FileMakerDB { .system }
    public var 指定注文番号:  指定注文番号型
    public var 資材入庫状況状態: 資材入庫状況状態型

    public var memoryFootPrint: Int {
        return 指定注文番号.memoryFootPrint + MemoryLayout<資材入庫状況状態型>.stride
    }
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "資材入庫状況", mes: key) }
        guard let 指定注文番号 = record.指定注文番号(forKey: "指定注文番号") else  { throw makeError("指定注文番号") }
        guard let 資材入庫状況状態 = record.資材入庫状況状態(forKey: "資材入庫状況状態") else { throw makeError("資材入庫状況状態") }
        self.指定注文番号 = 指定注文番号
        self.資材入庫状況状態 = 資材入庫状況状態
    }
    
    init(指定注文番号: 指定注文番号型, 資材入庫状況状態: 資材入庫状況状態型) {
        self.指定注文番号 = 指定注文番号
        self.資材入庫状況状態 = 資材入庫状況状態
    }
    
    public var fieldData: FileMakerFields {
        var data = FileMakerFields()
        data["指定注文番号"] = 指定注文番号.テキスト
        data["資材入庫状況状態"] = 資材入庫状況状態.text
        return data
    }
}

public final class 資材入庫状況型: FileMakerSyncObject<資材入庫状況Data型> {
//    var 指定注文番号: 指定注文番号型 {
//        get { data.指定注文番号 }
//        set { data.指定注文番号 = newValue }
//    }
//    var 資材入庫状況状態: 資材入庫状況状態型 {
//        get { data.資材入庫状況状態 }
//        set { data.資材入庫状況状態 = newValue }
//    }
    
    
    init(data: 資材入庫状況Data型, recordID: FileMakerRecordID) {
        super.init(data, recordId: recordID)
    }
    
    public init(_ 指定注文番号: 指定注文番号型, 資材入庫状況状態: 資材入庫状況状態型) {
        let data = 資材入庫状況Data型(指定注文番号: 指定注文番号, 資材入庫状況状態: 資材入庫状況状態)
        super.init(data, recordId: nil)
    }
    
    required init(_ record: FileMakerRecord) throws {
        try super.init(record)
    }
    
    public func delete() throws {
        if try generic_delete() {
            資材入庫状況キャッシュ型.shared.registCache(指定注文番号: self.指定注文番号, 資材入庫状況: nil)
        }
    }
    
    public func synchronize() throws {
        if try generic_synchronize() {
            資材入庫状況キャッシュ型.shared.registCache(指定注文番号: self.指定注文番号, 資材入庫状況: self)
        }
    }
    
    static func findDirect(指定注文番号: 指定注文番号型) throws -> 資材入庫状況型? {
        return try find(query: ["指定注文番号" : "==\(指定注文番号.テキスト)"]).first
    }
    
    // 不要になったレコードの消去
    static func removeOld() throws {
        let list = try fetchAll()
        for data in list {
            guard let order = try 資材指定注番発注キャッシュ型.shared.find(data.指定注文番号, noCache: false) else { continue }
            switch order.状態 {
            case .未処理, .発注待ち, .発注済み:
                break
            case .処理済み, .納品書待ち, .納品済み:
                try data.delete()
            }
        }
    }
}

// MARK: -
public class 資材入庫状況キャッシュ型: DMDBCache<指定注文番号型, 資材入庫状況型> {
    public static let shared: 資材入庫状況キャッシュ型 = 資材入庫状況キャッシュ型(lifeSpan: 10*60*60, nilCache: true) {
        try 資材入庫状況型.findDirect(指定注文番号: $0)
    }
    
    func 現在資材入庫状況(指定注文番号: 指定注文番号型) throws -> 資材入庫状況型? {
        return try find(指定注文番号, noCache: true)
    }

    func キャッシュ資材入庫状況(指定注文番号: 指定注文番号型) throws -> 資材入庫状況型? {
        return try find(指定注文番号, noCache: false)
    }

    public func removeOldData() {
        try? 資材入庫状況型.removeOld()
    }

    func flushCache(指定注文番号: 指定注文番号型) {
        removeCache(forKey: 指定注文番号)
    }
    
    func registCache(指定注文番号: 指定注文番号型, 資材入庫状況: 資材入庫状況型?) {
        if let 資材入庫状況 = 資材入庫状況 {
            self.regist(資材入庫状況, forKey: 指定注文番号)
        } else {
            self.removeCache(forKey: 指定注文番号)
        }
    }
}
