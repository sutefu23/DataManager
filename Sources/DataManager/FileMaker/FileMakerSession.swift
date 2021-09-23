//
//  FileMakerSession.swift
//  DataManager
//
//  Created by manager on 2019/02/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

/// FileMaker Serverとの通信
public final class FileMakerSession: DMLogger {
    // MARK: - 定数
    /// tokenの寿命
    static let expireSeconds: TimeInterval = 10
    /// スリープ復帰想定の追加のexpire時間
    static let expireSeconds2: TimeInterval = 10 * 60 - expireSeconds
    /// token解放後のtcp/ipセッションの寿命
    static let tcpExpireSeconds: TimeInterval = 30
    
    /// ウエイトの最大値
    static let maxWaitTime: TimeInterval = 3 * 10
    /// ウエイトの最小時間
    static let minWaitTime: TimeInterval = 0.1
    /// ウエイト時間の調整
    static func clampWaitTime(_ waitTime: TimeInterval) -> TimeInterval {
        return min(max(waitTime, minWaitTime), maxWaitTime)
    }
    /// 一度に取り出すレコードの数
    static let pageCount = 100
    /// セッションの通し番号を生成する
    private static let sessionIDGenerator = SerialGenerator()

    // MARK: - プロパティ
    typealias ID = ObjectID
    /// ベースとなるURL
    let url: URL
    /// 接続ユーザー名
    private let user: String
    /// 接続パスワード
    private let password: String
    /// サーバーへの接続
    private let connection: DMHttpConnection
    /// セッションID。これがそのまま通し番号になる
    let id: ObjectID = FileMakerSession.sessionIDGenerator.generateID()

    // MARK: - 初期化
    /// 指定されたサーバーURLとユーザー名・パスワードでセッションを生成する。sessionを指定した場合sessionからconnectionを流用する形で初期化を行う
    init(url: URL, user: String, password: String, session: FileMakerSession? = nil) {
        session?.logout(waitAfterLogout: nil) // sessionについて、tokenは解放しておく
        self.url = url
        self.user = user
        self.password = password
        self.connection = session?.connection ?? DMHttpConnection()
    }
    
    deinit {
        // tokenを保持している場合、解放する
        self.logout(waitAfterLogout: nil)
    }
    
    // MARK: - 接続管理

    /// token期限を延長する
    func updateTokenExpire() {
        switch state {
        case .login(token: let token, expire: _):
            self.state = .login(token: token, expire: Date(timeIntervalSinceNow: FileMakerSession.expireSeconds))
        default:
            break
        }
    }

    /// セッションの状態
    enum State {
        /// 初期化直後。セッション待機中
        case initialState
        /// token作成中。expireを過ぎるとlogpout
        case login(token: String, expire: Date)
        /// token削除後だが接続は存在している。expireを過ぎると切断
        case logout(expire: Date)
        /// セッションが切断されている
        case invalid
    }
    private var state: State = .initialState
    
    /// tokenを保有している場合true
    var hasToken: Bool {
        switch state {
        case .login:
            return true
        default:
            return false
        }
    }
    
    /// expireを過ぎたtokenがある場合true
    var hasDirtyToken: Bool {
        switch state {
        case .login(token: _, expire: let expire):
            return expire <= Date()
        default:
            return false
        }
    }
    
    /// 有効期限内のtokenを保有している場合true
    var hasValidToken: Bool {
        switch state {
        case .login(token: _, expire: let expire):
            return expire > Date()
        default:
            return false
        }
    }
    /// 有効期限内のTCP/IPセッションを保有している場合true
    var hasExpiredConnection: Bool {
        switch state {
        case .logout(expire: let expire):
            return expire <= Date()
        default:
            return false
        }
    }
    
    /// 接続可能な状態にする
    private func prepareToken() throws -> String {
        // 使えるtokenがあるなら、再利用する
        switch state {
        case .login(token: let token, expire: let expire):
            let now = Date()
            if expire > now { return token }
            if expire.addingTimeInterval(FileMakerSession.expireSeconds2) > now { return token }
            log("スリープ復帰検知")
            self.logout(waitAfterLogout: FileMakerSession.minWaitTime)
        case .invalid:
            throw FileMakerError.internalError(message: "無効化されたTCPセッションを再利用しようとした")
        case .logout, .initialState:
            break
        }
        // token申請
        let url = self.url.appendingPathComponent("sessions")
        let response = try connection.callFileMaker(url: url, method: .POST, authorization: .Basic(user: self.user, password: self.password), object: Dictionary<String, String>())
        guard response.code == 0 && response.message == "OK", case let token as String = response["token"] else {
            Thread.sleep(forTimeInterval: 15)
            throw FileMakerError.tokenCreate(message: response.message, code: response.code)
                .log(self, .critical)
        }
        log("token取得", detail: token)
        // tokenと有効期限を保存する
        self.state = .login(token: token, expire: Date(timeIntervalSinceNow: FileMakerSession.expireSeconds))
        return token
    }
    
