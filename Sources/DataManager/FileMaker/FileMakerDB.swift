//
//  FileMakerDB.swift
//  DataManager
//
//  Created by 四熊泰之 on 2019/01/27.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

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

/// サーバー上のデータベースファイル
public final class FileMakerDB: DMLogger {
    /// 再実行前の待機時間
    static let retryInterval: TimeInterval = 1.0

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
    let dbURL: URL
    /// サーバー
    let server: FileMakerServer
    /// ファイル名
    let filename: String
    /// ユーザー名
    let user: String
    /// パスワード
    let password: String

    private init(server: String, filename: String, user: String, password: String) {
        self.server = FileMakerServerCache.shared.server(server)
        self.dbURL = self.server.makeURL(with: filename)
        self.filename = filename
        self.user = user
        self.password = password
    }

    private let exportLock = NSRecursiveLock()
    
    /// 接続セッションを取得する
    func retainExportSession() -> FileMakerSession {
        exportLock.lock()
        return server.pullSession(url: self.dbURL, user: self.user, password: self.password)
    }
    
    /// セッションを解放する
    func releaseExportSession(_ session: FileMakerSession) {
        server.putSession(session)
        exportLock.unlock()
    }

    /// 接続セッションを取得する
    private func retainSession() -> FileMakerSession {
//        exportLock.lock(); defer { exportLock.unlock() }
        return server.pullSession(url: self.dbURL, user: self.user, password: self.password)
    }
    
    /// セッションを解放する
    private func releaseSession(_ session: FileMakerSession) {
//        exportLock.lock(); defer { exportLock.unlock() }
        server.putSession(session)
    }
    
    /// セッションを一時的に取得して作業を行う
    /// - Parameter work: セッション上で行う作業。なんらかの値を返す
    /// - Returns: 作業の返り値。Voidの時もある
    func execute<T>(_ work: (FileMakerSession) throws -> T) rethrows -> T {
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
                    Thread.sleep(forTimeInterval: FileMakerDB.retryInterval)
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
    func find(layout: String, recordId: String) throws -> FileMakerRecord? {
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
    func update(layout: String, recordId: FileMakerRecordID, fields: FileMakerQuery) throws {
        try checkStop()
        return try self.execute { try $0.update(layout: layout, recordID: recordId, fields: fields) }
    }
    ///指定されたレイアウトのrecordIdのレコードを削除する
    func delete(layout: String, recordId: FileMakerRecordID) throws {
        try checkStop()
        return try self.execute { try $0.delete(layout: layout, recordID: recordId) }
    }
    
    /// 指定されたレイアウトにfieldsを用いてレコードを作成する
    @discardableResult
    func insert(layout: String, fields: FileMakerQuery) throws -> FileMakerRecordID {
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
    public static func logoutAll() {
        FileMakerServerCache.shared.logoutAll()
    }
    /// 全てのサーバーの現在の待機数の合計
    public static var poolCount: Int { FileMakerServerCache.shared.poolCount }
    /// 全てのサーバーの現在の接続数の合計
    public static var connectionCount: Int { FileMakerServerCache.shared.connectingCount }
    /// DBについてログをとる
    public func registLogData<T: DMRecordData>(_ data: T, _ level: DMLogLevel) {
        currentLogSystem.registLogData(DMFileMakerDBRecord(self, data: data),  level)
    }
}
