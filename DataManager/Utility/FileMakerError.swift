//
//  FileMakerError.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/12/08.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

public enum FileMakerError: LocalizedError {
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
        case .tokenCreate(message: let message): return "トークン生成失敗(\(message))"
        case .response(message: let message): return "サーバーエラー: \(message)"
        default:
            return ""
        }
    }
}
