//
//  FileMakerRecord.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

/// レコードの種類
private enum RecordType {
    /// メインレコード
    case master(recordID: String, portals: [String: [FileMakerRecord]])
    /// ポータルレコード
    case portal(header: String)
}

/// 1レコードに対応するデータ
struct FileMakerRecord {
    /// フィールドデータ
    private let fieldData: [String: Any]
    /// レコードの種類
    private let type: RecordType

    /// レコードID
    var recordID: String? {
        switch type {
        case .master(recordID: let recordID, portals: _):
            return recordID
        case .portal:
            return nil
        }
    }

    /// 空のレコードを生成する
    init() {
        self.fieldData = [:]
        self.type = .portal(header: "") // 何もないポータル扱い
    }

    /// jsonをもとにメインレコードを生成する
    init?(json data: Any) {
        guard case let dic as [String: Any] = data, case let recordID as String = dic["recordId"] else { return nil }
        self.fieldData = dic["fieldData"] as? [String: Any] ?? [:]
        if case let data as [String: [[String: Any]]] = dic["portalData"], !data.isEmpty {
            var portalData: [String: [FileMakerRecord]] = [:]
            for (key, array) in data {
                let source = array.map { FileMakerRecord(portal: key, fieldData: $0) }
                portalData[key] = source
            }
            self.type = .master(recordID: recordID, portals: portalData)
        } else {
            self.type = .master(recordID: recordID, portals: [:])
        }
    }
    
    /// ポータルレコードを生成する。portalがポータルの名前になる。ポータルのレコードIDは必ずnilとなる
    init(portal name: String, fieldData: [String:Any]) {
        assert(!name.isEmpty)
        self.fieldData = fieldData
        self.type = .portal(header: "\(name)::")
    }
    
    // MARK: -
    /// 指定されたキーに対応するデータを返す
    subscript(_ key: String) -> Any? {
        switch type {
        case .master:
            let data = fieldData[key]
            return data
        case .portal(header: let header):
            let data2 = fieldData[header + key]
            return data2
        }
    }
    /// 指定された名前のポータルを取り出す
    func portal(forKey name: String) -> [FileMakerRecord]? {
        switch type {
        case .master(recordID: _, portals: let portalData):
            return portalData[name]
        case .portal:
            return nil
        }
    }
    /// 指定されたキーに対応する文字列を返す
    func string(forKey key: String) -> String? {
        guard let object = self[key] else { return nil }
        switch object {
        case let str as String:
            return str
        case let value as NSNumber:
            return value.stringValue
        default:
            return nil
        }
    }
    
    /// 指定されたキーに対応する整数値を返す
    func integer(forKey key: String) -> Int? {
        if case let value as Int = self[key] { return value }
        guard let str = string(forKey: key) else { return nil }
        if let value = Int(str) { return value }
        if str.last == "\r" {
            return Int(str.dropLast())
        } else {
            return nil
        }
    }

    /// 指定されたキーに対応する実数値を返す
    func double(forKey key: String) -> Double? {
        if case let value as Double = self[key] { return value }
        guard let str = string(forKey: key) else { return nil }
        if let value = Double(str) { return value }
        if str.last == "\r" {
            return Double(str.dropLast())
        } else {
            return nil
        }
    }
    
    /// 指定されたキーに対応する日付を返す
    func day(forKey key: String) -> Day? {
        guard let day = string(forKey: key) else { return nil }
        return Day(fmJSONDay: day)
    }
    
    /// 指定されたキーに対応する時間を返す
    func time(forKey key: String) -> Time? {
        guard let time = string(forKey: key) else { return nil }
        return Time(fmJSONTime: time)
    }
    
    /// 指定されたキーに対応する日時を返す
    func date(forKey key: String) -> Date? {
        guard let date = string(forKey: key) else { return nil }
        return Date(fmJSONDayTime: date)
    }
    
    /// 指定されたキーに対応する日付と時間から日時を返す
    func date(dayKey: String, timeKey: String, optionDayKey: String? = nil) -> Date? {
        var day = string(forKey: dayKey)
        if day?.isEmpty != false, let key = optionDayKey {
            day = string(forKey: key)
        }
        let time = string(forKey: timeKey)
        return Date(fmJSONDay: day, fmJSONTime: time)
    }

    /// 指定されたキーに対応するURLを返す
    func url(forKey key: String) -> URL? {
        guard let url = string(forKey: key) else { return nil }
        return URL(string: url)
    }
    
    /// 指定されたキーに対応するFileMakerオブジェクトを返す
    func object(forKey key: String) -> Data? {
        guard let url = self.url(forKey: key) else { return nil }
        let db = FileMakerDB.pm_osakaname
        let data = try? db.downloadObject(url: url)
        return data
    }
}

// MARK: -
func makeQueryDayString(_ range: ClosedRange<Day>?) -> String? {
    guard let range = range else { return nil }
    let from = range.lowerBound
    let to = range.upperBound
    if from == to {
        return "\(from.fmString)"
    } else {
        return "\(from.fmString)...\(to.fmString)"
    }
}
