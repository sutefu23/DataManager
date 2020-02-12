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
    
    public var errorDescription: String? {
        switch self {
        case .dbIsDisabled: return "サーバー接続停止中"
        case .tokenCreate(message: _): return "データベースに接続できませんでした"
        case .fetch(message: _): return "データベースからの読み取りができなかった"
        case .find(message: _): return "データベースの検索ができなかった"
        case .delete(message: _): return "データベースから削除できなかった"
        case .update(message: _): return "データベースの更新ができなかった"
        case .insert(message: _): return "データベースへの登録ができなかった"
        case .execute(message: _): return "データベースのスクリプトが実行できなかった"
        case .download(message: _): return "データベースからのダウンロードができなかった"
        case .response(message: _): return "正常な情報処理がされていません"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .dbIsDisabled:
            return "サーバー利用停止フラグがonになっている"
        case .tokenCreate(message: let mes), .fetch(message: let mes), .find(message: let mes), .delete(message: let mes), .update(message: let mes), .insert(message: let mes), .execute(message: let mes), .download(message: let mes), .response(message: let mes):
            return "サーバーエラー: \(mes)"
        }
    }
}
