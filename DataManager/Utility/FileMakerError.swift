//
//  FileMakerError.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/12/08.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

public enum FileMakerError: LocalizedError {
    case dbIsDisabled
    case tokenCreate(message: String)
    case fetch(message: String)
    case find(message: String)
    case delete(message: String)
    case update(message: String)
    case insert(message: String)
    case execute(message: String)
    case download(message: String)
    case response(message: String)
    case upload進捗入力(message: String)
    case upload発注(message: String)
    case upload資材入出庫(message: String)

    case invalidData(message: String)
    case notFound(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .dbIsDisabled: return "サーバー接続停止中"
        case .tokenCreate(message: let mes): return "データベースに接続できませんでした(\(mes))"
        case .fetch(message: let mes): return "データベースからの読み取りができなかった(\(mes))"
        case .find(message: let mes): return "データベースの検索ができなかった(\(mes))"
        case .delete(message: let mes): return "データベースから削除できなかった(\(mes))"
        case .update(message: let mes): return "データベースの更新ができなかった(\(mes))"
        case .insert(message: let mes): return "データベースへの登録ができなかった(\(mes))"
        case .execute(message: let mes): return "データベースのスクリプトが実行できなかった(\(mes))"
        case .download(message: let mes): return "データベースからのダウンロードができなかった(\(mes))"
        case .response(message: let mes): return "正常な情報処理がされていません(\(mes))"
        case .upload進捗入力(message: let mes): return "進捗入力登録失敗(\(mes))"
        case .upload発注(message: let mes): return "発注登録失敗(\(mes))"
        case .upload資材入出庫(message: let mes): return "資材入出庫登録失敗(\(mes))"
        case .invalidData(message: let mes): return "読み込みフィールド形式不正(\(mes))"
        case .notFound(message: let mes): return "必要なレコードが見つからなかった(\(mes))"
        }
    }
}