    /// DBへの接続が可能ならtrue
    func checkDBAccess() -> Bool {
        let token = try? self.prepareToken()
        return token != nil
    }

    /// 接続を切断状態にする
    func logout(waitAfterLogout: TimeInterval?) {
        switch state {
        case .login(token: let token, expire: _):
            let url = self.url.appendingPathComponent("sessions").appendingPathComponent(token)
            do {
                log("token削除")
                let response = try connection.callFileMaker(url: url, method: .DELETE)
                if response.code != 0 {
                    log("token削除失敗（\(response.message)）", level: .error)
                }
                if let waitAfterLogout = waitAfterLogout {
                    let waitTime = FileMakerSession.clampWaitTime(waitAfterLogout)
                    Thread.sleep(forTimeInterval: waitTime)
                }
            } catch {
                error.asyncShowAlert()
            }
            self.state = .logout(expire: Date(timeIntervalSinceNow: FileMakerSession.tcpExpireSeconds))
            return
        default:
            return
        }
    }
    /// セッションを無効化する
    func invalidate() {
        switch state {
        case .login:
            self.logout(waitAfterLogout: nil)
        case .logout, .initialState:
            break
        case .invalid:
            return
        }
        self.connection.invalidate()
        log("セッション無効化")
    }
    
    // MARK: - レコード操作
    /// レコードを取り出す
    func fetch(layout: String, sortItems: [(String, FileMakerSortType)] = [], portals: [FileMakerPortal] = []) throws -> [FileMakerRecord] {
        log(layout: layout, "全件読み込み", detail: "")
        let sortQueryItem: URLQueryItem?
        if !sortItems.isEmpty {
            let request = sortItems.map { FileMakerSortItem(fieldName: $0.0, sortOrder: $0.1) }
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(request) else { throw FileMakerError.fetch(message: "sortItem encoding").log(self, .critical) }
            let str = String(data: data, encoding: .utf8)
            sortQueryItem = URLQueryItem(name: "_sort", value: str)
        } else {
            sortQueryItem = nil
        }
        let url = self.url.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
        var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        let token = try self.prepareToken()

        var offset = 1
        let limit = FileMakerSession.pageCount
        var result: [FileMakerRecord] = []
        while true {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "_offset", value: "\(offset)"),
                URLQueryItem(name: "_limit", value: "\(limit)")
            ]
            // 検索条件
            if let item = sortQueryItem { queryItems.append(item) }
            // portal
            var names: [String] = []
            for portal in portals where portal.limit != 0 {
                if let limit = portal.limit {
                    names.append(portal.name)
                    let name = "_limit.\(portal.name)"
                    let item = URLQueryItem(name: name, value: "\(limit)")
                    queryItems.append(item)
                }
            }
            if names.isEmpty == false {
                let value = "[" + names.map { "\"" + $0 + "\"" }.joined(separator: ",") + "]"
                queryItems.append(URLQueryItem(name: "portal", value: value))
            }
            comp.queryItems = queryItems
            
