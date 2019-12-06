//
//  FileMakerDB.swift
//  DataManager
//
//  Created by 四熊泰之 on 2019/01/27.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

enum FileMakerSortType : String, Encodable {
    case 昇順 = "ascend"
    case 降順 = "descend"
}

struct FileMakerSortItem : Encodable {
    let fieldName : String
    let sortOrder : FileMakerSortType
}

let maxConnection = 3

public final class FileMakerDB {
    public static func flushSessions() {
        FileMakerDB.pm_osakaname.closeAllSessions()
    }
    
    static let pm_osakaname : FileMakerDB = FileMakerDB(server: "192.168.1.153", filename: "pm_osakaname", user: "admin", password: "ojwvndfM")
    static let laser : FileMakerDB = FileMakerDB(server: "192.168.1.153", filename: "laser", user: "admin", password: "ws")
    static let system : FileMakerDB =  FileMakerDB(server: "192.168.1.153", filename: "system", user: "admin", password: "ws161")
    static let pm_osakaname2 : FileMakerDB = FileMakerDB(server: "192.168.1.155", filename: "pm_osakaname", user: "admin", password: "ojwvndfM")

    let dbURL : URL
    let user : String
    let password : String
    
    init(server:String, filename:String, user:String, password:String) {
        let serverURL = "https://\(server)/fmi/data/v1/databases/\(filename)/"
        self.dbURL = URL(string: serverURL)!
        self.user = user
        self.password = password
        self.sem = DispatchSemaphore(value: maxConnection)
    }

    private var sessions : [FileMakerSession] = []
    private let lock = Lock()
    private let sem : DispatchSemaphore

    func closeAllSessions() {
        sessions.forEach { $0.logout() }
        sessions.removeAll()
    }
    
    private func prepareSesion() -> FileMakerSession {
        sem.wait()
        lock.lock()
        defer { lock.unlock() }
        if let session = sessions.last {
            sessions.removeLast(1)
            return session
        } else {
            let session = FileMakerSession(url: self.dbURL, user: self.user, password: self.password)
            return session
        }
    }
    
    private func stockSession(_ session:FileMakerSession) {
        lock.lock()
        self.sessions.append(session)
        lock.unlock()
        sem.signal()
    }
    
    func fetch(layout:String, sortItems:[(String, FileMakerSortType)] = [], portals:[FileMakerPortal] = []) -> [FileMakerRecord]? {
        let session = self.prepareSesion()
        let result = session.fetch(layout: layout, sortItems: sortItems, portals: portals)
        stockSession(session)
        return result
    }
    
    func find(layout:String, recordId:Int) -> FileMakerRecord? {
        return self.find(layout: layout, query: [["recordId" : "\(recordId)"]])?.first
    }
    
    func find(layout:String, query:[[String:String]], sortItems:[(String, FileMakerSortType)] = [], max:Int? = nil) -> [FileMakerRecord]? {
        let session = self.prepareSesion()
        defer { stockSession(session) }
        return session.find(layout: layout, query: query, sortItems: sortItems, max: max)
    }
    
    func downloadObject(url:URL) -> Data? {
        let session = self.prepareSesion()
        defer { stockSession(session) }
        return session.download(url)
    }
    
    func update(layout:String, recordId:String, fields:[String:String]) -> Bool {
        let session = self.prepareSesion()
        defer { stockSession(session) }
        return session.update(layout: layout, recordId: recordId,fields: fields)
    }
    
    func delete(layout: String, recordId: String) -> Bool {
        let session = self.prepareSesion()
        defer { stockSession(session) }
        return session.delete(layout: layout, recordId: recordId)
    }
    
    @discardableResult func insert(layout:String, fields:[String:String]) -> String? {
        let session = self.prepareSesion()
        defer { stockSession(session) }
        return session.insert(layout: layout, fields: fields)
    }
    
    @discardableResult func execute(layout: String, script:String, param: String) -> Bool {
        let session = self.prepareSesion()
        defer { stockSession(session) }
        return session.execute(layout: layout, script: script, param: param)
    }
}

