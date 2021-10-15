//
//  箱文字工程優先度.swift
//  DataManager
//
//  Created by manager on 2020/03/20.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

let 立ち上がり工程: [工程型] = [.立ち上がり, .立ち上がり_溶接]

public enum 箱文字前工程優先度型: Int, Comparable {
    case 照合検査完了 = 0
    case 照合検査開始 = 1
    case 照合検査受取 = 2
    case レーザー完了 = 3
    case レーザー開始 = 4
    case レーザー受取
    case 第３グループCM開始
    case 出力完了
    case 出力開始
    case 入力完了
    case 入力開始
    case 入力受取
    case 原稿完了
    case 原稿開始
    case 管理完了
    case 管理開始
    case 営業完了
    case 営業開始
    case その他

    public static func < (left: 箱文字前工程優先度型, right: 箱文字前工程優先度型) -> Bool {
        return left.rawValue < right.rawValue
    }
}

let 箱文字前工程一覧: [工程型] = [.営業, .管理, .原稿, .入力, .出力, .レーザー, .照合検査, .立ち上がり, .立ち上がり_溶接]

extension 指示書型 {

    public func 箱文字前工程_最終工程(of target: 工程型) -> 進捗型? {
        let skip立ち上がり = 立ち上がり工程.contains(target)
        for progress in self.進捗一覧.reversed() {
            if skip立ち上がり && 立ち上がり工程.contains(progress.工程) { continue }
            if 箱文字前工程一覧.contains(progress.工程) {
                if (target == .レーザー || target == .照合検査) && (progress.工程 == .出力 || progress.工程 == .立ち上がり) { continue }
                return progress
            }
        }
        return nil
    }
    
    public func 箱文字前工程_進捗表示(of target: 工程型) -> String {
        var str = ""
        if let progress = 箱文字前工程_最終工程(of: target) {
            str += progress.工程.description.prefix(2)
            str += "\(progress.作業内容.description)/\(progress.作業者.社員姓)".prefix(6)
        }
        return str
    }
    
    public var 箱文字前工程状態表示: String {
        var state: String = self.状態表示（２文字）
        // 立ち上がり進度
        for target in 立ち上がり工程 {
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

    public func 箱文字前工程必要チェック(for target: 工程型, buddyCheck: Bool = true) -> Bool {
        if self.is箱文字アクリのみ { return false }
        switch self.伝票状態 {
        case .キャンセル, .発送済: return false
        case .未製作, .製作中:
            break
        }
        switch self.承認状態 {
        case .承認済: break
        case .未承認: return false
        }
        let map = self.工程別進捗一覧
        if map[.溶接] != nil { return false }
        if map[.裏加工_溶接] != nil { return false }
        if map[.半田] != nil { return false }
        if map[.裏加工] != nil { return false }

        if map[target]?.contains(where: { $0.作業内容 == .完了 }) == true {
            if target == .立ち上がり || target == .立ち上がり_溶接 {
                return map[.照合検査]?.contains(where: { $0.作業内容 == .完了 }) != true
            }
            return false
        }
        if buddyCheck {
            if target == .立ち上がり { return self.箱文字前工程必要チェック(for: .立ち上がり_溶接, buddyCheck: false) }
            if target == .立ち上がり_溶接 { return self.箱文字前工程必要チェック(for: .立ち上がり, buddyCheck: false) }
        }
        return true
    }
    

    public func 箱文字前工程優先度(of target: 工程型) -> 箱文字前工程優先度型 {
        let map = self.工程別進捗一覧
        func is完了(_ process: 工程型) ->Bool { map[process]?.contains{ $0.作業内容 == .完了 } == true }
        if let last = map[.照合検査]?.last {
            if !is完了(.出力) && !is完了(.レーザー) { return .レーザー完了 }
            switch last.作業内容 {
            case .完了:
                return .照合検査完了
            case .開始, .仕掛:
                return .照合検査開始
            case .受取:
                return .照合検査受取
            }
        }
        if let last = map[.レーザー]?.last {
            if !is完了(.入力) { return .入力完了 }
            switch last.作業内容 {
            case .完了:
                return .レーザー完了
            case .開始, .仕掛:
                return .レーザー開始
            case .受取:
                return .レーザー受取
            }
        }
        if let list = map[.立ち上がり] {
            if list.contains(where: { $0.作業内容 == .開始 }) { return .第３グループCM開始 }
        }
        if let list = map[.立ち上がり_溶接] {
            if list.contains(where: { $0.作業内容 == .開始 }) { return .第３グループCM開始 }
        }
        if let last = map[.出力]?.last {
            switch last.作業内容 {
            case .完了:
                return .出力完了
            case .開始, .仕掛:
                return .出力開始
            default:
                break
            }
        }
        if let last = map[.入力]?.last {
            switch last.作業内容 {
            case .完了:
                return .入力完了
            case .開始, .仕掛:
                return .入力開始
            case .受取:
                return .入力受取
            }
        }
        if let last = map[.原稿]?.last {
            switch last.作業内容 {
            case .完了:
                return .原稿完了
            case .開始, .仕掛:
                return .原稿開始
            default:
                break
            }
        }
        if let last = map[.管理]?.last {
            switch last.作業内容 {
            case .完了:
                return .管理完了
            case .開始, .仕掛:
                return .管理開始
            default:
                break
            }
        }
        if let last = map[.営業]?.last {
            switch last.作業内容 {
            case .完了:
                return .営業完了
            case .開始, .仕掛:
                return .営業開始
            default:
                break
            }
        }
        return .その他
    }
}

public func 箱文字前工程比較(_ order1: 指示書型, _ order2: 指示書型, 工程 target: 工程型) -> Bool {
    let rank0 = order1.箱文字前工程優先度(of: target)
    let rank1 = order2.箱文字前工程優先度(of: target)
    if rank0 != rank1 { return rank0 < rank1 }
    let pri1 = ((try? order1.優先状態(for: [target])) ?? false) ? -1 : 0
    let pri2 = ((try? order2.優先状態(for: [target])) ?? false) ? -1 : 0
    if pri1 != pri2 {
        return pri1 < pri2
    }
    if order1.製作納期 != order2.製作納期 { return order1.製作納期 < order2.製作納期 }
    return false
}
