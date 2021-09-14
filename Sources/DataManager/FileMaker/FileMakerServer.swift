//
//  FileMakerServer.swift
//  FileMakerServer
//
//  Created by manager on 2021/09/09.
//

import Foundation

public extension UserDefaults {
    /// FileMakerへのアクセスを停止したいときはtrue
    var filemakerIsDisabled: Bool {
        get { return bool(forKey: "filemakerIsDisabled") }
        set { self.set(newValue, forKey: "filemakerIsDisabled") }
    }
    
    var fileMakerIsEnabled: Bool { !self.filemakerIsDisabled }
    
    /// サーバーへの同時接続数
    var filemakerMaxConnection: Int {
        get { FileMakerServer.maxConnection }
        set { FileMakerServer.maxConnection = newValue }
    }
}

/// サーバーオブジェクト（セッションの管理）
final class FileMakerServer: Hashable, DMLogger {
    // MARK: - 定数
    /// １台のサーバーへの最大同時接続数
    static fileprivate(set) var maxConnection = 3
    /// 最低180秒はアクセスする
    static let lastAccessInterval: TimeInterval = 180
    /// 有効期限一括チェックの周期。整数で単位は秒
    static let timerInterval: Int = 10

    // MARK: - プロパティ
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
        self.sem = DispatchSemaphore(value: FileMakerServer.maxConnection)
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
        if totalCount >= FileMakerServer.maxConnection, let last = pool.popLast() { // 再生する
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
            if abs(self.logoutBaseLine.timeIntervalSinceNow) < FileMakerServer.lastAccessInterval { return }
        }
        DispatchQueue.concurrentPerform(iterations: pool.count) {
            let pool = pool[$0]
            pool.invalidate()
        }
        pool.removeAll()
        updateLogoutBaseLine()
    }
    
    // MARK: - logger
    func registLogData<T: DMRecordData>(_ data: T, _ level: DMLogLevel) {
        currentLogSystem.registLogData(DMFileMakerServerRecord(self, data: data), level)
    }

    // MARK: - タイマー管理
    /// 有効期限処理タイマーを起動する。起動済みなら何もしない
    func startTimer() {
        lock.lock(); defer { lock.unlock() }
        if timerSet || pool.isEmpty { return }
        timerSet = true
        debugLog("start timer")
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + .seconds(FileMakerServer.timerInterval)) {
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

// MARK: - サーバーキャッシュ
let serverCache = FileMakerServerCache()

/// サーバー名に対応するサーバーオブジェクトを保持する（共用のため）
final class FileMakerServerCache {
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
