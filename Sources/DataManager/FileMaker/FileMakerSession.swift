//
//  FileMakerSession.swift
//  DataManager
//
//  Created by manager on 2019/02/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//
#if os(macOS) || os(iOS) || os(tvOS)
import Foundation

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
    let dbURL: URL
    let user: String
    let password: String
    
//    private let connection = DMHttpConnection()
//    private func callJSON(url: URL, method: DMHttpMethod, authorization: String?, contentType: String? = "application/json", content: Data?) throws -> (codeNum: Int, message: String, response:[String: Any])? {
//        guard let data = try connection.connect(url: url, method: method, authorization: authorization, contentType: contentType, content: content),
//              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//              let messages = json["messages"] as? [[String: Any]],
//              let code = messages[0]["code"] as? String,
//              let codeNum = Int(code) else { return nil }
//        let response = (json["response"] as? [String: Any]) ?? [:]
//        let message = (messages[0]["message"] as? String) ?? ""
//        return (codeNum, message, response)
//    }

    private let sem = DispatchSemaphore(value: 0)
    private(set) lazy var session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    
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
        if now < ticket.expire {
            return ticket.token
        }
        return nil
    }
    
    var isConnect: Bool {
        return self.activeToken != nil
    }
    
    func prepareToken(reuse: Bool = true) throws -> String {
        if reuse == true, let token = self.activeToken { return token }
        return try makeNewToken()
    }
    
    func makeNewToken() throws -> String {
        var result: String? = nil
        let url = self.dbURL.appendingPathComponent("sessions")
        let auth = "\(user):\(password)".data(using: .utf8)!.base64EncodedString()
        var request = URLRequest(url: url)
        var isOk = false
        var errorMessage = ""
        let expire: Date = Date(timeIntervalSinceNow: expireSeconds)
        let lock = NSLock()
        lock.lock()
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)!
        self.session.dataTask(with: request) { data, _, error in
            defer { lock.unlock() }
            guard   let data      = data, error == nil,
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String,
                let codeNum = Int(code) else { return }
            errorMessage = message
            isOk = (codeNum == 0)
            guard let token = response["token"] as? String else {
                print(messages)
                return
            }
            result = token
        }.resume()
        lock.lock()
        lock.unlock()
        guard isOk, let token = result else { throw FileMakerError.tokenCreate(message: errorMessage) }
        self.ticket = (token:token, expire:expire)
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
        let credential: URLCredential?
        if let trust = challenge.protectionSpace.serverTrust {
            credential = URLCredential(trust:trust)
        } else {
            credential = nil
        }
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
            var errorMessage = ""
            var isOk = false
            var newRequest: [FileMakerRecord] = []
            newRequest.reserveCapacity(100)
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
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            self.session.dataTask(with: request) { data, _, error in
                defer { self.sem.signal() }
                guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let message = messages[0]["message"] as? String,
                    let code      = messages[0]["code"] as? String else { return }
                isOk = (Int(code) == 0)
                errorMessage = message
                if let res = response["data"] {
                    newRequest = (res as? [Any])?.compactMap { FileMakerRecord(json:$0) } ?? []
                }
            }.resume()
            sem.wait()
            if isOk == false { throw FileMakerError.fetch(message: errorMessage) }
            let count = newRequest.count
            result.append(contentsOf: newRequest)
            offset += limit
            isRepeat = count >= limit
        } while (isRepeat)
        return result
    }
    
    struct SearchRequest: Encodable {
        let query: [[String:String]]
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
        var result : [FileMakerRecord] = []
        var resultError: Error? = nil
        
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("_find")
        let sort: [FileMakerSortItem]? = sortItems.isEmpty ? nil : sortItems.map { FileMakerSortItem(fieldName: $0.0, sortOrder: $0.1) }
        let encoder = JSONEncoder()
        repeat {
            var isOk = false
            var errorMessage = ""
            let json = SearchRequest(query: query, sort:sort , offset: offset, limit: limit)
            guard let data = try? encoder.encode(json) else { throw FileMakerError.find(message: "sortItem encoding") }
//            let rawData = String(data: data, encoding: .utf8)
            var newResult: [FileMakerRecord] = []
            var request = URLRequest(url: url,timeoutInterval: 30)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            self.session.dataTask(with: request) { data, _, error in
                defer { self.sem.signal() }
                guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let message = messages[0]["message"] as? String,
                    let code      = messages[0]["code"] as? String,
                    let errorCode = Int(code) else { return }
                isOk = (errorCode == 0 || errorCode == 401)
                errorMessage = message
                if message.contains("Field") {
                    resultError = FileMakerError.response(message: "Field情報がない。layout:\(layout) query:\(query)")
                    return
                }
                if let res = response["data"] {
                    newResult = (res as? [Any])?.compactMap { FileMakerRecord(json:$0) } ?? []
                }
            }.resume()
            sem.wait()
            if let error = resultError { throw error }
            if isOk == false { throw FileMakerError.find(message: errorMessage) }
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
        if isOk == false { throw FileMakerError.delete(message: errorMessage) }
    }
    
    func update(layout: String, recordID: String , fields: FileMakerQuery) throws {
        let token = try self.prepareToken()
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records").appendingPathComponent(recordID)
        let encoder = JSONEncoder()
        var isOk = false
        var errorMessage = ""
        let json = ["fieldData" : fields]
        guard let data = try? encoder.encode(json) else { throw FileMakerError.update(message: "sortItem encoding") }
//        let rawData = String(data: data, encoding: .utf8)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
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
        if isOk == false { throw FileMakerError.update(message: errorMessage) }
    }
    
    @discardableResult func insert(layout: String, fields: FileMakerQuery) throws -> String {
        let token = try self.prepareToken()
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
        let encoder = JSONEncoder()
        var isOk = false
        var errorMessage = ""
        let json = ["fieldData": fields]
        guard let data = try? encoder.encode(json) else { throw FileMakerError.insert(message: "sortItem encoding") }
//        let rawData = String(data: data, encoding: .utf8)
        var result = ""
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        self.session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            guard   let data      = data, error == nil,
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let message = messages[0]["message"] as? String,
                let code      = messages[0]["code"] as? String else { return }
            isOk = (Int(code) == 0)
            errorMessage = message
            if let res = response["recordId"] as? String { result = res }
        }.resume()
        sem.wait()
        if isOk == false { throw FileMakerError.insert(message: errorMessage) }
        return result
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
        var isOk = false
        var errorMessage = ""
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
        if isOk == false { throw FileMakerError.execute(message: errorMessage) }
    }
}

#endif
