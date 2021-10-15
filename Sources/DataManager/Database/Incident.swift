//
//  インシデント.swift
//  DataManager
//
//  Created by manager on 2019/11/07.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

/// 指示書に対して発生したイベント。進捗入力と内容変更・資材の利用などを時系列で並べるのが目的
public final class インシデント型 {
    /// インシデントの種類
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
        
        /// 種類の文字表現
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

    /// インシデントの日時
    public var 日時: Date
    /// 内容
    public var 内容: String
    /// 種類
    public var 種類: 種類型
    /// 作業者
    public var 作業者: 社員型

    /// 進捗入力で初期化する
    init(_ progress: 進捗型) {
        switch progress.作業内容 {
        case .受取: self.種類 = .受取
        case .開始: self.種類 = .開始
        case .仕掛: self.種類 = .仕掛
        case .完了: self.種類 = .完了
        }
        self.日時 = progress.登録日時
        self.内容 = progress.工程.description
        self.作業者 = progress.作業者
    }
    
    /// 変更内容履歴で初期化する
    init(_ change: 指示書変更内容履歴型) {
        switch change.種類 {
        case .指示書承認: self.種類 = .指示書承認
        case .校正開始: self.種類 = .校正開始
        case .校正終了: self.種類 = .校正終了
        case .保留開始: self.種類 = .保留開始
        case .保留解除: self.種類 = .保留解除
        case .キャンセル: self.種類 = .キャンセル
        case .その他: self.種類 = .その他
        }
        self.日時 = change.日時
        self.内容 = change.内容
        self.作業者 = change.作業者
    }
}
