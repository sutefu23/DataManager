//
//  作業.swift
//  DataManager
//
//  Created by 四熊泰之 on 2019/02/26.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

enum 開始日時型 {
    case 確定(日時:Date)
    case 推定(日時:Date)
}

enum 完了日時型 {
    case 確定(日時:Date)
    case 推定(日時:Date)
}

class 作業型 {
    let 工程 : 工程型
    private(set) var 関連進捗 : [進捗型]
    private(set) var 開始日時 : 開始日時型?
    private(set) var 完了日時 : 完了日時型?
    private(set) var 次作業 : [作業型]
    
    init(_ progress:進捗型) {
        self.工程 = progress.工程
        self.開始日時 = nil
        self.完了日時 = nil
        switch progress.作業内容 {
        case .受取:
            self.開始日時 = .推定(日時: progress.登録日時)
        case .開始:
            self.開始日時 = .確定(日時: progress.登録日時)
        case .仕掛:
            break
        case .完了:
            self.完了日時 = .確定(日時: progress.登録日時)
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

func make作業ツリー(_ order: 指示書型) -> [作業型] {
    let status = 作業リスト作成状態型(order)
    for progress in order.進捗一覧 {
        if status.merge(progress) {
            continue
        }
        status.update(progress)
        let newWork = 作業型(progress)
        status.append(newWork)
    }
    return status.作業リスト
}


extension 作業リスト作成状態型 {
    /// 既存の作業に融合できるなら融合する
    func merge(_ progress:進捗型) -> Bool {
        return false
    }
    
    /// 可能なら既存の作業に推定完了を追加する
    func update(_ progress:進捗型) {
        
    }
    
    /// 新規作業の追加
    func append(_ newWork:作業型) {
        
    }
}