            let response = try connection.callFileMaker(url: comp.url!, method: .GET, authorization: .Bearer(token: token))
            guard response.code == 0 else {
                throw FileMakerDetailedError(table: layout, work: .fetch, response: response).log(self)
            }
            guard let newRecords = response.records else { break }
            result.append(contentsOf: newRecords)
            let count = newRecords.count
            if count < limit { break }
            assert(count == limit)
            offset += count
        }
        return result
    }
    
    /// 指定されたrecordIdのレコードを取り出す
    func find(layout: String, recordID: String) throws -> FileMakerRecord? {
        try self.find(layout: layout, query: [["recordId": recordID]]).first
    }
    
    /// レコードを検索する
    func find(layout: String, query: [FileMakerQuery], sortItems: [(String, FileMakerSortType)] = [], max: Int? = nil) throws -> [FileMakerRecord] {
        struct SearchRequest: Encodable {
            let query: [FileMakerQuery]
            let sort: [FileMakerSortItem]?
            var offset: Int
            let limit: Int
        }
        var result: [FileMakerRecord] = []
        log(layout: layout, "検索開始", detail: query.makeText() ?? query.makeKeys())
        let limit: Int
        if let max = max, max < FileMakerSession.pageCount {
            limit = max
        } else {
            limit = FileMakerSession.pageCount
        }
        assert(limit >= 1)
        
        let url = self.url.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("_find")
        let sort: [FileMakerSortItem]? = sortItems.isEmpty ? nil : sortItems.map { FileMakerSortItem(fieldName: $0.0, sortOrder: $0.1) }
        var request = SearchRequest(query: query, sort: sort , offset: 1, limit: limit)

        let token = try self.prepareToken()
        while true {
            let response = try connection.callFileMaker(url: url, method: .POST, authorization: .Bearer(token: token), object: request)
            guard response.code == 0 || response.code == 401 else {
                throw FileMakerDetailedError(table: layout, work: .find(query: query), response: response).log(self)
            }
            if response.message.contains("Field") {
                throw FileMakerError.response(message: "Field情報がない。layout:\(layout) query:\(query)").log(self, .critical)
            }
            guard let newRecords = response.records else { break }
            result.append(contentsOf: newRecords)
            if max != nil { break }
            let count = newRecords.count
            if count < limit { break }
            assert(count == limit)
            request.offset += count
        }
        return result
    }
    
    /// レコードを削除する
    func delete(layout: String, recordID: String) throws {
        log(layout: layout, "削除", detail: "レコードID=\(recordID)")
        let token = try self.prepareToken()
        let url = self.url.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records").appendingPathComponent(recordID)
        let response = try connection.callFileMaker(url: url, method: .DELETE, authorization: .Bearer(token: token))
        if response.code != 0 {
            throw FileMakerDetailedError(table: layout, work: .delete(recordID: recordID), response: response).log(self)
        }
    }
    
    /// レコードを更新する
    func update(layout: String, recordID: String , fields: FileMakerQuery) throws {
        let token = try self.prepareToken()
        let url = self.url.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records").appendingPathComponent(recordID)
        let request = ["fieldData" : fields]
        let response = try connection.callFileMaker(url: url, method: .PATCH, authorization: .Bearer(token: token), object: request)
        if response.code != 0 {
            throw FileMakerDetailedError(table: layout, work: .update(recordID: recordID, fields: fields), response: response).log(self)
        }
    }
    
    /// レコードを追加する
    @discardableResult
    func insert(layout: String, fields: FileMakerQuery) throws -> String {
        log(layout: layout, "追加", detail: fields.makeText())

        let token = try self.prepareToken()
        let url = self.url.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
        let request = ["fieldData": fields]
        let response = try connection.callFileMaker(url: url, method: .POST, authorization: .Bearer(token: token), object: request)
        guard response.code == 0, case let recordId as String = response["recordId"] else {
            throw FileMakerDetailedError(table: layout, work: .insert(fields: fields), response: response).log(self)
        }
        return recordId
    }

    /// オブジェクトをダウンロードする
    func download(_ url: URL) throws -> Data {
        log("ダウンロード", detail: "url=\(url.path)")
        return try connection.call(url: url, method: .GET, authorization: nil, contentType: nil, body: nil) ?? Data()
    }
    
    /// スクリプトを実行する
    func executeScript(layout: String, script: String, param: String, waitTime: (main: TimeInterval, extra: TimeInterval)?) throws {
        let fromDate = Date()
        log(layout: layout, "実行", detail: "script=\(script), param=\(param)")
        let token = try self.prepareToken()
        let url = self.url.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw FileMakerError.execute(message: "URL Components", code: nil).log(self, .critical) }
        components.queryItems = [
            URLQueryItem(name: "script", value: script),
            URLQueryItem(name: "script.param", value: param)
        ]
        let response = try connection.callFileMaker(url: components.url!, method: .GET, authorization: .Bearer(token: token))
        if response.code != 0 {
            throw FileMakerDetailedError(table: layout, work: .exec(script: script, param: param), response: response).log(self)
        }
        let execTime = Date().timeIntervalSince(fromDate)
        log(layout: layout, "実行完了", detail: "実行時間 \(String(format: "%.1f", execTime))秒")
        if let (mainTime, extraTime) = waitTime {
            let waitTime = max(execTime, mainTime) + extraTime
            Thread.sleep(forTimeInterval: waitTime)
//            self.logout(waitAfterLogout: waitTime)
        }
    }
    
    /// missingField発生時のリトライ
    func checkMissing() {
        log("recover field missing対策実行")
        let waitTime: TimeInterval
        if let date = lastMissingDate, date > Date() {
            debugLog("wait field missing")
            waitTime = FileMakerSession.maxWaitTime / 2
        } else {
            waitTime = 1.0
        }
        self.logout(waitAfterLogout: waitTime)
        lastMissingDate = Date(timeIntervalSinceNow: FileMakerSession.expireSeconds + FileMakerSession.tcpExpireSeconds)
    }
    /// 次回にリトライ対策をする時間
    private var lastMissingDate: Date?
    
    // MARK: - ログ関連
    public func registLogData<T: DMRecordData>(_ data: T, _ level: DMLogLevel) {
        let data = DMFileMakerSessionRecord(self, data: data)
        currentLogSystem.registLogData(data, level)
    }
    
    /// レイアウト情報とともにログを残す
    private func log(layout: String, _ title: String, detail: String?, level: DMLogLevel = .information) {
        let data = LayoutRecord(layout, title, detail: detail)
        self.registLogData(data, level)
    }
    class LayoutRecord: DMHeaderRecordData<DMTextRecord> {
        let layout: String
        init(_ layout: String, _ title: String, detail: String?) {
            self.layout = layout
            let data = DMTextRecord(title: title, detail: detail)
            super.init(data)
        }
        override var titleHeader: String { layout }
    }
}

