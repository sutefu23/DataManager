//
//  FileMakerSession.swift
//  DataManager
//
//  Created by manager on 2019/02/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

/// tokenの寿命
private let expireSeconds: Double = 10
/// token解放後のtcp/ipセッションの寿命
private let expireSeconds2: Double = 30

private let sessionIDGenerator = SerialGenerator()

// MARK: -
/// FileMaker Serverとの通信
final class FileMakerSession: Loggable {
    typealias ID = ObjectID
    /// ベースとなるURL
    let url: URL
    /// 接続ユーザー名
    private let user: String
    /// 接続パスワード
    private let password: String
    /// サーバーへの接続
    private var connection: DMHttpConnection
    /// 一度に取り出すレコードの数
    private let pageCount = 100
    
    let id: ObjectID = sessionIDGenerator.generateID()

    init(url: URL, user: String, password: String, session: FileMakerSession? = nil) {
        session?.logout(waitAfterLogout: false)
        self.url = url
        self.user = user
        self.password = password
        self.connection = session?.connection ?? DMHttpConnection()
    }
    
    deinit {
        // tokenを保持している場合、解放する
        self.logout(waitAfterLogout: false)
    }
    
    // MARK: - 接続管理
    /// (token, 自動切断までの時間, 自動切断時間後にtokenを使いたくなった場合のロスタイム)
    private var ticket: (token: String, expire: Date, extendExpire: Date)? {
        didSet {
            if ticket == nil {
                sessionExpire = Date(timeIntervalSinceNow: expireSeconds2)
            } else {
                sessionExpire = nil
            }
        }
    }
    /// logout後のセッションの有効期限
    private var sessionExpire: Date? // logout後のexpire
    private var activeToken: String? {
        guard let ticket = self.ticket else { return nil }
        if Date() < ticket.extendExpire {
            return ticket.token
        }
        return nil
    }

    /// token期限を延長する
    func updateTokenExpire() {
        ticket?.extendExpire = Date(timeIntervalSinceNow: expireSeconds * 2)
        ticket?.expire = Date(timeIntervalSinceNow: expireSeconds)
    }

    /// tokenを保有している場合true
    var hasToken: Bool { return self.ticket?.token != nil }
    
    /// 有効期限内のtokenを保有している場合true
    var hasValidToken: Bool {
        guard let expire = self.ticket?.expire else { return false }
        return expire > Date()
    }
    /// 有効期限内のTCP/IPセッションを保有している場合true
    var hasValidConnection: Bool {
        guard self.ticket == nil, let expire = self.sessionExpire else { return true }
        return expire > Date()
    }
    
    /// 接続可能な状態にする
    private func prepareToken(reuse: Bool = true) throws -> String {
        if reuse {
            if let token = self.activeToken { return token }
        } else {
            self.logout(waitAfterLogout: true)
        }
        let url = self.url.appendingPathComponent("sessions")
        let response = try connection.callFileMaker(url: url, method: .POST, authorization: .Basic(user: self.user, password: self.password), object: Dictionary<String, String>())
        guard response.code == 0, case let token as String = response["token"] else {
            Thread.sleep(forTimeInterval: 15)
            throw FileMakerError.tokenCreate(message: response.message, code: response.code)
                .log(self, .critical)
        }
        log("token取得", detail: token)
        Thread.sleep(forTimeInterval: 0.5)
        let extendExpire: Date = Date(timeIntervalSinceNow: expireSeconds * 2)
        let expire: Date = Date(timeIntervalSinceNow: expireSeconds)
        self.ticket = (token: token, expire: expire, extendExpire: extendExpire)
        return token
    }
    
    /// DBへの接続が可能ならtrue
    func checkDBAccess() -> Bool {
        let token = try? self.prepareToken()
        return token != nil
    }

    /// 接続を切断状態にする
    @discardableResult
    func logout(waitAfterLogout: Bool) -> Bool {
        guard let token = self.ticket?.token else { return false }
        let url = self.url.appendingPathComponent("sessions").appendingPathComponent(token)
        do {
            log("token削除")
            let response = try connection.callFileMaker(url: url, method: .DELETE)
            if response.code != 0 {
                self.log("token削除失敗（\(response.message)）", level: .warning)
            }
            if waitAfterLogout {
                Thread.sleep(forTimeInterval: 0.1)
            }
        } catch {
            error.asyncShowAlert()
        }
        self.ticket = nil
        return true
    }
    /// セッションを無効化する
    func invalidate() {
        self.logout(waitAfterLogout: false)
        log("セッション終了")
        self.connection.invalidate()
    }
    
