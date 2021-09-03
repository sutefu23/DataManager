//
//  ErrorLog.swift
//  ErrorLog
//
//  Created by manager on 2021/09/02.
//

import Foundation

public enum DMLogLevel: Int, Comparable {    
    public static let all: DMLogLevel = .information
    /// 情報
    case information = 0
    /// 続行可能なエラー
    case warning = 10
    /// 致命的で続行不能
    case critical = 20
    
    public static func < (lhs: DMLogLevel, rhs: DMLogLevel) -> Bool { return lhs.rawValue < rhs.rawValue }
}

public struct DMLogRecord: DMRecordData {
    public let date: Date = Date()
    public let level: DMLogLevel
    let data: DMRecordData
    
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

struct DMTextRecord: DMRecordData {
    var title: String
    var detail: String
}

struct DMSessionRecord: DMRecordData {
    let data: DMRecordData
    let sessionID: FileMakerSession.ID
    
    init(_ session: FileMakerSession, data: DMRecordData) {
        self.sessionID = session.id
        self.data = data
    }
    
    var title: String { return data.title }
    var detail: String {
        let detail = data.detail
        if detail.isEmpty {
            return "セッション\(sessionID)"
        } else {
            return "セッション\(sessionID) \(detail)"
        }
    }
}

