//
//  LogSystem.swift
//  LogSystem
//
//  Created by manager on 2021/09/02.
//

import Foundation

/// ログシステム（簡易アクセス）
let logSystem = DMLogSystem.shared

/// ログシステム
public class DMLogSystem {
    /// ログシステム
    public static let shared: DMLogSystem = DMLogSystem()

    private let lock = NSRecursiveLock()
    /// ログデータ本体
    private var log: [DMLogRecord] = []
    /// エラーダイアログ時に自動でログダンプしたい時はtrueをする
    public var autoDumpLevel: DMLogLevel? = nil
    
    /// ログを登録する
    public func registRecord(_ data: DMRecordData, _ level: DMLogLevel) {
        let log = DMLogRecord(level: level, data: data)
        lock.lock(); defer { lock.unlock() }
        self.log.append(log)
    }
    /// エラーをログとして登録する
    public func registError(_ error: Error, _ level: DMLogLevel) {
        let data = DMErrorRecord(error: error)
        registRecord(data, level)
    }
    /// テキストをログとして登録する
    public func registText(title: String, detail: String = "", level: DMLogLevel) {
        let data = DMTextRecord(title: title, detail: detail)
        registRecord(data, level)
    }
    /// 指定されたレベル以上のログを取り出す
    public func currentLog(minLevel: DMLogLevel = .all) -> [DMLogRecord] {
        lock.lock(); defer { lock.unlock() }
        return self.log.filter { $0.level >= minLevel }
    }
    /// 指定されたレベル以上のログがあればtrueを返す
    public func hasRecord(level: DMLogLevel) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return log.contains { $0.level >= level }
    }
}

public protocol Loggable {
    func log(_ text: String, level: DMLogLevel)
}
public extension Loggable {
    func log(_ text: String) {
        log(text, level: .information)
    }
    func debugLog(_ text: String, level: DMLogLevel = .information) {
#if DEBUG
        self.log(text, level: level)
#endif
    }
}

extension Error {
    func log(_ session: FileMakerSession, _ level: DMLogLevel) -> Error {
        let data = DMSessionRecord(session, data: DMErrorRecord(error: self))
        DMLogSystem.shared.registRecord(data, level)
        return self
    }

    func log(_ session: FileMakerSession) -> Error {
        return self.log(session, self.canRetry ? .warning : .critical)
    }

    public func log(_ level: DMLogLevel) -> Error {
        DMLogSystem.shared.registError(self, level)
        return self
    }
    
    public func log() -> Error {
        self.log(self.canRetry ? .warning : .critical)
    }
}

extension DMLogSystem {
    public func errorDump() {
        guard let level = self.autoDumpLevel else { return }
        try? dumplog(minLevel: level)
    }
    
    public func dumplog(base: DirType = .desktop, minLevel: DMLogLevel = .warning) throws {
        let gen = TableGenerator<DMLogRecord>()
            .string("種類") {
                switch $0.level {
                case .critical: return "致命的"
                case .warning: return "エラー"
                case .information: return "情報"
                }
            }
            .day("日付", .monthDay) { $0.date.day }
            .time("時間", .hourMinuteSecond) { $0.date.time }
            .string("概要") { $0.title }
            .string("詳細") { $0.detail }
        let hostname = ProcessInfo.processInfo.hostName
        let log = self.currentLog(minLevel: minLevel)
        try gen.share(log, format: .excel(header: true), base: base, title: "\(defaults.programName)動作履歴(\(hostname)).csv")
    }
}
