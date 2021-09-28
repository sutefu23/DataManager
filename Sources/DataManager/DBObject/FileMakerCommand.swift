//
//  FileMakerCommand.swift
//  DataManager
//
//  Created by 四熊泰之 on R 3/09/27.
//

import Foundation

/// DBコマンド
/// （リトライシステムでの使用が前提。DBに繋がらない状態でもDecode/Encodeできる必要がある）
public enum FileMakerCommand: Codable {
    case insert(db: FileMakerDB, layout: String, fields: [FileMakerFields])
    case export(db: FileMakerDB, layout: String, prepare: (layout: String, field: String)?, fields: [FileMakerFields], uuidField: String, script: String, checkField: String)
    
    // MARK: <Codable>
    enum CodingKeys: String, CodingKey {
        case type
        case db
        case layout
        case script
        case fields
        case prepareLayout
        case prepareField
        case uuidField
        case checkField
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(FileMakerCommandType.self, forKey: .type)
        switch type {
        case .insert:
            guard let db = try FileMakerDB.db(ofName: values.decode(String.self, forKey: .db)) else { throw FileMakerCommandError.dbが見つからない }
            let layout = try values.decode(String.self, forKey: .layout)
            let fields = try values.decode([FileMakerFields].self, forKey: .fields)
            self = .insert(db: db, layout: layout, fields: fields)
        case .export:
            guard let db = try FileMakerDB.db(ofName: values.decode(String.self, forKey: .db)) else { throw FileMakerCommandError.dbが見つからない }
            let layout = try values.decode(String.self, forKey: .layout)
            let prepare: (layout: String, field: String)?
            if let prepareLayout = try values.decodeIfPresent(String.self, forKey: .prepareLayout),
               let prepareField = try values.decodeIfPresent(String.self, forKey: .prepareField) {
                prepare = (prepareLayout, prepareField)
            } else {
                prepare = nil
            }
            let fields = try values.decode([FileMakerFields].self, forKey: .fields)
            let uuidField = try values.decode(String.self, forKey: .uuidField)
            let script = try values.decode(String.self, forKey: .script)
            let checkField = try values.decode(String.self, forKey: .checkField)
            self = .export(db: db, layout: layout, prepare: prepare, fields: fields, uuidField: uuidField, script: script, checkField: checkField)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .insert(db: let db, layout: let layout, fields: let fields):
            try container.encode(FileMakerCommandType.insert, forKey: .type)
            try container.encode(db.filename, forKey: .db)
            try container.encode(layout, forKey: .layout)
            try container.encode(fields, forKey: .fields)
        case .export(db: let db, layout: let layout, prepare: let prepare, fields: let fields, uuidField: let uuidField, script: let script, checkField: let checkField):
            try container.encode(FileMakerCommandType.export, forKey: .type)
            try container.encode(db.filename, forKey: .db)
            try container.encode(layout, forKey: .layout)
            if let prepare = prepare {
                try container.encode(prepare.layout, forKey: .prepareLayout)
                try container.encode(prepare.field, forKey: .prepareField)
            }
            try container.encode(fields, forKey: .fields)
            try container.encode(uuidField, forKey: .uuidField)
            try container.encode(script, forKey: .script)
            try container.encode(checkField, forKey: .checkField)
        }
    }
    /// エラー
    enum FileMakerCommandError: String, LocalizedError {
        case dbが見つからない
        
        var errorDescription: String? { return self.rawValue }
    }

    /// コマンドの種類
    enum FileMakerCommandType: Codable {
        case insert
        case export
    }

    // MARK: -
    var db: FileMakerDB {
        switch self {
        case .export(db: let db, layout: _, prepare: _, fields: _, uuidField: _, script: _, checkField: _),
                .insert(db: let db, layout: _, fields: _):
            return db
        }
        
    }
    
    /// 出力を実行する
    func execute() throws -> Bool {
        switch self {
        case .insert:
            fatalError() // 未実装
        case .export(db: let db, layout: let layout, prepare: let prepare, fields: let fields, uuidField: let uuidField, script: let script, checkField: let checkField):
            return try execExport(db: db, layout: layout, prepare: prepare, fields: fields, uuidField: uuidField, script: script, checkField: checkField)
        }
    }
}

/// export実行
private func execExport(db: FileMakerDB, layout: String, prepare: (layout: String, field: String)?, fields: [FileMakerFields], uuidField: String, script: String, checkField: String) throws -> Bool {
    let session = db.retainExportSession()
    defer { db.releaseExportSession(session) }
    
    let uuid = UUID()
    let uuidString = uuid.uuidString
    let detailString = "uuid: \(uuidString)"
    session.log("出力開始[\(layout)]", detail: detailString, level: .information)

    if let prepare = prepare {
        let _ = try? session.find(layout: prepare.layout, query: [[prepare.field: uuidString]])
    }
    
    let startTime = Date()

    // アップロード
    for data in fields {
        var data = data
        data[uuidField] = uuidString
        try session.insert(layout: layout, fields: data)
    }
    let uploadTime = Date().timeIntervalSince(startTime)
    let waitTime = 0.5
    let extendTime = 0.5
    #if DEBUG
    session.log("出力中[\(layout)]", detail: "アップロード完了[\(uploadTime)秒]", level: .information)
    #endif
    Thread.sleep(forTimeInterval: waitTime + extendTime)
    // 更新
    try session.executeScript(layout: layout, script: script, param: uuidString, waitTime: (Swift.max(uploadTime, waitTime), extendTime))
    // チェック
    let records = try session.find(layout: layout, query: [[uuidField: uuidString]])
    var count = 0
    for record in records {
        if let error = record.string(forKey: checkField), error.isEmpty {
            count += 1
        }
    }
    if count == fields.count {
        session.log("出力成功[\(layout)]", detail: detailString, level: .information)
        return true
    } else {
        session.log("出力失敗[\(layout)]", detail: detailString, level: .critical)
        return false
    }
}
