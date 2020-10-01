//
//  FileMakerSession.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/10/01.
//

import Foundation

// MARK: -
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

enum DMHttpMethod {
    case GET
    case POST
    case DELETE
    case PATCH
}

protocol DMHttpConnectionProtocol: class {
    func connect(url: URL, method: DMHttpMethod, authorization: String?, contentType: String?, content: Data?) throws -> Data?
}

#if os(macOS) || os(iOS) || os(tvOS)
extension DMHttpMethod {
    var method: String {
        switch self {
        case .GET: return "GET"
        case .POST: return "POST"
        case .DELETE: return "DELETE"
        case .PATCH: return "PATCH"
        }
    }
}

class DMHttpAppleConnection: NSObject, URLSessionDelegate, DMHttpConnectionProtocol {
    private lazy var session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    private let sem = DispatchSemaphore(value: 0)

    func connect(url: URL, method: DMHttpMethod, authorization: String?, contentType: String?, content: Data?) throws -> Data? {
        var request = URLRequest(url: url)
        request.httpMethod = method.method
        if let authorization = authorization {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        var result: (data: Data?, error: Error?) = (nil, nil)
        request.httpBody = content
        self.session.dataTask(with: request) { (data, _, error) in
            result = (data, error)
            self.sem.signal()
        }
        self.sem.wait()
        if let error = result.error { throw error }
        return result.data
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
}
typealias DMHttpConnection = DMHttpAppleConnection

#elseif os(Linux)
import AsyncHTTPClient
import NIO
import NIOSSL

extension DMHttpMethod {
    var method: HTTPMethod {
        switch self {
        case .GET: return .GET
        case .POST: return .POST
        case .DELETE: return .DELETE
        case .PATCH: return .PATCH

        }
    }
}

private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount) // CPUコア数にイベントループを制限する

class DMHttpLinuxConnection: DMHttpConnectionProtocol {
    private lazy var session: HTTPClient = {
        var config = HTTPClient.Configuration()
        let tlsc = TLSConfiguration.forClient(certificateVerification: .none)
        config.tlsConfiguration = tlsc
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup), configuration: config)
        self.isActiveSession = true
        return client
    }()

    func connect(url: URL, method: DMHttpMethod, authorization: String?, contentType: String?, content: Data?) throws -> Data? {
        var request = try HTTPClient.Request(url: url, method: method.method)
        if let authorization = authorization {
            request.headers.add(name: "Authorization", value: authorization)
        }
        if let contentType = contentType {
            request.headers.add(name: "Content-Type", value: contentType)
        }
        if let data = data {
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
typealias DMHttpConnection = DMHttpLinuxConnection
#endif
