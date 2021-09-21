//
//  ErrorLog.swift
//  ErrorLog
//
//  Created by manager on 2021/09/02.
//

import Foundation
import AVFoundation

public enum DumpType: String {
    /// エラーダンプ
    case error = "エラー"
    /// 現時点までの動作状況
    case current = "動作履歴"
    /// アプリの動作記録
    case app = "終了時"
}

public enum DMLogLevel: Int, Comparable {    
    public static let all: DMLogLevel = .debug
    /// デバッグ
    case debug = 0
    /// 情報
    case information = 1
    /// 続行可能なエラー
    case warning = 2
    /// 致命的で続行不能
    case critical = 3
    
    public static func < (lhs: DMLogLevel, rhs: DMLogLevel) -> Bool { return lhs.rawValue < rhs.rawValue }
}

public struct DMLogRecord: DMRecordData {
    public let date: Date = Date()
    let data: DMRecordData
    public let level: DMLogLevel

    public var title: String { data.title }
    public var detail: String { data.detail }
}

public protocol DMRecordData {
    var title: String { get }
    var detail: String { get }
}

struct DMErrorRecord: DMRecordData {
    let error: Error
    
    var title: String {
        if case let error as LocalizedError = error, let title = error.errorDescription {
            return title
        }
        return self.error.localizedDescription
    }
    var detail: String {
        if case let error as LocalizedError = error, let detail = error.failureReason {
            return detail
        }
        return ""
    }
}

public struct DMTextRecord: DMRecordData {
    public let title: String
    public let detail: String

    public init(title: String, detail: String?) {
        self.title = title
        self.detail = detail ?? ""
    }
}

open class DMHeaderRecordData<T: DMRecordData>: DMRecordData {
    let data: T
    
    public init(_ data: T) {
        self.data = data
    }
    
    open var titleHeader: String { "" }
    open var detailHeader: String { "" }
    
    /// ヘッダと本文を合成する
    private func makeString(header: String, body: String) -> String {
        if header.isEmpty { return body }
        if body.isEmpty { return header }
        return "\(header): \(body)"
    }
    
    public var title: String { return makeString(header: titleHeader, body: data.title) }
    
    public var detail: String { return makeString(header: detailHeader, body: data.detail) }
}

final class DMFileMakerDBRecord<T: DMRecordData>: DMHeaderRecordData<T> {
    let filename: String

    init(_ db: FileMakerDB, data: T) {
        self.filename = db.filename
        super.init(data)
    }
    
    override var titleHeader: String { "db=\(filename)" }
}

final class DMFileMakerSessionRecord<T: DMRecordData>: DMHeaderRecordData<T> {
    let sessionID: FileMakerSession.ID

    init(_ session: FileMakerSession, data: T) {
        self.sessionID = session.id
        super.init(data)
    }
    
    override var detailHeader: String { "セッション\(sessionID)" }
}

final class DMFileMakerServerRecord<T: DMRecordData>: DMHeaderRecordData<T> {
    let name: String

    init(_ server: FileMakerServer, data: T) {
        self.name = server.name
        super.init(data)
    }
    
    override var detailHeader: String { "db=\(name)" }
}
