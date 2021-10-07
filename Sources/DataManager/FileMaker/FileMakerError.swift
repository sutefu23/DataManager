//
//  FileMakerError.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/12/08.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

extension Error {
    var canRetry: Bool {
        guard case let error as FilemakerErrorProtocol = self else { return false }
        return error.canRetry
    }
    
    var resetToken: Bool {
        guard case let error as FilemakerErrorProtocol = self else { return false }
        return error.resetToken
    }
    
    var retryCount: Int? {
        get {
            guard case let error as FileMakerDetailedError = self else { return nil }
            return error.retryCount
        }
        set {
            guard case let error as FileMakerDetailedError = self else { return }
            error.retryCount = newValue ?? 1
        }
    }
}

protocol FilemakerErrorProtocol: LocalizedError {
    var canRetry: Bool { get }
    var resetToken: Bool { get }
}

enum FileMakerErrorWork {
    case fetch
    case delete(recordID: FileMakerRecordID)
    case find(query: [FileMakerQuery])
    case insert(fields: FileMakerQuery)
    case exec(script: String, param: String)
    case update(recordID: FileMakerRecordID, fields: FileMakerQuery)

    var title: String {
        switch self {
        case .fetch: return "取得"
        case .delete: return "削除"
        case .find: return "検索"
        case .insert: return "追加"
        case .exec: return "実行"
        case .update: return "更新"
        }
    }
    
    var query: [FileMakerQuery]? {
        switch self {
        case .find(query: let query):
            return query
        case .insert(fields: let fields), .update(recordID: _, fields: let fields):
            return [fields]
        case .delete, .exec, .fetch:
            return nil
        }
    }
    
    var recordID: FileMakerRecordID? {
        switch self {
        case .delete(recordID: let recordID), .update(recordID: let recordID, fields: _):
            return recordID
        case .fetch, .find, .insert, .exec:
            return nil
        }
    }
    
    var script: String? {
        switch self {
        case .exec(script: let script, param: _):
            return script
        case .fetch, .delete, .find, .insert, .update:
            return nil
        }
    }
    
    var param: String? {
        switch self {
        case .exec(script: _, param: let param):
            return param
        case .fetch, .delete, .find, .insert, .update:
            return nil
        }
    }
}

class FileMakerDetailedError: FilemakerErrorProtocol {
    var retryCount: Int = 1
    let table: String
    var response: FileMakerResponse? = nil
    let work: FileMakerErrorWork

    init(table: String, work: FileMakerErrorWork, response: FileMakerResponse? = nil) {
        self.table = table
        self.work = work
        self.response = response
    }
    
    var errorDescription: String? {
        var message: String = "\(table): \(work.title)失敗"
        if let response = self.response {
            message += "(code\(response.code):\(response.message))"
        }
        if retryCount > 1 {
            message += "\(retryCount)回目"
        }
        return message
    }
    
    var failureReason: String? {
        var mes = ""
        if let response = response {
            mes += " \(response.message)"
        }
        if let recordID = work.recordID {
            mes += " recordID:\(recordID)"
        }
        if let query = work.query, !query.isEmpty {
            if let text = query.makeText() {
                mes += " query:\(text)"
            } else {
                mes += " query:\(query.makeKeys())"
            }
        }
        if let script = work.script, !script.isEmpty {
            mes += " script:\(script)"
        }
        if let param = work.param, !param.isEmpty {
            mes += " param: \(param)"
        }
        return mes
    }

    var canRetry: Bool {
        switch work {
        case .find, .fetch, .update, .delete:
            return true
        case .exec, .insert:
            return false
        }
    }
    
    var resetToken: Bool {
        if response?.code == 102 { return canRetry }
        return false
    }
}

private func makeCodeMes(_ code: Int?, _ mes: String) -> String {
    guard let code = code else { return mes }
    return "エラー\(code): \(mes)"
}

