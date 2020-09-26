//
//  FileMakerSession.swift
//  DataManager
//
//  Created by manager on 2019/02/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation
#if os(Linux)
import FoundationNetworking
let commandPath = "/home/pi/session.sh"
#elseif os(macOS)
let commandPath = "/Users/manager/session.sh"
#endif


struct FileMakerPortal {
    let name : String
    let limit : Int?
    
    init(name:String, limit:Int? = nil) {
        self.name = name
        self.limit = limit
    }
}

typealias FileMakerQuery = [String: String]

private let expireSeconds: Double = 15 * 60 - 60 // 本来は15分だが余裕を見て60秒減らしている

final class FileMakerSession: NSObject, URLSessionDelegate {
    #if os(Linux)
    let extConnection: Bool = true
    #elseif os(macOS)
    let extConnection: Bool = false
    #endif
    let dbURL: URL
    let user: String
    let password: String
    private let sem = DispatchSemaphore(value: 0)
    lazy var session: URLSession = {
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: nil)
        return session
    }()
    
    init(url: URL, user: String, password: String) {
        self.dbURL = url
        self.user = user
        self.password = password
    }
    deinit {
        self.logout()
    }
    
    private var ticket: (token: String, expire: Date)?
    var activeToken: String? {
        guard let ticket = self.ticket else { return nil }
        let now = Date()
        return now < ticket.expire ? ticket.token : nil
    }
    
    var isConnect: Bool {
        return self.activeToken != nil
    }
    
    func prepareToken(reuse: Bool = true) throws -> String {
        if reuse == true, let token = self.activeToken { return token }
        return try makeNewToken()
    }
    
    func makeNewToken() throws -> String {
        let url = self.dbURL.appendingPathComponent("sessions")
        let expire: Date = Date(timeIntervalSinceNow: expireSeconds)
        let token = try exec_connect(to: url)
        self.ticket = (token:token, expire: expire)
        return token
    }
    
    func checkDBAccess() -> Bool {
        let token = try? self.prepareToken()
        return token != nil
    }
    
    private func logout(with token: String) {
        let url = self.dbURL.appendingPathComponent("sessions").appendingPathComponent(token)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.session.dataTask(with: request) { _, _, error in
            self.sem.signal()
        }.resume()
        sem.wait()
        self.ticket = nil
    }
    
    @discardableResult func logout() -> Bool {
        guard let token = self.activeToken else { return false }
        self.logout(with: token)
        return true
    }
    
    // MARK: - <URLSessionDelegate>
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // そもそもLinuxではDelegateが呼ばれないため無効
        let credential: URLCredential?
    #if os(Linux)
        credential = URLCredential(user: self.user, password: self.password, persistence: .permanent) // 仮実装。実際には無意味
    #else
        if let trust = challenge.protectionSpace.serverTrust {
            credential = URLCredential(trust:trust)
        } else {
            credential = nil
        }
        #endif
        completionHandler(.useCredential, credential)
    }
    
    func fetch(layout: String, sortItems: [(String, FileMakerSortType)] = [], portals: [FileMakerPortal] = []) throws -> [FileMakerRecord] {
        let sortItems = sortItems.map { FileMakerSortItem(fieldName: $0.0, sortOrder: $0.1) }
        let token = try self.prepareToken()
        var result: [FileMakerRecord] = []
        
        var offset = 1
        let limit = 100
        var isRepeat = false
        
        repeat {
            var url = dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
            var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "_offset", value: "\(offset)"),
                URLQueryItem(name: "_limit", value: "\(limit)")
            ]
            if sortItems.isEmpty == false {
                let encoder = JSONEncoder()
                guard let data = try? encoder.encode(sortItems) else { throw FileMakerError.fetch(message: "sortItem encoding") }
                let str = String(data: data, encoding: .utf8)
                let item = URLQueryItem(name: "_sort", value: str)
                queryItems.append(item)
            }
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
            url = comp.url!
            
            let response = try exec_get(url: url, token: token)
            let newRequest = (response["data"] as? [Any])?.compactMap { FileMakerRecord(json:$0) } ?? []
            let count = newRequest.count

            result.append(contentsOf: newRequest)
            offset += limit
            isRepeat = count >= limit
        } while (isRepeat)
        return result
    }
    
    struct SearchRequest: Encodable {
        let query: [[String: String]]
        let sort: [FileMakerSortItem]?
        let offset: Int
        let limit: Int
    }
    
    func find(layout: String, recordID: String) throws -> FileMakerRecord? {
        return try self.find(layout: layout, query: [["recordId": recordID]]).first
    }
    
    func find(layout: String, query: [FileMakerQuery], sortItems: [(String, FileMakerSortType)] = [], max: Int? = nil) throws -> [FileMakerRecord] {
        let token = try self.prepareToken()
        var offset = 1
        let limit = 100
        var result: [FileMakerRecord] = []
        
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("_find")
        let sort: [FileMakerSortItem]? = sortItems.isEmpty ? nil : sortItems.map { FileMakerSortItem(fieldName: $0.0, sortOrder: $0.1) }
        repeat {
            let json = SearchRequest(query: query, sort:sort , offset: offset, limit: limit)
            let (message, response) = try exec_post(url: url, token: token, request: json)
                if message.contains("Field") {
                    throw FileMakerError.response(message: "Field情報がない。layout:\(layout) query:\(query)")
                }
            let newResult = (response["data"] as? [Any])?.compactMap { FileMakerRecord(json:$0) } ?? []
            let count = newResult.count
            result.append(contentsOf: newResult)
            offset += limit
            if let max = max, result.count >= max { break }
            if count < limit { break }
        } while(true)
        return result
    }
    
    func delete(layout: String, recordID: String) throws {
        let token = try self.prepareToken()
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records").appendingPathComponent(recordID)
        var isOk = false
        var errorMessage = ""
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            guard   let data      = data, error == nil,
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String else { return }
            isOk = (Int(code) == 0)
            errorMessage = message
        }.resume()
        sem.wait()
        if isOk == false { throw FileMakerError.DELETE(message: errorMessage) }
    }
    
    func update(layout: String, recordID: String , fields: FileMakerQuery) throws {
        let token = try self.prepareToken()
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records").appendingPathComponent(recordID)
        let json = ["fieldData" : fields]
        try exec_patch(url: url, token: token, request: json)
    }
    
    @discardableResult func insert(layout: String, fields: FileMakerQuery) throws -> String {
        let token = try self.prepareToken()
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
        let json = ["fieldData": fields]
        let (_, res) = try exec_post(url: url, token: token, request: json)
        return (res["recordId"] as? String) ?? ""
    }
    
    func download(_ url: URL) throws -> Data {
        var result: Data = Data()
        var errorCode: Error? = nil
        self.session.downloadTask(with: url) { (data , res, error) in
            if error == nil {
                if let url = data {
                    do {
                        result = try Data(contentsOf: url)
                    } catch {
                        errorCode = error
                    }
                }
            }
            self.sem.signal()
        }.resume()
        self.sem.wait()
        if let error = errorCode { throw error }
        return result
    }
    
    func executeScript(layout: String, script: String, param: String) throws {
        let token = try self.prepareToken()
        var url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw FileMakerError.execute(message: "URL Components") }
        components.queryItems = [
        URLQueryItem(name: "script", value: script),
        URLQueryItem(name: "script.param", value: param)
        ]
        url = components.url!
        let _ = try exec_get(url: url, token: token)
    }
}

