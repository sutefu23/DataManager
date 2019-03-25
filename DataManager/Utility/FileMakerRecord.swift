//
//  FileMakerRecord.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

class FileMakerRecord {
    let fieldData : [String:Any]
    let portalData : [String : Any]
    let name : String
    
    init?(json data:Any) {
        guard let dic = data as? [String:Any] else { return nil }
        guard let field = dic["fieldData"] as? [String:Any] else { return nil }
        self.fieldData = field
        self.portalData = dic["portalData"] as? [String:Any] ?? [:]
        self.name = ""
    }
    init?(portal name:String, json data:Any) {
        self.name = name
        guard let dic = data as? [String:Any] else { return nil }
        self.fieldData = dic
        self.portalData = [:]
    }
    
    func output(_ key:String) {
        print(self[key] ?? "")
    }
    
    // MARK: -
    subscript(_ key:String) -> Any? {
        if name.isEmpty {
            let data = fieldData[key]
            return data
        } else {
            let data2 = fieldData["\(name)::\(key)"]
            return data2
        }
    }
    
    func portal(forKey key:String) -> [FileMakerRecord]? {
        guard let source = portalData[key] as? [Any] else { return nil }
        return source.compactMap { FileMakerRecord(portal:key, json: $0) }
    }
    
    var recordId : Int {
        return integer(forKey: "recordId")!
    }
    
    func string(forKey key:String) -> String? {
        return self[key] as? String
    }
    
    func integer(forKey key:String) -> Int? {
        if let value = self[key] as? Int { return value }
        guard let str = string(forKey: key) else { return nil }
        return Int(str)
//        return self[key] as? Int
    }
    
    func double(forKey key:String) -> Double? {
        if let value = self[key] as? Double { return value }
        guard let str = string(forKey: key) else { return nil }
        return Double(str)
    }
    
    func day(forKey key: String) -> Day? {
        guard let day = string(forKey: key) else { return nil }
        return Day(fmJSONDay: day)
    }
    
    func time(forKey key:String) -> Time? {
        guard let time = string(forKey: key) else { return nil }
        return Time(fmJSONTime: time)
    }
    
    func date(forKey key:String) -> Date? {
        guard let date = string(forKey: key) else { return nil }
        return Date(fmJSONDayTime: date)
    }
    
    func date(dayKey:String, timeKey:String) -> Date? {
        let day = string(forKey: dayKey)
        let time = string(forKey: timeKey)
        return Date(fmJSONDay: day, fmJSONTime: time)
    }
    
    func url(forKey key:String) -> URL? {
        guard let url = string(forKey: key) else { return nil }
        return URL(string: url)
    }
    
    func object(forKey key:String) -> Data? {
        guard let url = self.url(forKey: key) else { return nil }
        let db = FileMakerDB.pm_osakaname
        let data = db.downloadObject(url: url)
        return data
    }
}

