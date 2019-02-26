//
//  作業.swift
//  DataManager
//
//  Created by 四熊泰之 on 2019/02/26.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

enum 日時型 {
    case 確定(Date)
    case 推定(Date)
    
    var date : Date {
        switch self {
        case .推定(let date): return date
        case .確定(let date): return date
        }
    }
    
    var is確定 : Bool {
        switch self {
        case .推定(_): return false
        case .確定(_): return true
        }
    }
}

class 作業型 {
    let 工程 : 工程型
    private(set) var 関連進捗 : [進捗型]
    private(set) var 開始日時 : 日時型?
    private(set) var 完了日時 : 日時型?
    private(set) var 次作業 : [作業型]
    
    init(_ progress:進捗型) {
        self.工程 = progress.工程
        self.開始日時 = nil
        self.完了日時 = nil
        switch progress.作業内容 {
        case .受取:
            self.開始日時 = .推定(progress.登録日時)
        case .開始:
            self.開始日時 = .確定(progress.登録日時)
        case .仕掛:
            break
        case .完了:
            self.完了日時 = .確定(progress.登録日時)
        }
        self.次作業 = []
        self.関連進捗 = [progress]
    }
}

class 作業リスト作成状態型 {
    let 指示書 : 指示書型
    var 作業リスト : [作業型]
    
    init(_ order: 指示書型) {
        self.指示書 = order
        self.作業リスト = []
    }
}

extension 指示書型 {
    func make作業ツリー() -> [作業型] {
        let status = 作業リスト作成状態型(self)
        for progress in self.進捗一覧 {
            if status.merge(progress) {
                continue
            }
            status.update(progress)
            let newWork = 作業型(progress)
            status.append(newWork)
        }
        return status.作業リスト
    }
}

extension 作業リスト作成状態型 {
    /// 既存の作業に融合できるなら融合する
    func merge(_ progress:進捗型) -> Bool {
        if let work = self.merge候補(for: progress) {
            if work.merge(progress) == true {
                return true
            }
        }
        return false
    }
    
    /// 可能なら既存の作業に推定完了を追加する
    func update(_ progress:進捗型) {
        
    }
    
    /// 新規作業の追加
    func append(_ newWork:作業型) {
        
    }
}

extension 作業リスト作成状態型 {
    func merge候補(for progress:進捗型) -> 作業型? {
        for work in self.作業リスト {
            if work.工程 == progress.工程 {
                return work
            }
            if progress.工程.is前工程(to: work.工程) {
                return nil
            }
        }
        return nil
    }
}

extension 工程型 {
    static let 前工程map : [工程型 : Set<工程型>] = [
        工程型.営業 : [],
        工程型.管理 : [.営業],
        工程型.設計 : [.営業, .管理],
        工程型.原稿 : [.営業, .管理, .校正],
        工程型.校正 : [.営業, .管理, .原稿],
        工程型.入力 : [.営業, .管理, .原稿],
        工程型.出力 : [.営業, .管理, .原稿],
        工程型.付属品準備 : [.営業, .管理, .原稿],
        工程型.ルーター : [.営業, .管理, .原稿],
        工程型.タップ : [.営業, .管理, .原稿],
        工程型.フォーミング : [.営業, .管理, .原稿],
        工程型.腐蝕 : [.営業, .管理, .原稿],
        工程型.印刷 : [.営業, .管理, .原稿],
        工程型.シャーリング : [.営業, .管理, .原稿, .フォーミング],
        工程型.タレパン : [.営業, .管理, .原稿, .フォーミング],
        工程型.プレーナー : [.営業, .管理, .原稿, .フォーミング],
        工程型.レーザー : [.営業, .管理, .原稿, .入力],
        工程型.レーザー（アクリル） : [.営業, .管理, .原稿, .入力],
        工程型.照合検査 : [.営業, .管理, .原稿, .入力, .レーザー],
        工程型.オブジェ : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.切文字 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.加工 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.切文字 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.立ち上がり : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.半田 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査, .立ち上がり],
        工程型.裏加工 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査, .半田],
        工程型.溶接 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.レーザー溶接 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.表面仕上 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.塗装 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.表面仕上 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査],
        工程型.拭き取り : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査, .塗装, .表面仕上],
        工程型.組立検品 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査, .塗装, .表面仕上, .拭き取り],
        工程型.発送 : [.営業, .管理, .原稿, .入力, .レーザー, .照合検査, .塗装, .表面仕上, .拭き取り, .組立検品],
        ]
    func is前工程(to state:工程型) -> Bool {
        if let map = 工程型.前工程map[state] {
            return map.contains(self)
        }
        switch state {
        case .経理, .外注:
            return true
        default:
            fatalError()
        }
    }
}

extension 作業型 {
    func merge(_ progress:進捗型) -> Bool {
        if self.工程 != progress.工程 { return false }
        switch progress.作業内容 {
        case .受取:
            
            return true
        case .開始:
            self.開始日時 = .確定(progress.登録日時)
            return true
        case .仕掛:
            if let date = self.完了日時 {
                if date.is確定 {
                    return false
                }
            }
            self.完了日時 = .推定(progress.登録日時)
            return true
        case .完了:
            if self.完了日時?.is確定 != true {
                self.完了日時 = .確定(progress.登録日時)
            }
            return true
        }
    }
}