func makeQueryDayString(_ range: ClosedRange<Day>?) -> String? {
    guard let range = range else { return nil }
    let from = range.lowerBound
    let to = range.upperBound
    if from == to {
        return "\(from.fmString)"
    } else {
        return "\(from.fmString)...\(to.fmString)"
    }
}

extension FileMakerSession {
    // MARK: - CONNECT
    func exec_connect(to url: URL) throws -> String {
        #if os(Linux) || os(macOS)
        return try !extConnection ? exec_connect_self(to: url, user: self.user, password: self.password) : exec_connect_ext(to: url, user: self.user, password: self.password)
        #else
        return try exec_connect_self(to: url, user: self.user, password: self.password)
        #endif
    }
    #if os(Linux) || os(macOS)
    func exec_connect_ext(to url: URL, user: String, password: String) throws -> String {
        let data = execCommand(commandPath, ["CONNECT", user, password, url.absoluteString])
        return try process_connect(data: data)
    }
    #endif

    func exec_connect_self(to url: URL, user: String, password: String) throws -> String {
        var result: Result<String, Error> = .failure(FileMakerError.tokenCreate(message: "データ無し"))
        
        var request = URLRequest(url: url)
        let auth = "\(user):\(password)".data(using: .utf8)!.base64EncodedString()
        let lock = NSLock()
        lock.lock()
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)!
        self.session.dataTask(with: request) { data, _, error in
            defer { lock.unlock() }
            if let error = error {
                result = .failure(error)
                return
            }
            do {
                let token = try self.process_connect(data: data)
                result = .success(token)
            } catch {
                result = .failure(error)
            }
        }.resume()
        lock.lock()
        lock.unlock()
        return try result.get()
    }
    func process_connect(data: Data?) throws -> String {
        guard   let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response = json["response"] as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let message = messages[0]["message"] as? String,
                let code = messages[0]["code"] as? String,
                let codeNum = Int(code) else { throw FileMakerError.tokenCreate(message: "") }
        if codeNum == 0, let token = response["token"] as? String {
            return token
        } else {
            throw FileMakerError.tokenCreate(message: message)
        }
    }
     
    // MARK: - GET
    func exec_get(url: URL, token: String) throws -> [String: Any] {
        #if os(Linux) || os(macOS)
        return try !extConnection ? exec_get_self(url: url, token: token) : exec_get_ext(url: url, token: token)
        #else
        return try exec_get_self(url: url, token: token)
        #endif
    }
    #if os(Linux) || os(macOS)
    func exec_get_ext(url: URL, token: String) throws -> [String: Any] {
        let data = execCommand(commandPath, ["GET", token, url.absoluteString])
        return try process_get(data: data)
    }
    #endif
    func exec_get_self(url: URL, token: String) throws -> [String: Any] {
        var result: Result<[String: Any], Error> = .success([:])
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            if let error = error {
                result = .failure(error)
                return
            }
            do {
                let list = try self.process_get(data: data)
                result = .success(list)
            } catch {
                result = .failure(error)
            }
        }.resume()
        sem.wait()
        return try result.get()
    }

    func process_get(data: Data?) throws -> [String: Any] {
        guard   let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response = json["response"] as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let message = messages[0]["message"] as? String,
                let code = messages[0]["code"] as? String,
                let codeNum = Int(code) else { throw FileMakerError.GET(message: "") }
        if codeNum != 0 {
            throw FileMakerError.GET(message: message)
        }
        return response
    }
    
    // MARK: - POST
    func exec_post<T: Encodable>(url: URL, token: String, request: T) throws -> (message: String, response: [String: Any]) {
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        #if os(Linux) || os(macOS)
        return try !extConnection ? exec_post_self(url: url, token: token, request: data) : exec_post_ext(url: url, token: token, request: data)
        #else
        return try exec_post_self(url: url, token: token, request: data)
        #endif
    }
    #if os(Linux) || os(macOS)
    func exec_post_ext(url: URL, token: String, request: Data) throws -> (message: String, response: [String: Any]) {
        let resuestStr = String(data: request, encoding: .utf8) ?? ""
        try resuestStr.write(to: URL(fileURLWithPath: "/Users/manager.aaa"), atomically: true, encoding: .utf8)
        let data = execCommand(commandPath, ["POST", token, url.absoluteString, resuestStr])
        return try process_post(data: data)
    }
    #endif
    func exec_post_self(url: URL, token: String, request data: Data) throws -> (message: String, response: [String: Any]) {
        var result: Result<(message: String, response: [String: Any]), Error> = .success(("",[:]))
        var request = URLRequest(url: url,timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        self.session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            if let error = error {
                result = .failure(error)
                return
            }
            do {
                let list = try self.process_post(data: data)
                result = .success(list)
            } catch {
                result = .failure(error)
            }
        }.resume()
        sem.wait()
        return try result.get()
    }
    func process_post(data: Data?) throws -> (message: String, response: [String: Any]) {
        guard   let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response = json["response"] as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let message = messages[0]["message"] as? String,
                let code = messages[0]["code"] as? String,
                let codeNum = Int(code) else { return ("",[:]) }
        if codeNum != 0 && codeNum != 401 {
            throw FileMakerError.POST(message: message)
        }
        return (message, response)
    }
    
    // MARK: - PATCH
    func exec_patch<T: Encodable>(url: URL, token: String, request: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        #if os(Linux) || os(macOS)
        try !extConnection ? exec_patch_self(url: url, token: token, request: data) : exec_patch_ext(url: url, token: token, request: data)
        #else
        try exec_patch_self(url: url, token: token, request: data)
        #endif
    }
    #if os(Linux) || os(macOS)
    func exec_patch_ext(url: URL, token: String, request: Data) throws {
        let resuestStr = String(data: request, encoding: .utf8) ?? ""
        let data = execCommand(commandPath, ["PATCH", token, url.absoluteString, resuestStr])
        try process_patch(data: data)
    }
    #endif
    func exec_patch_self(url: URL, token: String, request data: Data) throws {
        var result: Error? = nil
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        self.session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            if let error = error {
                result = error
                return
            }
            do {
                try self.process_patch(data: data)
            } catch {
                result = error
            }
        }.resume()
        sem.wait()
        if let error = result { throw error }
    }
    func process_patch(data: Data?) throws {
        guard   let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let message = messages[0]["message"] as? String,
                let code = messages[0]["code"] as? String,
                let codeNum = Int(code) else { throw FileMakerError.PATCH(message: "no data(patch)") }
        if codeNum != 0 {
            throw FileMakerError.PATCH(message: message)
        }
    }
    
    // MARK: - DELETE
    func exec_delete(url: URL, token: String) throws {
        #if os(Linux) || os(macOS)
        try !extConnection ? exec_delete_self(url: url, token: token) : exec_delete_ext(url: url, token: token)
        #else
        try exec_delete_self(url: url, token: token)
        #endif
    }
    #if os(Linux) || os(macOS)
    func exec_delete_ext(url: URL, token: String) throws {
        let data = execCommand(commandPath, ["DELETE", token, url.absoluteString])
        try process_delete(data: data)
    }
    #endif
    func exec_delete_self(url: URL, token: String) throws {
        var result: Error? = nil
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            if let error = error {
                result = error
                return
            }
            do {
                try self.process_patch(data: data)
            } catch {
                result = error
            }
        }.resume()
        sem.wait()
        if let error = result { throw error }
    }
    func process_delete(data: Data?) throws {
        guard   let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let message = messages[0]["message"] as? String,
                let code = messages[0]["code"] as? String,
                let codeNum = Int(code) else { throw FileMakerError.DELETE(message: "no data(delete)") }
        if codeNum != 0 {
            throw FileMakerError.DELETE(message: message)
        }
    }
}

// MARK: -
#if os(macOS) || os(Linux)
func execCommand(_ command: String, _ args: [String]) -> Data {
    let fm = FileManager.default
    let hd = fm.homeDirectoryForCurrentUser
    let output = Pipe()
    let error = Pipe()
    let task = Process()
    task.launchPath = command
    task.arguments = args
    task.standardOutput = output
    task.standardError = error
    task.currentDirectoryPath = hd.path
    task.launch()
    task.waitUntilExit()
    let data = output.fileHandleForReading.availableData
    if data.isEmpty {
        let edata = error.fileHandleForReading.availableData
        if let str = String(data: edata, encoding: .utf8) {
            print(str)
        }
    }
    if let str = String(data: data, encoding: .utf8) {
        print(str)
    }
    return data
}
#endif
