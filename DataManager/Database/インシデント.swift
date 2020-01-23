//
//  インシデント.swift
//  DataManager
//
//  Created by manager on 2019/11/07.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class インシデント型 {
    public enum 種類型 {
        case 受取
        case 開始
        case 仕掛
        case 完了
        case 指示書承認
        case 校正開始
        case 校正終了
        case 保留開始
        case 保留解除
        case キャンセル
        case その他
        
        public init(_ type: 作業内容型) {
            switch type {
            case .受取: self = .受取
            case .開始: self = .開始
            case .仕掛: self = .仕掛
            case .完了: self = .完了
            }
        }
        
        public init(_ type: 変更履歴種類型) {
            switch type {
            case .指示書承認: self = .指示書承認
            case .校正開始: self = .校正開始
            case .校正終了: self = .校正終了
            case .保留開始: self = .保留開始
            case .保留解除: self = .保留解除
            case .キャンセル: self = .キャンセル
            case .その他: self = .その他
            }
        }
        
        public var description : String {
            switch self {
            case .受取: return "受取"
            case .開始: return "開始"
            case .仕掛: return "仕掛"
            case .完了: return "完了"
            case .指示書承認: return "指示書承認"
            case .校正開始: return "校正開始"
            case .校正終了: return "校正終了"
            case .保留開始: return "保留開始"
            case .保留解除: return "保留解除"
            case .キャンセル: return "キャンセル"
            case .その他: return "内容変更"
            }
        }
    }

    public var 日時: Date
    public var 内容: String
    public var 種類: 種類型
    public var 社員名称: String

    init(_ progress: 進捗型) {
        self.日時 = progress.登録日時
        self.内容 = progress.工程.description
        self.種類 = 種類型(progress.作業内容)
        self.社員名称 = progress.作業者.社員名称
    }
    
    init(_ change: 指示書変更内容履歴型) {
        self.日時 = change.日時
        self.内容 = change.内容
        self.種類 = 種類型(change.種類)
        self.社員名称 = change.社員名称
    }
}
