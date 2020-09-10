//
//  FileMakerDB.swift
//  DataManager
//
//  Created by 四熊泰之 on 2019/01/27.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public extension UserDefaults {
    /// FileMakerへのアクセスを停止したいときはtrue
    var filemakerIsDisabled: Bool {
        get { return bool(forKey: "filemakerIsDisabled") }
        set { self.set(newValue, forKey: "filemakerIsDisabled") }
    }
    
    /// サーバーへの同時接続数
    var filemakerMaxConnection: Int {
        get { maxConnection }
        set { maxConnection = newValue }
    }
}

private let serverCache = FileMakerServerCache()

/// サーバー名に対応するサーバーオブジェクトを保持する（共用のため）
private final class FileMakerServerCache {
    private var cache: [String: FileMakerServer] = [:]
    private let lock = NSLock()
    
    /// サーバーを取り出す
    /// - Parameter name: サーバー名
    /// - Returns: 共用サーバーオブジェクト
    func server(_ name: String) -> FileMakerServer {
        lock.lock()
        defer { lock.unlock() }
        if let server = cache[name] { return server}
        let server = FileMakerServer(name)
        cache[name] = server
        return server
    }
    
    /// 全てのサーバーへの接続を解除する
    func logoutAll() {
        lock.lock()
        defer { lock.unlock() }
        if cache.isEmpty { return }
        cache.values.forEach { $0.logout() }
    }
}

/// 検索項目
struct FileMakerSortItem: Encodable {
    let fieldName: String
    let sortOrder: FileMakerSortType
}
/// ソート順
enum FileMakerSortType: String, Encodable {
    case 昇順 = "ascend"
    case 降順 = "descend"
}

/// １台のサーバーへの最大同時接続数
var maxConnection = 3

/// サーバーオブジェクト（セッションの管理）
final class FileMakerServer: Hashable {
    private var pool: [FileMakerSession] = []
    private let lock = NSLock()
    private let sem: DispatchSemaphore

    let serverURL: URL
    let name: String
    
    fileprivate init(_ server: String) {
        self.name = server
        let serverURL = URL(string: "https://\(server)/fmi/data/v1/databases/")!
        self.serverURL = serverURL
        self.sem = DispatchSemaphore(value: maxConnection)
    }
    
    func makeURL(with filename: String) -> URL {
        return self.serverURL.appendingPathComponent(filename)
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func ==(left: FileMakerServer, right: FileMakerServer) -> Bool {
        return left.name == right.name
    }
    
    /// セッションを取得する
    func pullSession(url: URL, user: String, password: String) -> FileMakerSession {
        sem.wait()
        lock.lock()
        defer { lock.unlock() }
        for (index, session) in pool.enumerated().reversed() {
            if session.dbURL == url {
                pool.remove(at: index)
                return session
            }
        }
        while pool.count >= maxConnection, let session = pool.first {
            pool.removeFirst(1)
            session.logout()
        }
        let session = FileMakerSession(url: url, user: user, password: password)
        return session
    }
    
    /// セッションを解放する
    func putSession(_ session: FileMakerSession) {
        lock.lock()
        self.pool.append(session)
        lock.unlock()
        sem.signal()
    }
    
    /// セッションを閉じる
    func logout() {
        lock.lock()
        for session in pool {
            session.logout()
        }
        pool.removeAll()
        lock.unlock()
    }
}

/// サーバー上のデータベースファイル
public final class FileMakerDB {
    /// 生産管理DB
    static let pm_osakaname: FileMakerDB = FileMakerDB(server: "192.168.1.153", filename: "pm_osakaname", user: "api", password: "@pi")
    /// 生産管理テストDB
    static let pm_osakaname2: FileMakerDB = FileMakerDB(server: "192.168.1.155", filename: "pm_osakaname", user: "api", password: "@pi")
    /// システムDB
    static let system: FileMakerDB =  FileMakerDB(server: "192.168.1.153", filename: "system", user: "admin", password: "ws161")
    /// レーザーDB
    static let laser: FileMakerDB = FileMakerDB(server: "192.168.1.153", filename: "laser", user: "admin", password: "ws")

