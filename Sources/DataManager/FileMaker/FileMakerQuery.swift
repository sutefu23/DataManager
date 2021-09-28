//
//  FileMakerQuery.swift
//  DataManager
//
//  Created by manager on 2021/09/27.
//

import Foundation

// MARK: - クエリ
public typealias FileMakerQuery = [String: String]

/// ポータル取得情報
struct FileMakerPortal {
    let name: String
    let limit: Int?
}

/// 日付の範囲をクエリ文字列に変換する
func makeQueryDayString(_ range: ClosedRange<Day>) -> String {
    let from = range.lowerBound
    let to = range.upperBound
    if from == to {
        return "\(from.fmString)"
    } else {
        return "\(from.fmString)...\(to.fmString)"
    }
}

// MARK: - レスポンス
/// DataAPIのレスポンス
struct FileMakerResponse {
    /// レスポンスコード
    let code: Int
    /// レスポンスメッセージ
    let message: String
    /// レスポンスデータ
    let response: [String: Any]

    subscript(key: String) -> Any? { response[key] }
    
    var data: [FileMakerRecord]? {
        get throws {
            guard let data = self["data"] else { return nil }
            guard case let dataArray as [[String: Any]] = data else { throw FileMakerError.invalidData(message: "dataのJSON形式が不正") }
            return try dataArray.map { try FileMakerRecord(json: $0) }
        }
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

// MARK: - サーバーアクセス
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
            if let str = String(data: data, encoding: .utf8) { // UTF-8になる？
                DMLogSystem.shared.log("JSONデータ破損", detail: "\(url.path): \(str.prefix(100))", level: .critical)
            } else {
                DMLogSystem.shared.log("UTF8変換失敗", detail: "\(url.path): \(data.count)bytes", level: .critical)
            }
            #if os(macOS) || targetEnvironment(macCatalyst)
            if let url = try? 動作履歴URL.appendingPathComponent("HTTP-Error-Response.data") {
                try? data.write(to: url)
            }
            #endif
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

// MARK: - デバッグ用
/// FileMaker検索条件
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

