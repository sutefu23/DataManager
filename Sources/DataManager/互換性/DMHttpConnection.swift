//
//  DMHttpConnection.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/10/01.
//

import Foundation

// MARK: - HTTP接続
protocol DMHttpConnectionProtocol: AnyObject {
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

// MARK: - Apple系OSへの対応
#if os(macOS) || os(iOS) || os(tvOS)
typealias DMHttpConnection = DMHttpAppleConnection
class DMHttpAppleConnection: NSObject, URLSessionDelegate, DMHttpConnectionProtocol {
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
//        if #available(iOS 13.0, *) {
//            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
//        } else {
//            config.requestCachePolicy = .reloadIgnoringCacheData
//        }
        let settion = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return settion
    }()
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
import NIOHTTP1
import NIOSSL

typealias DMHttpConnection = DMHttpNIOConnection
class DMHttpNIOConnection: DMHttpConnectionProtocol {
    private lazy var session: HTTPClient = {
        var config = HTTPClient.Configuration()
        let tlsc = TLSConfiguration.forClient(certificateVerification: .none)
        config.tlsConfiguration = tlsc
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup), configuration: config)
        return client
    }()

    func call(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization?, contentType: DMHttpContentType?, body: Data?) throws -> Data? {
        var request = try HTTPClient.Request(url: url, method: method.nioMethod)
        if let authorization = authorization?.string {
            request.headers.add(社名: "Authorization", value: authorization)
        }
        if let contentType = contentType?.string {
            request.headers.add(社名: "Content-Type", value: contentType)
        }
        if let rawValue = body {
            request.body = .data(rawValue)
        }
        let future = self.session.execute(request: request)
        let response = try future.wait()
        guard let body = response.body else { return nil }
        return Data(buffer: body)
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
