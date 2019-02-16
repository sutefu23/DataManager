//
//  工程図.swift
//  DataManager
//
//  Created by manager on 2019/02/12.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 工程図エラー : Error {
    case 伝票種類が箱文字・切文字・エッチング・加工でない
    case 開始時間の推定ができない
    case 説明できない作業の上書きが発生した
    case 説明できない作業内容の戻りが発生した
}

public class 工程図型 {
    public let 作業バー : [作業バー型]
    public init(_ order: 指示書型) throws {
        switch order.伝票種類 {
        case .箱文字, .切文字, .エッチング, .加工:
            break
        default:
            throw 工程図エラー.伝票種類が箱文字・切文字・エッチング・加工でない
        }
        
        let state = try MakingState(order)
        self.作業バー = state.make作業バー()
    }
}

class MakingState {
    init(_ order:指示書型) throws {
        self.order = order
        self.prevProgress = []
        self.nextProgress = order.進捗一覧

        try processData()
    }
    
    private func processData() throws {
        while let first = nextProgress.first {
            nextProgress.remove(at: 0)
            try self.append(first)
            prevProgress.append(first)
        }
        for progress in progressMap.values {
            try progress.validateGarbage(self)
        }
    }
    private let order : 指示書型
    
    private(set) var progressMap : [工程型 : ProgressState] = [:]
    private(set) var workMap : [工程型 : 作業バー型] = [:]
    private(set) var prevProgress : [進捗型]
    private(set) var nextProgress : [進捗型]
    
    subscript(_ progress:工程型) -> 作業バー型? {
        get { return workMap[progress] }
        set { workMap[progress] = newValue }
    }
    
    func make作業バー() -> [作業バー型] {
        return [作業バー型](workMap.values)
    }
    
    func append(_ progress:進捗型) throws {
        let process = progress.工程
        if let current = progressMap[process] {
            try current.append(progress, state: self)
        } else {
            let state = try makeNewProgressState(progress, state:self)
            if state != nil {
                progressMap[process] = state
            }
        }
    }
    
    func contains(progressFor states:工程型...) -> Bool {
        let keys = progressMap.keys
        for state in states {
            if keys.contains(state) == false { return false }
        }
        return true
    }
    var progressCount : Int { return progressMap.count }
    
    var lastDate : Date? {
        return progressMap.values.max { $0.lastDate < $1.lastDate }?.lastDate
    }
}



class ProgressState {
    var accept : Date?
    var start : Date?
    var working : Date?
    var complete : Date?
    
    var lastDate : Date {
        return complete ?? start ?? accept!
    }
    
    init?(_ progress:進捗型, state:MakingState) throws {
        self.accept = nil
        self.start = nil
        self.working = nil
        self.complete = nil
        switch progress.作業内容 {
        case .受取: accept = progress.登録日時
        case .開始: start = progress.登録日時
        case .仕掛: working = progress.登録日時
        case .完了:
            try registFirstComplete(progress, state: state)
            return nil
        }
        let result = try validateFirstEnvironment(progress, state: state)
        if result == false {
            return nil
        }
        
    }
    
    /// 初期登録時の状態が適性か検査する。falseでスキップできる
    func validateFirstEnvironment(_ progress:進捗型, state:MakingState) throws -> Bool {
        return true
    }
    
    /// 完了のみの場合の処理
    func registFirstComplete(_ progress:進捗型, state:MakingState) throws {
        guard let from = state.lastDate else {
            throw 工程図エラー.開始時間の推定ができない
        }
        let work = 作業バー型(工程: progress.工程, 開始時間: from, 完了時間: progress.登録日時, hasStart: false, hasComplete: true)
        if state[progress.工程] != nil {
            throw 工程図エラー.説明できない作業の上書きが発生した
        }
        state[progress.工程] = work
    }
    
    /// ２番目以降のパラメータが追加された場合の処理
    func append(_ progress:進捗型, state:MakingState) throws {
        switch progress.作業内容 {
        case .受取:
            if start != nil || working != nil || complete != nil {
                throw 工程図エラー.説明できない作業内容の戻りが発生した
            }
            self.accept = progress.登録日時
        case .開始:
            if working != nil || complete != nil {
                throw 工程図エラー.説明できない作業内容の戻りが発生した
            }
            self.start = progress.登録日時
        case .仕掛:
            if complete != nil {
                throw 工程図エラー.説明できない作業内容の戻りが発生した
            }
            self.working = progress.登録日時
        case .完了:
            guard let from = start ?? accept ?? state.lastDate else {
                throw 工程図エラー.開始時間の推定ができない
            }
            let work = 作業バー型(工程: progress.工程, 開始時間: from, 完了時間: progress.登録日時, hasStart: start != nil, hasComplete: true)
            if state[progress.工程] != nil {
                throw 工程図エラー.説明できない作業の上書きが発生した
            }
            state[progress.工程] = work
        }
    }
    
    /// 最後にゴミが残った場合の確認
    func validateGarbage(_ state:MakingState) throws {
    }
}


func makeNewProgressState(_ progress:進捗型, state:MakingState) throws -> ProgressState?  {
    switch progress.工程 {
    case .営業 : return nil
    case .管理 : return try 管理ProgressState(progress, state: state)
    case .校正 : return try 校正ProgressState(progress, state: state)
    case .設計 : return nil
    case .原稿 : return try 原稿ProgressState(progress, state: state)
    case .出力 : return try 出力ProgressState(progress, state: state)
    case .入力 : return try 入力ProgressState(progress, state: state)
    case .レーザー: return try レーザーProgressState(progress, state: state)
    case .レーザー（アクリル）: return try アクリルProgressState(progress, state: state)
    case .照合検査 : return try 照合検査ProgressState(progress, state: state)
    case .腐蝕 : return try 腐蝕ProgressState(progress, state: state)
    case .オブジェ : return try オブジェProgressState(progress, state: state)
    case .フォーミング: return try フォーミングProgressState(progress, state: state)
    case .シャーリング : return try フォーミングProgressState(progress, state: state)
    case .プレーナー : return try フォーミングProgressState(progress, state: state)
    case .タレパン : return try フォーミングProgressState(progress, state: state)
    case .加工 : return try 加工ProgressState(progress, state: state)
    case .仕上 : return try 仕上ProgressState(progress, state: state)
    case .切文字 : return try 切文字ProgressState(progress, state: state)
    case .溶接 : return try 溶接ProgressState(progress, state: state)
    case .立ち上がり : return try 立ち上がりProgressState(progress, state: state)
    case .半田 : return try 半田ProgressState(progress, state: state)
    case .レーザー溶接 : return try レーザー溶接ProgressState(progress, state: state)
    case .裏加工: return try 裏加工ProgressState(progress, state: state)
    case .研磨 : return try 研磨ProgressState(progress, state: state)
    case .ルーター : return try ルーターProgressState(progress, state: state)
    case .タップ : return try ルーターProgressState(progress, state: state)
    case .印刷 : return try 印刷ProgressState(progress, state: state)
    case .表面仕上 : return try 表面仕上ProgressState(progress, state: state)
    case .塗装 : return try 塗装ProgressState(progress, state: state)
    case .外注 : return nil
    case .拭き取り : return try 拭き取りProgressState(progress, state: state)
    case .付属品準備 : return try 付属品準備ProgressState(progress, state: state)
    case .組立検品 : return try 組立検品ProgressState(progress, state: state)
    case .発送 : return try 発送ProgressState(progress, state: state)
    case .経理 : return nil
    }
}
