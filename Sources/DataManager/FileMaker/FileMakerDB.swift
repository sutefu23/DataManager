//
//  FileMakerDB.swift
//  DataManager
//
//  Created by 四熊泰之 on 2019/01/27.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

/// １台のサーバーへの最大同時接続数
private var maxConnection = 3
/// 最低300秒はアクセスする
private let lastAccessInterval: TimeInterval = 300
/// 有効期限一括チェックの周期
private let timerInterval: Int = 10
/// 再実行前の待機時間
private let retryInterval: TimeInterval = 1.0

public extension UserDefaults {
    /// FileMakerへのアクセスを停止したいときはtrue
    var filemakerIsDisabled: Bool {
        get { return bool(forKey: "filemakerIsDisabled") }
        set { self.set(newValue, forKey: "filemakerIsDisabled") }
    }
    
    var fileMakerIsEnabled: Bool { !self.filemakerIsDisabled }
    
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
    private let lock = NSRecursiveLock()
    
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
    
    /// 全てのサーバーの現在の待機数の合計
    var poolCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.reduce(0) { $0 + $1.value.poolCount }
    }
    /// 全てのサーバーの現在の接続数の合計
    var connectingCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.reduce(0) { $0 + $1.value.connectingCount }
    }
    
    /// 全てのサーバーへの接続を解除する
    func logoutAll(force: Bool) {
        lock.lock(); defer { lock.unlock() }
        cache.values.forEach { $0.logout(force: force) }
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

/// サーバーオブジェクト（セッションの管理）
final class FileMakerServer: Hashable, DMLoggable {
    private var pool: [FileMakerSession] = []
    private var connecting: [FileMakerSession.ID: FileMakerSession] = [:]
    private let lock = NSRecursiveLock()
    private let sem: DispatchSemaphore
    private var timerSet: Bool = false

    /// サーバーのURL
    let serverURL: URL
    /// サーバーのホスト名またはIPアドレス
    let name: String
    
    fileprivate init(_ server: String) {
        self.name = server
        let serverURL = URL(string: "https://\(server)/fmi/data/v1/databases/")!
        self.serverURL = serverURL
        self.sem = DispatchSemaphore(value: maxConnection)
    }
    
    /// 現在の待機数
    var poolCount: Int {
        lock.lock(); defer { lock.unlock() }
        return pool.reduce(0) { $1.hasValidToken ? $0+1 : $0 }
    }
    /// 現在の接続数
    var connectingCount: Int {
        lock.lock(); defer { lock.unlock() }
        return connecting.count
    }
    
    /// 指定された名称のDBファイルのURLを生成する
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
        if connecting.isEmpty { updateLogoutBaseLine() }
        // 使い回し
        for (index, session) in pool.enumerated().reversed() where session.url == url {
            pool.remove(at: index)
            connecting[session.id] = session
            return session
        }
        // 作成
        let newSession: FileMakerSession
        let totalCount = pool.count + connecting.count
        if totalCount >= maxConnection, let last = pool.popLast() { // 再生する
            debugLog("reset session")
            newSession = FileMakerSession(url: url, user: user, password: password, session: last)
        } else { // 完全新規作成
            newSession = FileMakerSession(url: url, user: user, password: password)
        }
        connecting[newSession.id] = newSession
        return newSession
    }
    
    /// セッションを返却する
    func putSession(_ session: FileMakerSession) {
        session.updateTokenExpire()
        lock.lock()
        self.pool.append(session)
        connecting[session.id] = nil
        lock.unlock()
        sem.signal()
        startTimer()
    }
    
    private func updateLogoutBaseLine() {
        self.logoutBaseLine = Date()
    }
    private var logoutBaseLine: Date = Date() // 前回ログアウト時間。ある程度間隔を空けないとログアウトできない
    /// セッションを閉じる
    func logout(force: Bool) {
        guard FileMakerDB.isEnabled else { return }
        lock.lock(); defer { lock.unlock() }
        if pool.isEmpty { return }
        if !force {
            if abs(self.logoutBaseLine.timeIntervalSinceNow) < lastAccessInterval { return }
        }
        DispatchQueue.concurrentPerform(iterations: pool.count) {
            let pool = pool[$0]
            pool.invalidate()
        }
        pool.removeAll()
        updateLogoutBaseLine()
    }
    
    // MARK: - logganle
    func log(_ text: String, detail: String?, level: DMLogLevel) {
        if let detail = detail, !detail.isEmpty {
            mainLogSystem.log(text, detail: "db=\(name):\(detail)", level: level)
        } else {
            mainLogSystem.log(text, detail: "db=\(name)", level: level)
        }
    }

    // MARK: - タイマー管理
    /// 有効期限処理タイマーを起動する。起動済みなら何もしない
    func startTimer() {
        lock.lock(); defer { lock.unlock() }
        if timerSet || pool.isEmpty { return }
        timerSet = true
        debugLog("start timer")
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + .seconds(timerInterval)) {
            self.checkSessions()
        }
    }
    /// セッションの有効期限処理を実行する
    func checkSessions() {
        lock.lock(); defer { lock.unlock() }
        debugLog("start check")
        timerSet = false
        /// 別スレッドで処理するログアウト処理の同期用
        let group = DispatchGroup()
        for (index, session) in pool.enumerated().reversed() {
            if session.hasToken {
                if !session.hasValidToken {
                    DispatchQueue.global().async(group: group) {
                        session.debugLog("expire logout")
                        session.logout(waitAfterLogout: nil)
                    }
                }
            } else if !session.hasValidConnection {
                DispatchQueue.global(qos: .background).async {
                    session.debugLog("expire invalidate")
                    session.invalidate()
                }
                pool.remove(at: index)
            }
        }
        group.wait()
        if !pool.isEmpty { self.startTimer() } // poolが存在 = チェックすることがある
    }
}

