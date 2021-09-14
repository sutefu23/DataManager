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
    static var db: FileMakerDB { get }
    static var exportLayout: String { get }
    static var exportScript: String { get }
    static var uuidField: String { get }
    static var errorField: String { get }
    
    func makeExportRecord(exportUUID: UUID) -> FileMakerQuery
    /// 登録済みかどうかチェック対象リストを取得する
    func find重複候補() throws -> [ImportBuddyType]
    /// 登録済みと判定できた場合true
    func is内容重複(with data: ImportBuddyType) -> Bool
    /// 出力後のキャッシュのクリア
    func flushCache()
    static func countUploads(uuid: UUID, session: FileMakerSession) throws -> Int
}

extension FileMakerExportRecord {
    public static var db: FileMakerDB { FileMakerDB.pm_osakaname }
    public static var uuidField: String { "識別キー" }
    public static var errorField: String { "エラー" }

    public func find重複候補() throws -> [ImportBuddyType] { return [] }
    public func is内容重複(with data: ImportBuddyType) -> Bool { return false }
    public func flushCache() {}
    
    public static func countUploads(uuid: UUID, session: FileMakerSession) throws -> Int {
        let records = try session.find(layout: Self.exportLayout, query: [[Self.uuidField: uuid.uuidString]])
            .filter {
                guard let error = $0.string(forKey: Self.errorField) else { return false }
                return error.isEmpty
            }
        return records.count
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
    public static var db: FileMakerDB { FileMakerDB.pm_osakaname }

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

extension Collection where Element: FileMakerExportRecord {
    public func exportToDB(重複チェック: Bool = false) throws {
        let db = Element.db
        let session = db.retainExportSession()
        defer { db.releaseExportSession(session) }
        let targets = try self.filter { try !重複チェック || $0.test重複() }
        if targets.isEmpty { return }
        
        var loopCount = 1
        repeat {
            let uuid = UUID()
            let detail = "uuid: \(uuid.uuidString)"
            session.log("\(Element.exportLayout)へ\(targets.count)件\(Element.ImportBuddyType.title)出力開始[\(loopCount)]", detail: detail, level: .information)
            let startTime = Date()
            // アップロード
            for progress in targets {
                try session.insert(layout: Element.exportLayout, fields: progress.makeExportRecord(exportUUID: uuid))
                progress.flushCache()
            }
            let uploadTime = Date().timeIntervalSince(startTime)
            let waitTime = TimeInterval(loopCount) * 2
            Thread.sleep(forTimeInterval: waitTime + 1.0)
            // 更新
            session.log("\(Element.ImportBuddyType.title)出力スクリプト実行開始[\(loopCount)]", detail: detail, level: .information)
            try session.executeScript(layout: Element.exportLayout, script: Element.exportScript, param: uuid.uuidString, waitTime: (Swift.max(uploadTime, waitTime), TimeInterval(targets.count)))
            // チェック
            session.log("\(Element.ImportBuddyType.title)出力チェック開始[\(loopCount)]", detail: detail, level: .information)
            let count = try Element.countUploads(uuid: uuid, session: session)
            if count == targets.count {
                session.log("\(Element.ImportBuddyType.title)出力完了[\(loopCount)]", detail: detail, level: .information)
                return
            }
//            let checkQuery = Element.ImportBuddyType.makeExportCheckQuery(exportUUID: uuid)
//            var checked = try Element.ImportBuddyType.find(query: checkQuery)
//            if checked.count == targets.count {
//                session.log("\(Element.ImportBuddyType.title)出力完了[\(loopCount)]", detail: detail, level: .information)
//                return
//            }
//            targets = targets.filter { target in
//                if let index = checked.firstIndex(where: { target.isUploaded(data: $0) }) {
//                    checked.remove(at: index)
//                    return false
//                } else {
//                    return true
//                }
//            }
          loopCount += 1
        } while loopCount <= 2
        throw FileMakerError.upload(message: "\(Element.exportLayout)へ\(targets.count)件").log(.critical)
    }
}
