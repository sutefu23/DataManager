//
//  箱文字日報.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/12/05.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

private let lock = NSRecursiveLock()

public struct 箱文字日報Data型: DMSystemRecordData {
    public static let layout = "DataAPI_2"
    public static var db: FileMakerDB { .system }

    public var 工程: 工程型
    public var 作業日: Day
    public var 件数: Int?
    public var 分: Int?
    public var 備考: String
    
    public var memoryFootPrint: Int { 5 * 16 } // てきとう
    
    public init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: "箱文字日報", mes: key) }

        guard let 工程 = record.工程(forKey: "工程コード") else { throw makeError("工程コード") }
        guard let 作業日 = record.day(forKey: "作業日") else { throw makeError("作業日") }
        self.工程 = 工程
        self.作業日 = 作業日
        self.件数 = record.integer(forKey: "件数")
        self.分 = record.integer(forKey: "分")
        self.備考 = record.string(forKey: "備考") ?? ""
    }
    
    init(工程: 工程型, 作業日: Day, 件数: Int?, 分: Int?, 備考: String) {
        self.工程 = 工程
        self.作業日 = 作業日
        self.件数 = 件数
        self.分 = 分
        self.備考 = 備考
    }
    
    public var fieldData: FileMakerQuery {
        var data = FileMakerQuery()
        data["作業日"] = 作業日.fmString
        data["工程コード"] = 工程.code
        if let number = self.件数 { data["件数"] = "\(number)" } else { data["件数"] = "" }
        if let number = self.分 { data["分"] = "\(number)" } else { data["分"] = "" }
        data["備考"] = 備考
        return data
    }
}

public final class 箱文字日報型: DMSystemRecord<箱文字日報Data型> {
//    public var 工程: 工程型 {
//        get { data.工程 }
//        set { data.工程 = newValue }
//    }
//    public var 作業日: Day {
//        get { data.作業日 }
//        set { data.作業日 = newValue }
//    }
//    public var 件数: Int? {
//        get { data.件数 }
//        set { data.件数 = newValue }
//    }
//    public var 分: Int? {
//        get { data.分 }
//        set { data.分 = newValue }
//    }
//    public var 備考: String {
//        get { data.備考 }
//        set { data.備考 = newValue }
//    }

    public init(工程: 工程型, 作業日: Day, 件数: Int?, 分: Int?, 備考: String) {
        let data = 箱文字日報Data型(工程: 工程, 作業日: 作業日, 件数: 件数, 分: 分, 備考: 備考)
        super.init(data)
    }

    public required init(_ record: FileMakerRecord) throws {
        try super.init(record)
    }
    
    public func delete() throws {
        lock.lock(); defer { lock.unlock() }
        try generic_delete()
    }
    
    public func synchronize() throws {
        lock.lock(); defer { lock.unlock() }
        try generic_synchronize()
    }

    public static func findDirect(作業日: Day, 工程: 工程型) throws -> 箱文字日報型? {
        lock.lock(); defer { lock.unlock() }
        var query = FileMakerQuery()
        query["工程コード"] = "==\(工程.code)"
        query["作業日"] = "\(作業日.fmString)"
        return try find(query: query).first
    }
}
