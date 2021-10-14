//
//  LogSystem.swift
//  LogSystem
//
//  Created by manager on 2021/09/02.
//

import Foundation

// MARK: - ログシステムインターフェース
/// ログシステムのインターフェース。デフォルト実装完備
public protocol DMLogger {
    /// ログシステムにレコードを記録する
    func registLogData<T: DMRecordData>(_ data: T, _ level: DMLogLevel)
    /// 指定されたレベルか、それ以上のレベルのログが存在する場合trueを返す
    func hasLogRecord(level: DMLogLevel) -> Bool
    /// 指定されたレベル以上のログを取り出す
    func currentLog(minLevel: DMLogLevel) -> [DMLogRecord]
    
    /// 指定された場所に、指定されたレベル以上のログを出力する
    func dumplog(type: DumpType, minLevel: DMLogLevel, shareButton: DMButton?) throws
    /// エラー時の自動ダンプ
    func errorDump()
    
    var currentLogSystem: DMLogger { get set }
}

public extension DMLogger {
    var currentLogSystem: DMLogger {
        get { return DataManager.currentLogSystem }
        set { DataManager.currentLogSystem = newValue }
    }

    var defaultLogSystem: DMLogger {
        return DataManager.localLogSystem
    }

    // MARK: 基本実装（ログの管理場所を変えたい場合や挙動を変えたい場合、この4メソッドを独自実装する）
    /// ログシステムにレコードを記録する
    func registLogData<T: DMRecordData>(_ data: T, _ level: DMLogLevel) {
        currentLogSystem.registLogData(data, level)
    }

    /// 指定されたレベルか、それ以上のレベルのログが存在する場合trueを返す
    func currentLog(minLevel: DMLogLevel) -> [DMLogRecord] {
        return currentLogSystem.currentLog(minLevel: minLevel)
    }

    /// 指定されたレベル以上のログを取り出す
    func hasLogRecord(level: DMLogLevel) -> Bool {
        return currentLogSystem.hasLogRecord(level: level)
    }

    /// エラー時の自動ダンプ
    func errorDump() {
        // デフォルトではデスクトップ環境時のみ自動ダンプ
        #if os(macOS) || os(Linux) || os(Windows) || targetEnvironment(macCatalyst)
        try? dumplog(type: .error, minLevel: .all, shareButton: nil)
        #endif
    }
    // MARK: 派生実装
    /// テキストログを記録する
    func log(_ text: String, detail: String? = nil, level: DMLogLevel = .information) {
        let data = DMTextRecord(title: text, detail: detail)
        self.registLogData(data, level)
    }
    /// エラーログを記録する
    func log(_ error: Error, _ level: DMLogLevel) {
        let data = DMErrorRecord(error: error)
        self.registLogData(data, level)
    }

    /// デバッグモード時にデバッグログを記録する
    func debugLog(_ text: String, detail: String? = nil, level: DMLogLevel = .debug) {
        #if DEBUG
        self.log(text, detail: detail, level: level)
        #endif
    }
    
    // MARK: デフォルト引数
    /// 何らかのログがあればtrueを返す
    var hasLogRecord: Bool {
        self.hasLogRecord(level: .all)
    }

    func dumplog(type: DumpType, minLevel: DMLogLevel = .all) throws {
        try dumplog(type: type, minLevel: minLevel, shareButton: nil)
    }
    
    /// 全ログを返す
    func currentLog() -> [DMLogRecord] { return currentLog(minLevel: .all) }
}

extension Error {
    /// エラーに対するログレベルを計算する
    private func calcLogLevel() -> DMLogLevel {
        return self.canRetry ? .error : .critical
    }
    
    /// セッションエラーログを登録する
    func log(_ session: FileMakerSession, _ level: DMLogLevel? = nil) -> Error {
        let data = DMFileMakerSessionRecord(session, data: DMErrorRecord(error: self))
        currentLogSystem.registLogData(data, level ?? calcLogLevel())
        return self
    }

    /// エラーログを登録する
    public func log(_ level: DMLogLevel? = nil) -> Error {
        currentLogSystem.log(self, level ?? calcLogLevel())
        return self
    }
}

// MARK: - 実装
/// 標準実装のログシステム
private let localLogSystem = DMLogSystem()
/// デフォルトのログシステム
private var defaultLogSystem: DMLogger? = nil
/// 選択中のログシステム
var currentLogSystem: DMLogger {
    get { return defaultLogSystem ?? localLogSystem }
    set { defaultLogSystem = newValue }
}

/// 標準実装のログシステム
public final class DMLogSystem: DMLogger {
    public static var shared: DMLogger { DataManager.currentLogSystem }
    
    /// ログシステム
    private let lock = NSRecursiveLock()
    /// ログデータ本体
    private var records: [DMLogRecord] = []

    /// 最大記録数
    private let maxLogCount: Int

    /// ログシステムを初期化する
    init() {
        #if os(macOS) || os(Linux) || os(Windows) || targetEnvironment(macCatalyst)
        self.maxLogCount = 20000 // デスクトップ環境では多めにする
        #else
        self.maxLogCount = 1000 // モバイル環境では最小限に抑える
        #endif
    }
    /// ログを登録する
    public func registLogData<T: DMRecordData>(_ data: T, _ level: DMLogLevel) {
        let log = DMLogRecord(data: data, level: level)
        lock.lock(); defer { lock.unlock() }
        if self.records.count ==  maxLogCount {
            self.records.removeFirst()
        }
        assert(self.records.count < maxLogCount)
        self.records.append(log)
    }
    /// 指定されたレベル以上のログを取り出す
    public func currentLog(minLevel: DMLogLevel) -> [DMLogRecord] {
        lock.lock(); defer { lock.unlock() }
        return self.records.filter { $0.level >= minLevel }
    }
    /// 指定されたレベル以上のログがあればtrueを返す
    public func hasLogRecord(level: DMLogLevel) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return records.contains { $0.level >= level }
    }
}

// MARK: - テキスト出力
extension DMLogger {
    /// 指定された場所に、指定されたレベル以上のログを出力する
    public func dumplog(type: DumpType, minLevel: DMLogLevel, shareButton: DMButton?) throws {
        #if os(tvOS) // tvOSでは何もしない
        #else
        let gen = TableGenerator<DMLogRecord>()
            .string("種類") {
                switch $0.level {
                case .critical: return "致命的"
                case .error: return "エラー"
                case .information: return "記録"
                case .debug: return "デバッグ"
                }
            }
            .day("日付", .monthDay) { $0.date.day }
            .time("時間", .hourMinuteSecond) { $0.date.time }
            .string("概要") { $0.title }
            .string("詳細") { $0.detail }
        let hostname = ProcessInfo.processInfo.hostName.replacingOccurrences(of: ".local", with: "")
        let log = self.currentLog(minLevel: minLevel)
        try gen.share(log, format: .excel(header: true), base: type.dir, title: "\(defaults.programName)[\(type.rawValue)](\(hostname)).csv", shareButton: shareButton)
        #endif
    }
}
