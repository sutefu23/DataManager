//
//  DMHttpConnection.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/10/01.
//

import Foundation

// MARK: - HTTP接続
protocol DMHttpConnectionProtocol: class {
    func call(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization?, contentType: DMHttpContentType?, body: Data?) throws -> Data?
}

enum DMHttpMethod: String {
    case GET
    case POST
    case DELETE
    case PATCH

    var string: String { self.rawValue }
}

enum DMHttpAuthorization {
    case Basic(user: String, password: String)
    case Bearer(token: String)

    var string: String {
        switch self {
        case .Basic(user: let user, password: let password):
            let code = "\(user):\(password)".data(using: .utf8)!.base64EncodedString()
            return "Basic \(code)"
        case .Bearer(token: let token):
            return "Bearer \(token)"
        }
    }
}

struct DMHttpContentType {
    static let JSON = DMHttpContentType(string: "application/json")
    
    var string: String
}

// MARK: - FileMaker専用処理
extension DMHttpConnection {
    func callFileMaker(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization? = nil, contentType: DMHttpContentType? = .JSON, data: Data? = nil) throws -> FileMakerResponse {
        guard let data = try self.call(url: url, method: method, authorization: authorization, contentType: contentType, body: data),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messages = json["messages"] as? [[String: Any]],
              let codeString = messages[0]["code"] as? String else { return FileMakerResponse(code: nil, message: "", response: [:]) }
        let response = (json["response"] as? [String: Any]) ?? [:]
        let message = (messages[0]["message"] as? String) ?? ""
        return FileMakerResponse(code: Int(codeString), message: message, response: response)
    }

    func callFileMaker(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization? = nil, contentType: DMHttpContentType? = .JSON, string: String) throws -> FileMakerResponse {
        let data = string.data(using: .utf8)!
        return try self.callFileMaker(url: url, method: method, authorization: authorization, contentType: contentType, data: data)
    }

    func callFileMaker<T: Encodable>(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization? = nil, contentType: DMHttpContentType? = .JSON, object: T) throws -> FileMakerResponse {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        return try self.callFileMaker(url: url, method: method, authorization: authorization, contentType: contentType, data: data)
    }
}

struct FileMakerResponse {
    let code: Int?
    let message: String
    let response: [String: Any]
    
    subscript(key: String) -> Any? { response[key] }
    var records: [FileMakerRecord]? {
        guard let dataArray = self["data"] as? [Any] else { return nil }
        return dataArray.compactMap { FileMakerRecord(json: $0) }
    }
}


// MARK: - Apple系OSへの対応
#if os(macOS) || os(iOS) || os(tvOS)
typealias DMHttpConnection = DMHttpAppleConnection
class DMHttpAppleConnection: NSObject, URLSessionDelegate, DMHttpConnectionProtocol {
    private lazy var session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    private let sem = DispatchSemaphore(value: 0)

    func call(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization?, contentType: DMHttpContentType?, body: Data?) throws -> Data? {
        var request = URLRequest(url: url)
        request.httpMethod = method.string
        if let authorization = authorization?.string {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
        if let contentType = contentType?.string {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        var result: (data: Data?, error: Error?) = (nil, nil)
        request.httpBody = body
        self.session.dataTask(with: request) { (data, _, error) in
            result = (data, error)
            self.sem.signal()
        }.resume()
        self.sem.wait()
        if let error = result.error { throw error }
        return result.data
    }
    
    // MARK: <URLSessionDelegate>
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credential: URLCredential?
        if let trust = challenge.protectionSpace.serverTrust {
            credential = URLCredential(trust:trust)
        } else {
            credential = nil
        }
        completionHandler(.useCredential, credential)
    }
}

// MARK: - Linux/Windowsへの対応
#elseif os(Linux) || os(Windows)
import AsyncHTTPClient
import NIO
import NIOSSL

typealias DMHttpConnection = DMHttpNIOConnection
class DMHttpNIOConnection: DMHttpConnectionProtocol {
    private lazy var session: HTTPClient = {
        var config = HTTPClient.Configuration()
        let tlsc = TLSConfiguration.forClient(certificateVerification: .none)
        config.tlsConfiguration = tlsc
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup), configuration: config)
        self.isActiveSession = true
        return client
    }()

    func call(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization?, contentType: DMHttpContentType?, body: Data?) throws -> Data? {
        var request = try HTTPClient.Request(url: url, method: method.nioMethod)
        if let authorization = authorization?.string {
            request.headers.add(name: "Authorization", value: authorization)
        }
        if let contentType = contentType?.string {
            request.headers.add(name: "Content-Type", value: contentType)
        }
        if let data = body {
            request.body = .data(data)
        }
        let future = self.session.execute(request: request)
        let response = try future.wait()
        switch response.status {
        case .ok:
            break
        default:
            return nil
        }
    }
}
extension DMHttpMethod {
    var nioMethod: HTTPMethod {
        switch self {
        case .GET: return .GET
        case .POST: return .POST
        case .DELETE: return .DELETE
        case .PATCH: return .PATCH
        }
    }
}
private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount) // CPUコア数にイベントループを制限する

#endif
