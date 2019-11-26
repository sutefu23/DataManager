//
//  FileMakerSession.swift
//  DataManager
//
//  Created by manager on 2019/02/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

struct FileMakerPortal {
    let name : String
    let limit : Int?
    
    init(name:String, limit:Int? = nil) {
        self.name = name
        self.limit = limit
    }
}
private let expireMin: Double = 14 // 基本は15分で余裕を見て60秒少なくしている

class FileMakerSession : NSObject, URLSessionDelegate {
    let dbURL : URL
    let user : String
    let password : String
    private let sem = DispatchSemaphore(value: 0)
    lazy var session : URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    
    init(url:URL, user:String, password:String) {
        self.dbURL = url
        self.user = user
        self.password = password
    }
    deinit {
        self.logout()
    }
    
    private var ticket : (token: String, expire: Date)?
    var activeToken : String? {
        guard let ticket = self.ticket else { return nil }
        let now = Date()
        if now < ticket.expire {
            return ticket.token
        }
        self.logout(with: ticket.token)
        return nil
    }
    
    var isConnect : Bool {
        return self.activeToken != nil
    }
    
    func prepareToken(reuse:Bool = true) -> String? {
        if reuse == true, let token = self.activeToken{ return token }
        
        var result : String? = nil
        let url = self.dbURL.appendingPathComponent("sessions")
        let auth = "\(user):\(password)".data(using: .utf8)!.base64EncodedString()
        var request = URLRequest(url: url)
        var errorCode : String? = nil
        let expire : Date = Date(timeIntervalSinceNow: expireMin * 60)
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            guard   let data      = data, error == nil,
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let code      = messages[0]["code"] as? String else { return }
            errorCode = code
            guard let token = response["token"] as? String else {
                print(messages)
                return
            }
            result = token
        }.resume()
        sem.wait()
        guard let token = result else { return nil }
        guard let code = errorCode, code == "0" else { return nil }
        self.ticket = (token:token, expire:expire)
        return self.activeToken
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
        let credential : URLCredential?
        if let trust = challenge.protectionSpace.serverTrust {
            credential = URLCredential(trust: trust)
        } else {
            credential = nil
        }
        completionHandler(.useCredential, credential)
    }
    
    func fetch(layout:String, sortItems:[(String, FileMakerSortType)] = [], portals:[FileMakerPortal] = []) -> [FileMakerRecord]? {
        let sortItems = sortItems.map { return FileMakerSortItem(fieldName: $0.0, sortOrder: $0.1) }
        guard let token = self.prepareToken() else { return nil }
        var result : [FileMakerRecord] = []
        
        var offset = 1
        let limit = 100
        var isRepeat = false
        
        repeat {
            var isOk = false
            var newRequest : [FileMakerRecord] = []
            newRequest.reserveCapacity(100)
            var url = dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
            var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            var queryItems : [URLQueryItem] = [
                URLQueryItem(name: "_offset", value: "\(offset)"),
                URLQueryItem(name: "_limit", value: "\(limit)")
            ]
            if sortItems.isEmpty == false {
                let encoder = JSONEncoder()
                guard let data = try? encoder.encode(sortItems) else { return nil }
                let str = String(data: data, encoding: .utf8)
                let item = URLQueryItem(name: "_sort", value: str)
                queryItems.append(item)
            }
            // portal
            var names : [String] = []
            for portal in portals where portal.limit != 0 {
                if let limit = portal.limit {
                    names.append(portal.name)
                    let name = "_limit.\(portal.name)"
                    let item = URLQueryItem(name: "_limit.\(portal.name)", value: "\(limit)")
                    queryItems.append(item)
                }
            }
            if names.isEmpty == false {
                let value = "[" + names.map { return "\"" + $0 + "\"" }.joined(separator: ",") + "]"
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
                    let code      = messages[0]["code"] as? String else { return }
                isOk = (Int(code) == 0)
                if let res = response["data"] {
                    newRequest = (res as? [Any])?.compactMap { FileMakerRecord(json:$0) } ?? []
                }
            }.resume()
            sem.wait()
            if isOk == false { return nil }
            let count = newRequest.count
            result.append(contentsOf: newRequest)
            offset += limit
            isRepeat = count >= limit
        } while (isRepeat)
        return result
    }
    
    
    struct SearchRequest : Encodable {
        let query : [[String:String]]
        let sort : [FileMakerSortItem]?
        let offset : Int
        let limit : Int
    }
    
    func find(layout:String, recordId:String) -> FileMakerRecord? {
        return self.find(layout: layout, query: [["recordId" : recordId]])?.first
    }
    
    func find(layout:String, query:[[String:String]], sortItems:[(String, FileMakerSortType)] = [], max:Int? = nil) -> [FileMakerRecord]? {
        guard let token = self.prepareToken() else { return nil }
        var offset = 1
        let limit = 100
        var result : [FileMakerRecord] = []
        
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("_find")
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let sort : [FileMakerSortItem]? = sortItems.isEmpty ? nil : sortItems.map { return FileMakerSortItem(fieldName: $0.0, sortOrder: $0.1) }
        let encoder = JSONEncoder()
        repeat {
            var isOk = false
            let json = SearchRequest(query: query, sort:sort , offset: offset, limit: limit)
            guard let data = try? encoder.encode(json) else { return nil }
            let rawData = String(data: data, encoding: .utf8)
            var newResult : [FileMakerRecord] = []
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            session.dataTask(with: request) { data, _, error in
                defer { self.sem.signal() }
                guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String,
                    let codeNum = Int(code) else { return }
                isOk = (codeNum == 0 || codeNum == 401)
                if let res = response["data"] {
                    newResult = (res as? [Any])?.compactMap { FileMakerRecord(json:$0) } ?? []
                }
            }.resume()
            sem.wait()
            if isOk == false { return nil }
            let count = newResult.count
            result.append(contentsOf: newResult)
            offset += limit
            if let max = max, result.count >= max { break }
            if count < limit { break }
        } while(true)
        return result
    }
    
    func delete(layout: String, recordId: String) -> Bool {
        guard let token = self.prepareToken() else { return false }
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records").appendingPathComponent(recordId)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        var isOk = false
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            guard   let data      = data, error == nil,
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                //                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let code      = messages[0]["code"] as? String,
                let codeNum = Int(code) else { return }
            isOk = (codeNum == 0 || codeNum == 401)
        }.resume()
        sem.wait()
        return isOk
    }
    
    
    func update(layout:String, recordId:String , fields:[String:String]) -> Bool {
        guard let token = self.prepareToken() else { return false }
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records").appendingPathComponent(recordId)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let encoder = JSONEncoder()
        var isOk = false
        let json = ["fieldData" : fields]
        guard let data = try? encoder.encode(json) else { return false }
        let rawData = String(data: data, encoding: .utf8)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            guard   let data      = data, error == nil,
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let code      = messages[0]["code"] as? String,
                let codeNum = Int(code) else { return }
            isOk = (codeNum == 0 || codeNum == 401)
        }.resume()
        sem.wait()
        return isOk
    }
    
    func insert(layout:String, fields:[String:String]) -> String? {
        guard let token = self.prepareToken() else { return nil }
        let url = self.dbURL.appendingPathComponent("layouts").appendingPathComponent(layout).appendingPathComponent("records")
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let encoder = JSONEncoder()
        var isOk = false
        let json = ["fieldData" : fields]
        guard let data = try? encoder.encode(json) else { return nil }
        let rawData = String(data: data, encoding: .utf8)
        var result : String? = nil
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            guard   let data      = data, error == nil,
                let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response  = json["response"] as? [String: Any],
                let messages  = json["messages"] as? [[String: Any]],
                let code      = messages[0]["code"] as? String,
                let codeNum = Int(code) else { return }
            isOk = (codeNum == 0 || codeNum == 401)
            if let res = response["recordId"] as? String {
                result = res
            }
        }.resume()
        sem.wait()
        return result
    }
    
    func download(_ url:URL) -> Data? {
        var result : Data? = nil
        self.session.downloadTask(with: url) { (data , res, error) in
            if error == nil {
                if let url = data {
                    result = try? Data(contentsOf: url)
                }
            }
            self.sem.signal()
        }.resume()
        self.sem.wait()
        return result
    }
}

//func makeQueryDayString(_ range:ClosedRange<Date>?) -> String? {
//    guard let range = range else { return nil }
//    let from = range.lowerBound
//    let to = range.upperBound
//    if from == to {
//        return "\(from.day.fmString)"
//    } else {
//        return "\(from.day.fmString)...\(to.day.fmString)"
//    }
//
//}

func makeQueryDayString(_ range:ClosedRange<Day>?) -> String? {
    guard let range = range else { return nil }
    let from = range.lowerBound
    let to = range.upperBound
    if from == to {
        return "\(from.fmString)"
    } else {
        return "\(from.fmString)...\(to.fmString)"
    }
    
}
