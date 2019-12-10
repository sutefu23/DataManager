//
//  作業系列.swift
//  DataManager
//
//  Created by manager on 2019/12/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

private var seriesCache: [String : 作業系列型] = [:]
private let lock = NSLock()

func flush作業系列Cache() {
    lock.lock()
    seriesCache.removeAll()
    lock.unlock()
}

public class 作業系列型 : Hashable {
    static let gx = 作業系列型(系列コード: "S001")!
    static let ex = 作業系列型(系列コード: "S002")!
    static let hp = 作業系列型(系列コード: "S003")!
    static let water = 作業系列型(系列コード: "S004")!

    
    let record : FileMakerRecord

    public convenience init?(系列コード: String) {
        let code = 系列コード.uppercased()
        lock.lock()
        defer { lock.unlock() }
        if let cache = seriesCache[code] {
            self.init(cache.record)
            return
        }
        guard let series = (try? 作業系列型.find(系列コード: code)) else { return nil }
        seriesCache[code] = series
        self.init(series.record)
    }
    
    init(_ record:FileMakerRecord) {
        self.record = record
    }
    
    public lazy var 系列コード: String = {
        record.string(forKey: "系列コード")!
    }()
    
    public lazy var 名称: String = {
        record.string(forKey: "名称")!
    }()
    public lazy var 備考: String = {
        record.string(forKey: "備考")!
    }()
    
    public static func == (left: 作業系列型, right: 作業系列型) -> Bool {
        return left.系列コード == right.系列コード
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(系列コード)
    }
}

extension 作業系列型 {
    static func find(系列コード: String) throws -> 作業系列型? {
        var query = [String:String]()
        query["系列コード"] = 系列コード
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord] = try db.find(layout: "DataAPI_作業系列", query: [query])
        return list.compactMap { 作業系列型($0) }.first

    }
}

