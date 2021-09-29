//
//  FileMakerObject.swift
//  DataManager
//
//  Created by 四熊泰之 on R 3/09/25.
//

import Foundation

/// レコードの内容をオブジェクト化したものの共通インターフェース
/// recordIdは内容ではなく管理タグのため、共通インターフェースとしては含めない
public protocol FileMakerObject: DMCacheElement, DMLogger {
    /// テーブルのあるデータベースファイル
    static var db: FileMakerDB { get }
    /// 使用するレイアウト
    static var layout: String { get }
    /// オブジェクトの名前
    static var name: String { get }

    /// 指定された検索条件で検索し、生データを返す
    static func basic_find(query: FileMakerQuery, session: FileMakerSession) throws -> [FileMakerRecord]
    /// 指定された検索OR条件で検索し、生データを返す
    static func basic_find(querys: [FileMakerQuery], session: FileMakerSession) throws -> [FileMakerRecord]
}

extension FileMakerObject {
    public static var name: String { classNameBody(of: self) } // クラス名から動的に名称を作成する
    
    /// ログシステムにレコードを記録する
    public func registLogData<T: DMRecordData>(_ data: T, _ level: DMLogLevel) {
        let data = DMFileMakerObjectRecord(db: Self.db, layout: Self.layout, data: data)
        DMLogSystem.shared.registLogData(data, level)
    }

    public static func basic_find(query: FileMakerQuery, session: FileMakerSession) throws -> [FileMakerRecord] {
        return try self.basic_find(querys: [query], session: session)
    }

    public static func basic_find(querys: [FileMakerQuery], session: FileMakerSession) throws -> [FileMakerRecord] {
        if querys.isEmpty || querys.allSatisfy({ $0.isEmpty }) { // 条件指定が全くない
            return try session.fetch(layout: Self.layout) // 全データ読み込み
        } else {
            return try session.find(layout: Self.layout, query: querys) // 指定条件で検索
        }
    }
}
