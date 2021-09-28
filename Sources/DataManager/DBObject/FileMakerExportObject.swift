//
//  FileMakerExportRecord.swift
//  FileMakerExportRecord
//
//  Created by 四熊泰之 on R 3/09/13.
//

import Foundation

/// 出力レコード
public protocol FileMakerExportObject {
    /// 出力結果を参照できる入力レコード
    associatedtype ImportBuddyType: FileMakerImportObject
    /// 出力先のDBファイル
    static var db: FileMakerDB { get }
    /// 出力先のレイアウト名
    static var layout: String { get }
    /// 出力用スクリプト名
    static var exportScript: String { get }
    /// 出力先のUUIDフィールド名
    static var uuidField: String { get }
    /// 出力先のエラーフイールド名
    static var errorField: String { get }

    /// 出力準備のパラメータ。準備不要な場合nilを返す
    static var prepareParameters: (layout: String, field: String)? { get }
    
    /// 登録済みかどうかチェック対象リストを取得する
    func find重複候補() throws -> [ImportBuddyType]
    /// 登録済みと判定できた場合true
    func is内容重複(with data: ImportBuddyType) -> Bool
//    /// 出力準備する
//    static func prepareUploads(uuid: UUID, session: FileMakerSession) throws
    /// 出力データ作成
    func makeExportRecord(exportUUID: UUID?) -> FileMakerQuery
    /// 出力後のキャッシュのクリア
    func flushCache()
}

extension FileMakerExportObject {
    public static var db: FileMakerDB { FileMakerDB.pm_osakaname }
    public static var uuidField: String { "識別キー" }
    public static var errorField: String { "エラー" }
    public static var prepareParameters: (layout: String, field: String)? { return nil }

    public func find重複候補() throws -> [ImportBuddyType] { return [] }
    public func is内容重複(with data: ImportBuddyType) -> Bool { return false }
    public func flushCache() {}
    
    public static func prepareUploads(uuid: UUID, session: FileMakerSession) throws {
        guard let prepare = prepareParameters else { return }
        var query = FileMakerQuery()
        query[prepare.field] = "==\(uuid.uuidString)"
        _ = try session.find(layout: prepare.layout, query: [query])
    }

    public static func countUploads(uuid: UUID, session: FileMakerSession) throws -> Int {
        let records = try session.find(layout: Self.layout, query: [[Self.uuidField: uuid.uuidString]])
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


extension Array where Element: FileMakerExportObject {
    public func exportToDB(重複チェック: Bool = false, saveRetryIfError: Bool = false) throws {
        let db = Element.db
        let session = db.retainExportSession()
        defer { db.releaseExportSession(session) }
        session.log("\(Element.layout)へ\(Element.ImportBuddyType.name)重複チェック開始[\(self.count)]件")
        /// 重複を除去した登録予定のレコード
        let targets: [Element]
        if 重複チェック {
            targets = try self.filter { try !$0.test重複() }
        } else {
            targets = self
        }
        if targets.isEmpty {
            session.log("\(Element.layout)へ\(Element.ImportBuddyType.name)重複チェックで完了")
            return
        }
        /// リトライの最大回数
        let maxRetryCount = 1
        /// 現在のリトライの回数
        var retryCount = 0
        repeat {
            let command = makeCommand()
            if try command.execute() {
                return
            }
//            let uuid = UUID()
//            let detail = "uuid: \(uuid.uuidString)"
//            try Element.prepareUploads(uuid: uuid, session: session)
//            session.log("\(Element.layout)へ\(targets.count)件\(Element.ImportBuddyType.name)出力開始\(retryText)", detail: detail, level: .information)
//            let startTime = Date()
//            // アップロード
//            for progress in targets {
//                try session.insert(layout: Element.layout, fields: progress.makeExportRecord(exportUUID: uuid))
//                progress.flushCache()
//            }
//            let uploadTime = Date().timeIntervalSince(startTime)
//            let waitTime = 1.0
//            let extendTime = 1.0
//            Thread.sleep(forTimeInterval: waitTime + extendTime)
//            // 更新
//            session.log("\(Element.ImportBuddyType.name)出力スクリプト実行開始\(retryText)", detail: detail, level: .information)
//            try session.executeScript(layout: Element.layout, script: Element.exportScript, param: uuid.uuidString, waitTime: (Swift.max(uploadTime * 1.5, waitTime), extendTime))
//            // チェック
//            session.log("\(Element.ImportBuddyType.name)出力チェック開始\(retryText)", detail: detail, level: .information)
//            let count = try Element.countUploads(uuid: uuid, session: session)
//            if count == targets.count {
//                session.log("\(Element.ImportBuddyType.name)出力完了\(retryText)", detail: detail, level: .information)
//                return
//            }
            retryCount += 1
        } while retryCount <= maxRetryCount
        if saveRetryIfError {
            let command = makeCommand()
            FileMakerRetrySystem.shared.append(command)
        }
        throw FileMakerError.upload(message: "\(Element.layout)へ\(targets.count)件").log(.critical)
    }
    
    
    private func makeCommand() -> FileMakerCommand{
        let db = Element.db
        let layout = Element.layout
        let prepare = Element.prepareParameters
        let fields = self.map { $0.makeExportRecord(exportUUID: nil) }
        let uuidField = Element.uuidField
        let script = Element.exportScript
        let check = Element.errorField
        return .export(db: db, layout: layout, prepare: prepare, fields: fields, uuidField: uuidField, script: script, checkField: check)
    }

}