// MARK: - FileMaker専用処理
/// ポータル取得情報
struct FileMakerPortal {
    let name: String
    let limit: Int?
}

/// FileMaker検索条件
public typealias FileMakerQuery = [String: String]
extension Array where Element == FileMakerQuery {
    /// デバッグ用文字列表記を作成する
    func makeText() -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self), let text = String(data: data, encoding: .utf8)?.encodeLF() else { return nil }
        return text
    }
    
    /// デバッグ用のキー一覧を作成する
    func makeKeys() -> String {
        return self.map{ $0.makeKeys() }.joined(separator: "|")
    }
}

extension FileMakerQuery {
    /// デバッグ用文字列表記を作成する
    func makeText() -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self), let text = String(data: data, encoding: .utf8)?.encodeLF() else { return nil }
        return text
    }
    /// デバッグ用のキー一覧を作成する
    func makeKeys() -> String {
        return self.keys.joined(separator: ",")
    }
}

extension DMHttpConnectionProtocol {
    /// FileMakerSeverと通信する。その際dataを渡す
    func callFileMaker(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization? = nil, contentType: DMHttpContentType? = .JSON, data: Data? = nil) throws -> FileMakerResponse {
        guard let data = try self.call(url: url, method: method, authorization: authorization, contentType: contentType, body: data) else { throw FileMakerResponseError.レスポンスがない }
        do {
            guard case let json as [String: Any] = try JSONSerialization.jsonObject(with: data) else { throw FileMakerResponseError.レスポンスをJSONに変換できない }
            guard case let messages as [[String: Any]] = json["messages"] else { throw FileMakerResponseError.レスポンスにmessagesが存在しない }
            guard case let codeString as String = messages[0]["code"], let code = Int(codeString) else { throw FileMakerResponseError.レスポンスにcodeが存在しない }
            let response = (json["response"] as? [String: Any]) ?? [:]
            let message = (messages[0]["message"] as? String) ?? ""
            return FileMakerResponse(code: code, message: message, response: response)
        } catch {
            if let str = String(data: data, encoding: .utf8) {
                DMLogSystem.shared.log("JSON変換異常", detail: String(str.prefix(200)), level: .critical)
            } else {
                DMLogSystem.shared.log("JSON変換異常", detail: "UTF-8変換失敗[\(data.count)bytes]", level: .critical)
            }
            throw error
        }
    }
    
    /// FileMakerSeverと通信する。その際objectをJSONでエンコードして渡す
    func callFileMaker<T: Encodable>(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization? = nil, contentType: DMHttpContentType? = .JSON, object: T) throws -> FileMakerResponse {
        try autoreleasepool {
            let encoder = JSONEncoder()
            let data = try encoder.encode(object)
            let response = try self.callFileMaker(url: url, method: method, authorization: authorization, contentType: contentType, data: data)
            return response
        }
    }
}

/// DataAPIのレスポンス
struct FileMakerResponse {
    /// レスポンスコード
    let code: Int
    /// レスポンスメッセージ
    let message: String
    /// レスポンスデータ
    let response: [String: Any]

    subscript(key: String) -> Any? { response[key] }
    
    var records: [FileMakerRecord]? {
        guard case let dataArray as [Any] = self["data"] else { return nil }
        return dataArray.compactMap { FileMakerRecord(json: $0) }
    }
}

/// DataAPIの基本的な構造エラー
enum FileMakerResponseError: String, LocalizedError {
    case レスポンスがない
    case レスポンスをJSONに変換できない
    case レスポンスにmessagesが存在しない
    case レスポンスにcodeが存在しない
    var errorDescription: String? { self.rawValue }
}
