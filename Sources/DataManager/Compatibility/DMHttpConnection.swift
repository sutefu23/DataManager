//
//  DMHttpConnection.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/10/01.
//

import Foundation

#if os(Windows)
import FoundationNetworking
#endif

// MARK: - HTTP接続
/// HTTP接続インターフェース（Apple系とApple以外でHTTP接続の実態が異なるため用意）
protocol DMHttpConnectionProtocol: AnyObject {
    /// HTTP呼び出しを行う
    func call(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization?, contentType: DMHttpContentType?, body: Data?) throws -> Data?
    /// 接続を無効化する
    func invalidate()
}

/// HTTP接続方法
enum DMHttpMethod {
    case GET
    case POST
    case DELETE
    case PATCH
}

/// 認証方法
enum DMHttpAuthorization {
    /// BASIC認証
    case Basic(user: String, password: String)
    /// Bearer認証
    case Bearer(token: String)

    /// 文字列表現
    var string: String {
        switch self {
        case .Basic(user: let user, password: let password):
            let code = "\(user):\(password)".data(using: .ascii)!.base64EncodedString()
            return "Basic \(code)"
        case .Bearer(token: let token):
            return "Bearer \(token)"
        }
    }
}

/// ContentType
struct DMHttpContentType {
    /// JSON
    static let JSON = DMHttpContentType(string: "application/json")
    static let Text = DMHttpContentType(string: "text/plain")

    var string: String
}

// MARK: - Apple系OSへの対応
#if os(macOS) || os(iOS) || os(Windows) || os(tvOS)
extension DMHttpMethod {
    /// 文字列表現
    var string: String {
        switch self {
        case .GET: return "GET"
        case .POST: return "POST"
        case .DELETE: return "DELETE"
        case .PATCH: return "PATCH"
        }
    }
}

/// 共通名を設定する
typealias DMHttpConnection = DMHttpAppleConnection

/// Apple系のHTTP接続オブジェクト
class DMHttpAppleConnection: NSObject, URLSessionDelegate, DMHttpConnectionProtocol {
    /// 接続の本体はURLSessionだが、継承できないので内部に隠し持つことにする
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
//        config.httpMaximumConnectionsPerHost = 1
        config.networkServiceType = .responsiveData
        let settion = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return settion
    }()
    
    /// 非同期コールを同期化する為に使用
    private let sem = DispatchSemaphore(value: 0)

    /// 無効化ずみならtrue
    private var isInvalidated: Bool = false
    
    func invalidate() {
        guard isInvalidated == false else { return }
        // 無効済みとする
        isInvalidated = true
        // セッションを無効化する
        session.finishTasksAndInvalidate()
    }
    
    func call(url: URL, method: DMHttpMethod, authorization: DMHttpAuthorization?, contentType: DMHttpContentType?, body: Data?) throws -> Data? {
        // HTTPリクエスト作成
        var request = URLRequest(url: url)
        request.httpMethod = method.string
        if let authorization = authorization?.string {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
        if let contentType = contentType?.string {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = body
        
        var result: Result<Data, Error>? = nil
        // データを同期で読み出す
        self.session.dataTask(with: request) { (data, response, error) in
            if let error = error { // エラーが設定されている場合、エラーを返す
                if let response = response {
                    DMLogSystem.shared.log("request error", detail: "\(response.description)", level: .critical)
                }
                result = .failure(error)
            } else if let data = data { // データが設定されている場合、データを返す
                result = .success(data)
            }
            self.sem.signal()
        }.resume()
        self.sem.wait()
        return try result?.get()
    }
    
    // MARK: <URLSessionDelegate>
    /// 認証処理
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credential: URLCredential?
        if let trust = challenge.protectionSpace.serverTrust {
            credential = URLCredential(trust: trust)
        } else {
            credential = nil
        }
        completionHandler(.useCredential, credential)
    }
}

// MARK: - Linux/Windowsへの対応
#elseif os(Linux)
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
            request.headers.add(name: "Authorization", value: authorization)
        }
        if let contentType = contentType?.string {
            request.headers.add(name: "Content-Type", value: contentType)
        }
        if let rawValue = body {
            request.body = .data(rawValue)
        }
        let future = self.session.execute(request: request)
        let response = try future.wait()
        guard let body = response.body else { return nil }
        return Data(buffer: body)
    }
    
    /// 無効化ずみならtrue
    private var isInvalidated: Bool = false
    
    func invalidate() {
        // 無効済みとする
        isInvalidated = true
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