    public static var isEnabled = true
    
    let dbURL: URL
    let server: FileMakerServer
    let user: String
    let password: String

    init(server: String, filename: String, user: String, password: String) {
        self.server = serverCache.server(server)
        self.dbURL = self.server.makeURL(with: filename)
        self.user = user
        self.password = password
    }
    
    /// 接続セッションを取得する
    func retainSession() -> FileMakerSession {
        return server.pullSession(url: self.dbURL, user: self.user, password: self.password)
    }
    
    /// セッションを解放する
    func releaseSession(_ session: FileMakerSession) {
        server.putSession(session)
    }
    
    /// セッションを一時的に取得して作業を行う
    /// - Parameter work: セッション上で行う作業
    private func execute(_ work: (FileMakerSession) throws -> Void) rethrows {
        let session = server.pullSession(url: self.dbURL, user: self.user, password: self.password)
        defer { server.putSession(session) }
        do {
            try work(session)
        } catch {
            if let error = error as? FileMakerError, error.canRetry {
                session.logout()
                try work(session)
            } else {
                throw error
            }
        }
    }

    /// セッションを一時的に取得して作業を行う
    /// - Parameter work: セッション上で行う作業。なんらかの値を返す
    /// - Returns: 作業の返り値
    private func execute2<T>(_ work: (FileMakerSession) throws -> T) rethrows -> T {
         let session = server.pullSession(url: self.dbURL, user: self.user, password: self.password)
         defer { server.putSession(session) }
        do {
            return try work(session)
        } catch {
            if let error = error as? FileMakerError, error.canRetry {
                session.logout()
                return try work(session)
            } else {
                throw error
            }
        }
     }
    
    /// サーバーが停止中ならtrueを返す
    private func checkStop() throws {
        if !FileMakerDB.isEnabled || UserDefaults.standard.filemakerIsDisabled { throw FileMakerError.dbIsDisabled }
    }

    /// スクリプトを実行する
    /// - Parameters:
    ///   - layout: スクリプトを実行するレイアウト
    ///   - script: スクリプト名
    ///   - param: スクリプトのパラメータ
    func executeScript(layout: String, script: String, param: String) throws {
        try checkStop()
        try self.execute { try $0.executeScript(layout: layout, script: script, param: param) }
    }

    func fetch(layout: String, sortItems: [(String, FileMakerSortType)] = [], portals: [FileMakerPortal] = []) throws -> [FileMakerRecord] {
        try checkStop()
        return try self.execute2 { try $0.fetch(layout: layout, sortItems: sortItems, portals: portals) }
    }
    
    func find(layout: String, recordId: Int) throws -> FileMakerRecord? {
        try checkStop()
        return try self.find(layout: layout, query: [["recordId" : "\(recordId)"]]).first
    }
    
    func find(layout: String, query: [[String: String]], sortItems: [(String, FileMakerSortType)] = [], max: Int? = nil) throws -> [FileMakerRecord] {
        try checkStop()
        return try self.execute2 { try $0.find(layout: layout, query: query, sortItems: sortItems, max: max) }
    }
    
    func downloadObject(url: URL) throws -> Data? {
        try checkStop()
        return try self.execute2 { try $0.download(url) }
    }
    
    func update(layout: String, recordId: String, fields: FileMakerQuery) throws {
        try checkStop()
        return try self.execute { try $0.update(layout: layout, recordID: recordId,fields: fields) }
    }
    
    func delete(layout: String, recordId: String) throws {
        try checkStop()
        return try self.execute { try $0.delete(layout: layout, recordID: recordId) }
    }
    
    @discardableResult func insert(layout: String, fields: FileMakerQuery) throws -> String {
        try checkStop()
        return try self.execute2 { try $0.insert(layout: layout, fields: fields) }
    }
    
    /// DBにアクセス可能か調べる
    public static func testDBAccess() -> Bool {
        if UserDefaults.standard.filemakerIsDisabled { return false }
        return pm_osakaname.execute2 { $0.checkDBAccess() }
    }
    
    public static func logputAll() {
        serverCache.logoutAll()
    }
}
