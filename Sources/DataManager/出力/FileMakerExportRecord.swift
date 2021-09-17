//
//  FileMakerExportRecord.swift
//  FileMakerExportRecord
//
//  Created by 四熊泰之 on R 3/09/13.
//

import Foundation

/// 出力レコード
public protocol FileMakerExportRecord {
    /// 出力結果を参照できる入力レコード
    associatedtype ImportBuddyType: FileMakerImportRecord
    /// 出力先のDBファイル
    static var db: FileMakerDB { get }
    /// 出力先のレイアウト名
    static var exportLayout: String { get }
    /// 出力用スクリプト名
    static var exportScript: String { get }
    /// 出力先のUUIDフィールド名
    static var uuidField: String { get }
    /// 出力先のエラーフイールド名
    static var errorField: String { get }
    
    /// 登録済みかどうかチェック対象リストを取得する
    func find重複候補() throws -> [ImportBuddyType]
    /// 登録済みと判定できた場合true
    func is内容重複(with data: ImportBuddyType) -> Bool
    /// 出力準備する
    static func prepareUploads(uuid: UUID, session: FileMakerSession) throws
    /// 出力データ作成
    func makeExportRecord(exportUUID: UUID) -> FileMakerQuery
    /// 出力後のキャッシュのクリア
    func flushCache()
}

extension FileMakerExportRecord {
    public static var db: FileMakerDB { FileMakerDB.pm_osakaname }
    public static var uuidField: String { "識別キー" }
    public static var errorField: String { "エラー" }

    public func find重複候補() throws -> [ImportBuddyType] { return [] }
    public func is内容重複(with data: ImportBuddyType) -> Bool { return false }
    public func flushCache() {}

    public static func prepareUploads(uuid: UUID, session: FileMakerSession) throws {}

    public static func countUploads(uuid: UUID, session: FileMakerSession) throws -> Int {
        let records = try session.find(layout: Self.exportLayout, query: [[Self.uuidField: uuid.uuidString]])
        var count = 0
        for record in records {
            if let error = record.string(forKey: Self.errorField), error.isEmpty {
                count += 1
            }
        }
        return count
    }
    
    /// 登録済みかチェックする
    func test重複() throws -> Bool {
        let records = try self.find重複候補()
        return records.contains { self.is内容重複(with: $0) }
    }
}

/// 入力レコード
public protocol FileMakerImportRecord {
    static var db: FileMakerDB { get }
    static var importLayout: String { get }
    static var title: String { get }

    /// 指定された検索条件で検索する
    static func find(query: FileMakerQuery) throws -> [Self]
    ///
    static func find(querys: [FileMakerQuery]) throws -> [Self]

    init(_ record: FileMakerRecord) throws
}

extension FileMakerImportRecord {
    public static var db: FileMakerDB { .pm_osakaname }

    public static func find(query: FileMakerQuery) throws -> [Self] {
        return try self.find(querys: [query])
    }

    public static func find(querys: [FileMakerQuery]) throws -> [Self] {
        let list = try db.find(layout: Self.importLayout, query: querys)
        return try list.map { try Self($0) }
    }
    
    public static func find(recordId: String) throws -> Self? {
        guard let record = try Self.db.find(layout: Self.importLayout, recordId: recordId) else { return nil }
        return try Self(record)
    }
}

extension Array where Element: FileMakerExportRecord {
    public func exportToDB(重複チェック: Bool = false) throws {
        let db = Element.db
        let session = db.retainExportSession()
        defer { db.releaseExportSession(session) }
        session.log("\(Element.exportLayout)へ\(Element.ImportBuddyType.title)重複チェック開始[\(self.count)]件")
        /// 重複を除去した登録予定のレコード
        let targets: [Element]
        if 重複チェック {
            targets = try self.filter { try !$0.test重複() }
        } else {
            targets = self
        }
        if targets.isEmpty {
            session.log("\(Element.exportLayout)へ\(Element.ImportBuddyType.title)重複チェックで完了")
            return
        }
        
        /// ループの回数
        var loopCount = 1
        repeat {
            let uuid = UUID()
            let detail = "uuid: \(uuid.uuidString)"
            try Element.prepareUploads(uuid: uuid, session: session)
            session.log("\(Element.exportLayout)へ\(targets.count)件\(Element.ImportBuddyType.title)出力開始[\(loopCount)]", detail: detail, level: .information)
            let startTime = Date()
            // アップロード
            for progress in targets {
                try session.insert(layout: Element.exportLayout, fields: progress.makeExportRecord(exportUUID: uuid))
                progress.flushCache()
            }
            let uploadTime = Date().timeIntervalSince(startTime)
            let waitTime, extendTime: TimeInterval
            waitTime = 1.0
            extendTime = 1.0
//            waitTime = TimeInterval(loopCount) * 2
//            extendTime = TimeInterval(loopCount)
            Thread.sleep(forTimeInterval: waitTime + 1.0)
            // 更新
            session.log("\(Element.ImportBuddyType.title)出力スクリプト実行開始[\(loopCount)]", detail: detail, level: .information)
            try session.executeScript(layout: Element.exportLayout, script: Element.exportScript, param: uuid.uuidString, waitTime: (Swift.max(uploadTime, waitTime), extendTime))
            // チェック
            session.log("\(Element.ImportBuddyType.title)出力チェック開始[\(loopCount)]", detail: detail, level: .information)
            let count = try Element.countUploads(uuid: uuid, session: session)
            if count == targets.count {
                session.log("\(Element.ImportBuddyType.title)出力完了[\(loopCount)]", detail: detail, level: .information)
                return
            }
          loopCount += 1
        } while loopCount <= 2
        throw FileMakerError.upload(message: "\(Element.exportLayout)へ\(targets.count)件").log(.critical)
    }
}
