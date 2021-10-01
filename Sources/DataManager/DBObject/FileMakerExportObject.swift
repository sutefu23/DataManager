//
//  FileMakerExportRecord.swift
//  FileMakerExportRecord
//
//  Created by 四熊泰之 on R 3/09/13.
//

import Foundation

/// 出力レコード
public protocol FileMakerExportObject: FileMakerObject {
    /// DBに登録済みならtrueを返す。nilは未チェック
    func is登録済み() throws -> Bool?
    
    /// 出力データ作成
    func makeExportRecord() -> FileMakerFields
    /// 出力コマンドを作成する
    static func makeExportCommand(fields: [FileMakerFields]) -> FileMakerCommand

    /// 出力後のキャッシュのクリア
    func flushCache()
}

extension FileMakerExportObject {
    public static var db: FileMakerDB { FileMakerDB.pm_osakaname }
    
    public func is登録済み() throws -> Bool? { return nil }
    public func flushCache() {}
}

extension Array where Element: FileMakerExportObject {
    public func exportToDB(登録済み除外: Bool = false, saveRetryIfError: Bool = false) throws {
        if self.isEmpty { return } // 作業対象がなければ何もしない
        
        let db = Element.db
        let session = db.retainExportSession()
        defer { db.releaseExportSession(session) }
        /// 重複を除去した登録予定のレコード
        let targets: [Element]
        if 登録済み除外 {
            session.log("\(Element.layout)登録済みチェック開始[\(self.count)]件")
            var 登録済み件数 = 0
            targets = try self.filter {
                if try $0.is登録済み() == true {
                    登録済み件数 += 1
                    return false // 登録済みなら作業対象外
                } else {
                    return true // 未登録なら作業対象
                }
            }
            if 登録済み件数 == 0 {
                session.log("\(Element.layout)登録済みなし")
            } else {
                session.log("\(Element.layout)登録済み[\(登録済み件数)]件 残り: \(targets.count)件")
                if targets.isEmpty { return } // 全て重複ならやることがなくなる
            }
        } else {
            targets = self
        }
        let fields = targets.map { $0.makeExportRecord() }
        let command = Element.makeExportCommand(fields: fields)
        for retryCount in 0...1 {
            defer { self.forEach { $0.flushCache() } }
            if retryCount > 0 { session.log("リトライ\(retryCount)回目", level: .error) }
            if try command.execute() {
                return
            }
        }
        if saveRetryIfError {
            FileMakerRetrySystem.shared.append(command)
        }
        throw FileMakerError.upload(message: "\(Element.layout)へ\(targets.count)件").log(.critical)
    }
}