public enum FileMakerError: FilemakerErrorProtocol {
    case dbIsDisabled
    case noConnection
    case noRecordId
    case tokenCreate(message: String, code: Int?)
    case fetch(message: String)
    case find(message: String, code: Int?)
    case delete(message: String)
    case update(message: String)
    case insert(message: String, code: Int?)
    case execute(message: String, code: Int?)
    case download(message: String)
    case response(message: String)
    case upload(message: String)
    case upload進捗入力(message: String)
    case upload発注(message: String)
    case upload資材入出庫(message: String)
    case upload使用資材(message: String)

    case invalidData(message: String)
    case notFound(message: String)
    case internalError(message: String)
    case invalidRecord(name: String, recordId: FileMakerRecordID?, mes: String)
    
    init(invalidData keys: String..., record: FileMakerRecord) {
        let list: [String] = keys.map { "\($0): \(record.string(forKey: $0) ?? "")" }
        let mes = list.joined(separator: " ")
        self = .invalidData(message: mes)
    }
    
    var code: Int? {
        switch self {
        case
                .find(message: _, code: let code),
                .tokenCreate(message: _, code: let code),
                .insert(message: _, code: let code),
                .execute(message: _, code: let code):
            return code
        default:
            return nil
        }
    }
    
    var message: String {
        switch self {
        case .dbIsDisabled, .noRecordId: return ""
        case .noConnection: return "サーバーに接続できません"
        case
                .find(message: let mes, code: let code),
                .tokenCreate(message: let mes, code: let code),
                .insert(message: let mes, code: let code),
                .execute(message: let mes, code: let code):
            return makeCodeMes(code, mes)
        case
                .delete(message: let mes),
                .update(message: let mes),
                .download(message: let mes),
                .response(message: let mes),
                .upload(message: let mes),
                .upload進捗入力(message: let mes),
                .upload発注(message: let mes),
                .upload使用資材(message: let mes),
                .upload資材入出庫(message: let mes),
                .invalidData(message: let mes),
                .fetch(message: let mes),
                .notFound(message: let mes),
                .internalError(message: let mes):
            return mes
        case .invalidRecord(name: _, recordId: _, mes: let mes):
            return mes
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .dbIsDisabled: return "サーバー接続停止中"
        case .noConnection: return "サーバーに接続できません"
        case .noRecordId: return "recordIdが存在しない"
        case .tokenCreate: return "データベースに接続できませんでした(\(self.message))"
        case .fetch(message: let mes): return "データベースからの読み取りができなかった(\(mes))"
        case .find: return "データベースの検索ができなかった(\(self.message))"
        case .delete(message: let mes): return "データベースから削除できなかった(\(mes))"
        case .update(message: let mes): return "データベースの更新ができなかった(\(mes))"
        case .insert: return "データベースへの登録ができなかった(\(self.message))"
        case .execute: return "データベースのスクリプトが実行できなかった(\(self.message))"
        case .download(message: let mes): return "データベースからのダウンロードができなかった(\(mes))"
        case .response(message: let mes): return "正常な情報処理がされていません(\(mes))"
        case .upload(message: let mes): return "レコード登録失敗(\(mes))"
        case .upload進捗入力(message: let mes): return "進捗入力登録失敗(\(mes))"
        case .upload発注(message: let mes): return "発注登録失敗(\(mes))"
        case .upload資材入出庫(message: let mes): return "資材入出庫登録失敗(\(mes))"
        case .upload使用資材(message: let mes): return "使用資材登録失敗(\(mes))"
        case .invalidData(message: let mes): return "読み込みフィールド形式不正(\(mes))"
        case .notFound(message: let mes): return "必要なレコードが見つからなかった(\(mes))"
        case .internalError(message: let mes): return "内部ロジックエラー[\(mes)]"
        case .invalidRecord(name: let name, recordId: let recordId, mes: let mes):
            return "\(name): 初期化失敗[recordId=\(recordId?.description ?? "?")] 不明な\(mes)"
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .tokenCreate, .find, .fetch, .delete:
            return true
        default:
            break
        }
        let mes = self.message
        return mes.contains("Invalid FileMaker Data API token")
    }
    /// tokenのリセットが必要?
    var resetToken: Bool {
        return self.code == 102
    }
}