    // MARK: - レコード操作
    /// レコードを取り出す
    func fetch(layout: String, sortItems: [(String, FileMakerSortType)] = [], portals: [FileMakerPortal] = []) throws -> [FileMakerRecord] {
        var result: [FileMakerRecord] = []
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
        let limit = pageCount
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

        let limit: Int
        if let max = max, max < pageCount { limit = max } else { limit = pageCount }
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
        return try connection.call(url: url, method: .GET, authorization: nil, contentType: nil, body: nil) ?? Data()
    }
    
    /// スクリプトを実行する
    func executeScript(layout: String, script: String, param: String) throws {
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
    }
    
    /// missingField発生時のリトライ
    func checkMissing() {
        debugLog("recover field missing")
        self.logout(waitAfterLogout: false)
        let waitTime: TimeInterval
        if let date = lastMissingDate, date > Date() {
            debugLog("wait field missing")
            waitTime = expireSeconds
        } else {
            waitTime = 1.0
        }
        Thread.sleep(forTimeInterval: waitTime)
        lastMissingDate = Date(timeIntervalSinceNow: expireSeconds + expireSeconds2)
    }
    var lastMissingDate: Date?
    
    func allResetSession() {
        self.logout(waitAfterLogout: false)
        self.connection.invalidate()
        self.connection = DMHttpConnection()
    }

    func log(_ text: String, level: DMLogLevel = .information) {
        self.log(text, detail: "", level: level)
    }

    func log(_ text: String, detail: String, level: DMLogLevel = .information) {
        let record = DMSessionRecord(self, title: text, detail: detail)
        logSystem.registRecord(record, level)
    }
}

// MARK: - FileMaker専用処理
/// ポータル取得情報
struct FileMakerPortal {
    let name: String
    let limit: Int?
    
    init(name: String, limit: Int? = nil) {
        self.name = name
        self.limit = limit
    }
}

/// FileMaker検索条件
typealias FileMakerQuery = [String: String]

extension DMHttpConnectionProtocol {
    /// FileMakerSeverと通信する
    func callFileMaker(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization? = nil, contentType: DMHttpContentType? = .JSON, data: Data? = nil) throws -> FileMakerResponse {
        guard let data = try self.call(url: url, method: method, authorization: authorization, contentType: contentType, body: data)
            else { return FileMakerResponse(code: nil, message: "レスポンスがない", response: [:]) }
        guard case let json as [String: Any] = try JSONSerialization.jsonObject(with: data)
            else { return FileMakerResponse(code: nil, message: "レスポンスをJSONに変換できない", response: [:]) }
        guard case let messages as [[String: Any]] = json["messages"]
            else { return FileMakerResponse(code: nil, message: "レスポンスにmessagesが存在しない", response: [:]) }
        guard case let codeString as String = messages[0]["code"]
            else { return FileMakerResponse(code: nil, message: "レスポンスにcodeが存在しない", response: [:]) }
        let response = (json["response"] as? [String: Any]) ?? [:]
        let message = (messages[0]["message"] as? String) ?? ""
        return FileMakerResponse(code: Int(codeString), message: message, response: response)
    }
    
    func callFileMaker<T: Encodable>(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization? = nil, contentType: DMHttpContentType? = .JSON, object: T) throws -> FileMakerResponse {
        try autoreleasepool {
            let encoder = JSONEncoder()
            let data = try encoder.encode(object)
            let response = try self.callFileMaker(url: url, method: method, authorization: authorization, contentType: contentType, data: data)
            return response
        }
    }
}

struct FileMakerResponse {
    let code: Int?
    let message: String
    let response: [String: Any]
    
    subscript(key: String) -> Any? { response[key] }
    var records: [FileMakerRecord]? {
        guard case let dataArray as [Any] = self["data"] else { return nil }
        return dataArray.compactMap { FileMakerRecord(json: $0) }
    }
}