/// サーバー上のデータベースファイル
public final class FileMakerDB: DMLoggable {
    /// 生産管理DB
    static let pm_osakaname: FileMakerDB = FileMakerDB(server: "192.168.1.153", filename: "pm_osakaname", user: "api", password: "@pi")
    /// 生産管理テストDB
    static let pm_osakaname2: FileMakerDB = FileMakerDB(server: "192.168.1.155", filename: "pm_osakaname", user: "api", password: "@pi")
    /// システムDB
    static let system: FileMakerDB =  FileMakerDB(server: "192.168.1.153", filename: "system", user: "admin", password: "ws161")
    /// レーザーDB
    static let laser: FileMakerDB = FileMakerDB(server: "192.168.1.153", filename: "laser", user: "admin", password: "ws")

    private static var isEnabledValue = true
    public static var isEnabled: Bool {
        get { isEnabledValue && !defaults.filemakerIsDisabled}
        set { isEnabledValue = newValue }
    }
    /// DBファイルのURL
    private let dbURL: URL
    /// サーバー
    private let server: FileMakerServer
    /// ファイル名
    private let filename: String
    /// ユーザー名
    private let user: String
    /// パスワード
    private let password: String

    private init(server: String, filename: String, user: String, password: String) {
        self.server = serverCache.server(server)
        self.dbURL = self.server.makeURL(with: filename)
        self.filename = filename
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
    /// - Parameter work: セッション上で行う作業。なんらかの値を返す
    /// - Returns: 作業の返り値。Voidの時もある
    private func execute<T>(_ work: (FileMakerSession) throws -> T) rethrows -> T {
        try autoreleasepool {
            let session = server.pullSession(url: self.dbURL, user: self.user, password: self.password)
            defer { server.putSession(session) }
            do {
                return try work(session)
            } catch {
                guard error.canRetry else { throw error }
                if error.resetToken {
                    session.checkMissing()
                } else {
                    Thread.sleep(forTimeInterval: retryInterval)
                }
                do {
                    debugLog("retry")
                    return try work(session)
                } catch var error {
                    error.retryCount = 2
                    throw error
                }
            }
        }
     }
    
    /// サーバーが停止中ならtrueを返す
    private func checkStop() throws {
        if !FileMakerDB.isEnabled { throw FileMakerError.dbIsDisabled.log(.critical) }
    }

    /// スクリプトを実行する
    /// - Parameters:
    ///   - layout: スクリプトを実行するレイアウト
    ///   - script: スクリプト名
    ///   - param: スクリプトのパラメータ
    func executeScript(layout: String, script: String, param: String, waitTime: (main: TimeInterval, extra: TimeInterval)?) throws {
        try checkStop()
        try self.execute { try $0.executeScript(layout: layout, script: script, param: param, waitTime: waitTime) }
    }

    /// 指定されたレイアウトから全レコードを取得する
    func fetch(layout: String, sortItems: [(String, FileMakerSortType)] = [], portals: [FileMakerPortal] = []) throws -> [FileMakerRecord] {
        try checkStop()
        return try self.execute { try $0.fetch(layout: layout, sortItems: sortItems, portals: portals) }
    }

    /// 指定されたレイアウトからreckordIdのレコードを取得する
    func find(layout: String, recordId: Int) throws -> FileMakerRecord? {
        try checkStop()
        return try self.find(layout: layout, query: [["recordId" : "\(recordId)"]]).first
    }
    /// 指定されたレコードからqueryに合致するレコードを取得する
    func find(layout: String, query: [[String: String]], sortItems: [(String, FileMakerSortType)] = [], max: Int? = nil) throws -> [FileMakerRecord] {
        try checkStop()
        return try self.execute { try $0.find(layout: layout, query: query, sortItems: sortItems, max: max) }
    }
    /// urlからオブジェクトをダウンロードする
    func downloadObject(url: URL) throws -> Data? {
        try checkStop()
        return try self.execute { try $0.download(url) }
    }
    /// 指定されたレイアウトのrecordIdのレコードについてfiledsの項目を更新する
    func update(layout: String, recordId: String, fields: FileMakerQuery) throws {
        try checkStop()
        return try self.execute { try $0.update(layout: layout, recordID: recordId,fields: fields) }
    }
    ///指定されたレイアウトのrecordIdのレコードを削除する
    func delete(layout: String, recordId: String) throws {
        try checkStop()
        return try self.execute { try $0.delete(layout: layout, recordID: recordId) }
    }
    
    /// 指定されたレイアウトにfieldsを用いてレコードを作成する
    @discardableResult
    func insert(layout: String, fields: FileMakerQuery) throws -> String {
        try checkStop()
        return try self.execute { try $0.insert(layout: layout, fields: fields) }
    }
    
    /// DBの接続状態を確認し接続できないなら例外を出す
    public static func checkConnection() throws {
        if defaults.filemakerIsDisabled {
            throw FileMakerError.dbIsDisabled.log(.critical)
        }
        let isOk = pm_osakaname.execute { $0.checkDBAccess() }
        if isOk == false {
            throw FileMakerError.noConnection.log(.critical)
        }
    }
    /// DBにアクセス可能ならtrueを返す
    public static func testDBAccess() -> Bool {
        do {
            try checkConnection()
            return true
        } catch {
            return false
        }
    }

    /// 現在使用していないアイドル状態のセッションを閉じる
    public static func logoutAll(force: Bool = false) {
        serverCache.logoutAll(force: force)
    }
    
    /// 現在使用していないアイドル状態のセッションを非同期で閉じる
    public static func logoutAllAsync(force: Bool = false) {
        DispatchQueue.global(qos: .utility).async {
            serverCache.logoutAll(force: force)
        }
    }
    /// 全てのサーバーの現在の待機数の合計
    public static var poolCount: Int { serverCache.poolCount }
    /// 全てのサーバーの現在の接続数の合計
    public static var connectionCount: Int { serverCache.connectingCount }
    /// DBについてログをとる
    public func log(_ text: String, detail: String?, level: DMLogLevel = .information) {
        mainLogSystem.log("\(filename):\(text)", detail: detail, level: level)
    }
}
