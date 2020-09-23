//
//  TargetMode.swift
//  DataManager
//
//  Created by manager on 2020/09/08.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum DMTargetMode: Int, CaseIterable {

    case 全部署 = 0
    case 営業管理 = -1
    case 原稿入力出力 = -2
    case レーザー照合 = -3
    case 両立ち上がり = -4
    case レーザーから立ち上がりまで = -5
    case 照合立ち上がり = -6
    case 営業 = 1
    case 管理 = 2
    case 原稿 = 3
    case 入力 = 4
    case 出力 = 5
    case レーザー = 6
    case 照合 = 7
    case 切文字 = 8
    case 立ち上がり = 9

    public var next: DMTargetMode {
        switch self {
        case .全部署: return .営業管理
        case .営業管理: return .原稿入力出力
        case .原稿入力出力: return .レーザー照合
        case .レーザー照合: return .両立ち上がり
        case .両立ち上がり: return .レーザーから立ち上がりまで
        case .レーザーから立ち上がりまで: return .照合立ち上がり
        case .照合立ち上がり: return .営業
        case .営業: return .管理
        case .管理: return .原稿
        case .原稿: return .入力
        case .入力: return .出力
        case .出力: return .レーザー
        case .レーザー: return .照合
        case .照合: return .切文字
        case .切文字: return .立ち上がり
        case .立ち上がり: return .全部署
        }
    }
    
    public var targets: [工程型] {
        switch self {
        case .全部署: return []
        case .営業管理: return [.営業, .管理]
        case .原稿入力出力: return [.原稿, .入力, .出力]
        case .レーザー照合: return [.レーザー, .照合検査]
        case .照合立ち上がり: return [.照合検査, .立ち上がり, .立ち上がり_溶接]
        case .両立ち上がり: return [.立ち上がり, .立ち上がり_溶接]
        case .レーザーから立ち上がりまで: return [.レーザー, .照合検査, .立ち上がり, .立ち上がり_溶接]
        case .営業: return [.営業]
        case .管理: return [.管理]
        case .原稿: return [.原稿]
        case .入力: return [.入力]
        case .出力: return [.出力]
        case .レーザー: return [.レーザー]
        case .照合: return [.照合検査]
        case .切文字: return [.切文字]
        case .立ち上がり: return [.立ち上がり, .立ち上がり_溶接]
        }
    }
    
    public init(for process: 工程型) {
        for mode in Self.allCases {
            if mode.targets.contains(process) {
                self = mode
                return
            }
        }
        self = .立ち上がり
    }
    
    public var captiuon: String {
        switch self {
        case .全部署: return "全部署"
        case .営業管理: return "営業管理"
        case .原稿入力出力: return "原稿入力出力"
        case .レーザー照合: return "レーザー照合"
        case .両立ち上がり: return "両立ち上がり"
        case .レーザーから立ち上がりまで: return "レーザーから立ち上がりまで"
        case .照合立ち上がり: return "照合立ち上がり"
        case .営業: return "営業"
        case .管理: return "管理"
        case .原稿: return "原稿"
        case .入力: return "入力"
        case .出力: return "出力"
        case .レーザー: return "レーザー"
        case .照合: return "照合"
        case .切文字: return "切文字"
        case .立ち上がり: return "立ち上がり"
        }
    }
}

public extension 指示書型 {
    func 状態表示(注目工程: [工程型]) -> String {
        var state: String
        // 状態
        switch self.伝票状態 {
        case .キャンセル:
            state = "キャ"
        case .発送済:
            state = "発送"
        case .未製作, .製作中:
            switch self.工程状態 {
            case .通常:
                state = "　　"
            case .保留:
                state = "保留"
            case .校正中:
                state = "校正"
            }
        }
        // 立ち上がり進度
        for target in 注目工程 {
            if let progress = self.工程別進捗一覧[target]?.last {
                switch progress.作業内容 {
                case .受取: state += " 受"
                case .開始: state += " 開"
                case .仕掛: state += " 掛"
                case .完了: state += " 完"
                }
                state += " " + progress.作業者.社員姓
                break
            }
        }
        return state
    }

}

