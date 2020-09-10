//
//  FileMakerRecord.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

struct PortalDataCache {
    let cache: [FileMakerRecord]?
}

protocol FileMakerRecordOwner: class {
    init?(record: FileMakerRecord)
}

final class FileMakerRecord {
    let fieldData: [String: Any]
    let portalData: [String: [FileMakerRecord]]
    let recordID: String?
    let name: String
    
    convenience init() {
        self.init(portal: "", fieldData: [:])
    }

    init?(json data: Any) {
        guard let dic = data as? [String: Any] else { return nil }
        self.recordID = dic["recordId"] as? String
        self.fieldData = dic["fieldData"] as? [String: Any] ?? [:]
        if let data = dic["portalData"] as? [String: [[String: Any]]] {
            var portalData = [String: [FileMakerRecord]]()
            for (key, array) in data {
                let source = array.map { FileMakerRecord(portal: key, fieldData: $0) }
                portalData[key] = source
            }
            self.portalData = portalData
        } else {
            self.portalData = [:]
        }
        self.name = ""
    }
    
    init(portal name: String, fieldData: [String:Any]) {
        self.name = name
        self.fieldData = fieldData
        self.portalData = [:]
        self.recordID = nil
    }
    
    func output(_ key: String) {
        print(self[key] ?? "")
    }
    
    // MARK: -
    subscript(_ key: String) -> Any? {
        if name.isEmpty {
            let data = fieldData[key]
            return data
        } else {
            let data2 = fieldData["\(name)::\(key)"]
            return data2
        }
    }
    
    func portal(forKey key: String) -> [FileMakerRecord]? {
        return portalData[key]
    }
    
    func string(forKey key: String) -> String? {
        guard let object = self[key] else { return nil }
        if let str = object as? String { return str }
        if let value = object as? Int { return "\(value)" }
        return nil
    }
    
    func integer(forKey key: String) -> Int? {
        if let value = self[key] as? Int { return value }
        guard let str = string(forKey: key) else { return nil }
        if let value = Int(str) { return value }
        if str.last == "\r" {
            return Int(str.dropLast())
        } else {
            return nil
        }
    }

    func double(forKey key: String) -> Double? {
        if let value = self[key] as? Double { return value }
        guard let str = string(forKey: key) else { return nil }
        if let value = Double(str) { return value }
        if str.last == "\r" {
            return Double(str.dropLast())
        } else {
            return nil
        }
    }
    
    func day(forKey key: String) -> Day? {
        guard let day = string(forKey: key) else { return nil }
        return Day(fmJSONDay: day)
    }
    
    func time(forKey key: String) -> Time? {
        guard let time = string(forKey: key) else { return nil }
        return Time(fmJSONTime: time)
    }
    
    func date(forKey key: String) -> Date? {
        guard let date = string(forKey: key) else { return nil }
        return Date(fmJSONDayTime: date)
    }
    
    func date(dayKey: String, timeKey: String) -> Date? {
        let day = string(forKey: dayKey)
        let time = string(forKey: timeKey)
        return Date(fmJSONDay: day, fmJSONTime: time)
    }
    
    func url(forKey key: String) -> URL? {
        guard let url = string(forKey: key) else { return nil }
        return URL(string: url)
    }
    
    func object(forKey key: String) -> Data? {
        guard let url = self.url(forKey: key) else { return nil }
        let db = FileMakerDB.pm_osakaname
        let data = try? db.downloadObject(url: url)
        return data
    }
}
