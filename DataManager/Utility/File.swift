//
//  File.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/05/05.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

/// DataManager汎用エラー
public enum DataManagerError: LocalizedError, Equatable {
    /// 内部ロジックエラー
    case internalError(reason: String)
    /// データが数値でない
    case needsNumberString
    /// データを指定したエンコードで文字列かできない
    case invalidStringCoding
    /// bundleから読み込みできない
    case invalidBundle
    /// 保存先の指定が不正
    case invalidWriteURL
    
    public var errorDescription: String? {
        switch self {
        case .internalError(let reason):return "内部ロジックエラー(\(reason))"
        case .needsNumberString:        return "データが数値でない"
        case .invalidStringCoding:      return "データを指定したエンコードで文字列化できない"
        case .invalidBundle:            return "bundleから読み込みできない"
        case .invalidWriteURL:          return "保存先の指定が不正"
        }
    }
}
