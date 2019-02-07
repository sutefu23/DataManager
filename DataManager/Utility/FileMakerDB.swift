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

final class FileMakerDB : NSObject, URLSessionDelegate {
    static let pm_osakaname : FileMakerDB = FileMakerDB(server: "192.168.1.153", filename: "pm_osakaname", user: "admin", password: "ojwvndfM")
    static let laser : FileMakerDB = FileMakerDB(server: "192.168.1.153", filename: "laser", user: "admin", password: "ws")

    private let sem = DispatchSemaphore(value: 0)
    let dbURL : URL
    let user : String
    let password : String
    
    init(server:String, filename:String, user:String, password:String) {
        let serverURL = "https://\(server)/fmi/data/v1/databases/\(filename)/"
        self.dbURL = URL(string: serverURL)!
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
        return now < ticket.expire ? ticket.token : nil
    }
    
    var isConnect : Bool {
        return self.activeToken != nil
    }
    
    func prepareToken() -> String? {
        if let token = self.activeToken{ return token }
        
        var result : String? = nil
        let url = self.dbURL.appendingPathComponent("sessions")
        let auth = "\(user):\(password)".data(using: .utf8)!.base64EncodedString()
        var request = URLRequest(url: url)
        var errorCode : String? = nil
        let expire : Date = Date(timeIntervalSinceNow: 15*90-30) // 基本は15分で余裕を見て30秒少なくしている
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session.dataTask(with: request) { data, _, error in
            defer { self.sem.signal() }
            guard   let data      = data, error == nil,
                let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
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
    
    @discardableResult func logout() -> Bool {
        guard let token = self.activeToken else { return false }
        let url = self.dbURL.appendingPathComponent("sessions").appendingPathComponent(token)
        var errorCode : String? = nil
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session.dataTask(with: request) { _, _, error in
            defer { self.sem.signal() }
            }.resume()
        sem.wait()
        self.ticket = nil
        return true
    }

    func fetch(layout:String, sortItems:[(String, FileMakerSortType)] = []) -> [FileMakerRecord]? {
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
            comp.queryItems = queryItems
            url = comp.url!
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            session.dataTask(with: request) { data, _, error in
                defer { self.sem.signal() }
                guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
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
    
    func find(layout:String, recordId:Int) -> FileMakerRecord? {
        return self.find(layout: layout, query: [["recordId" : "\(recordId)"]])?.first
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
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
                isOk = (Int(code) == 0)
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
    
    // MARK: - <URLSessionDelegate>
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credential : URLCredential?
        if let trust = challenge.protectionSpace.serverTrust {
            credential = URLCredential(trust: trust)
        } else {
            credential = nil
        }
        completionHandler(.useCredential, credential)
    }

}

