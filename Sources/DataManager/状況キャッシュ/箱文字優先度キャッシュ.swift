//
//  箱文字優先度キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/02/26.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 箱文字優先度キャッシュKey型: Hashable, DMCacheElement, CustomStringConvertible {
    var number: 伝票番号型
    var process: 工程型?
    
    public var memoryFootPrint: Int {
        var size = number.memoryFootPrint
        if let process = process {
            size += process.memoryFootPrint
        }
        return size
    }
    
    public var description: String {
        return "伝票番号: \(number.整数文字列) 工程: \(process?.description ?? "nil")"
    }
}

public class 箱文字優先度キャッシュ型: DMDBCache<箱文字優先度キャッシュKey型, 箱文字優先度型> {
    public static let shared: 箱文字優先度キャッシュ型 = 箱文字優先度キャッシュ型(lifeSpan: 10 * 60, nilCache: true) {
        let number = $0.number
        let process = $0.process
        return try 箱文字優先度型.findDirect(伝票番号: number, 工程: process)
    }

    public func allRegistered(for number: 伝票番号型) throws -> [箱文字優先度型] {
        let all = try 箱文字優先度型.allRegistered(for: number)
        all.forEach {
            guard let number = $0.伝票番号 else { return }
            let key = 箱文字優先度キャッシュKey型(number: number, process: $0.工程)
            self.regist($0, forKey: key)
        }
        return all
    }

    public func contains(_ number: 伝票番号型, _ process: 工程型?) -> Bool {
        let key = 箱文字優先度キャッシュKey型(number: number, process: process)
        return isCaching(forKey: key)
    }

    public func find(_ number: 伝票番号型, _ process: 工程型?) throws -> 箱文字優先度型 {
        let key = 箱文字優先度キャッシュKey型(number: number, process: process)
        return try find(key, noCache: false) ?? 箱文字優先度型(number, 工程: process)
    }
    
    func update(_ data: 箱文字優先度型) {
        guard let number = data.伝票番号 else { return }
        let key = 箱文字優先度キャッシュKey型(number: number, process: data.工程)
        self.regist(data, forKey: key)
    }
}

extension 指示書型 {
    func 箱文字優先状態(for target: [工程型]) -> Bool {
        switch self.伝票種別 {
        case .クレーム, .再製:
            return true
        case .通常:
            break
        }
        func check仕上(_ surface: String) -> Bool {
            return surface.contains("梨地") || surface.contains("メッキ") || surface.contains("めっき") || surface.contains("腐食") || surface.contains("イブシ")
        }
        if check仕上(self.表面仕上1) || check仕上(self.表面仕上2) || check仕上(self.側面仕上1) || check仕上(self.側面仕上2) { return true }
        for d in self.箱文字側面高さ {
            if d <= 10 || d >= 150 { return true }
        }
        for size in self.寸法サイズ {
            if size <= 100 || size >= 1500 { return true }
        }
        return false
    }
    func 切文字優先状態(for target: [工程型]) -> Bool {
        if self.略号.contains(.看板) { return true }
        switch self.伝票種別 {
        case .クレーム, .再製:
            return true
        case .通常:
            break
        }
        if !self.枠材質.isEmpty || !self.台板材質.isEmpty { return true }
        let uranames = Set<String>(["ボルト立","浮かしパイプ付","ナット付","銘板ボルト立","看板三角コーナー","別枠三角コーナー","看板コの字ビス止","上下のみL金具止","別枠コの字ビス止","看板梯形Lアングル","別枠梯形Lアングル","看板四方Lアングル","別枠四方Lアングル","看板箱曲ビス止","別枠箱曲ビス止","下記"])
        if self.塗装文字数概算 >= 20 && uranames.contains(self.裏仕様) { return true }
        func check仕上(_ surface: String) -> Bool {
            let surface = surface.toJapaneseNormal
            return (surface.contains("メッキ") && !surface.contains("チタン")) || surface.contains("めっき")
        }
        if check仕上(self.表面仕上1) || check仕上(self.表面仕上2) || check仕上(self.側面仕上1) || check仕上(self.側面仕上2) { return true }
        return false
    }
    public func 優先状態(for targets: [工程型], cacheOnly: Bool = false) throws -> Bool? {
        switch try self.優先設定(for: targets, cacheOnly: cacheOnly) {
        case .優先あり: return true
        case .優先なし: return false
        case nil:
            return nil
        case .自動判定:
            break
        }
        if !targets.isEmpty {
            switch try self.優先設定(for: [], cacheOnly: cacheOnly) {
                case .優先あり: return true
                case .優先なし: return false
                case nil:
                    return nil
                case .自動判定:
                    break
            }
        }
        switch self.伝票種類 {
        case .箱文字:
            return self.箱文字優先状態(for: targets)
        case .切文字:
            return self.切文字優先状態(for: targets)
        default:
            switch self.伝票種別 {
            case .クレーム, .再製:
                return true
            case .通常:
                return false
            }
        }
    }
    
    public func 白表示(for targets: [工程型], cacheOnly: Bool = false) throws -> Bool? {
        switch try self.表示設定(for: targets, cacheOnly: cacheOnly) {
        case .白: return true
        case .黒: return false
        case nil: return nil
        case .自動判定:
            break
        }
        func check(_ process: 工程型) -> Bool {
            let start: 作業内容型 = (process == .管理 || process == .フォーミング) ? .受取 : .開始
            let list = self.進捗一覧.filter {
                if $0.登録日.isToday && 箱文字優先度型.自動有効期限 <= $0.登録時間 { return false }
                return true
            }
            return list.contains(工程: process, 作業内容: start) || list.contains(工程: process, 作業内容: .完了)
        }
        return targets.contains {
            let days: Int
            switch self.伝票種類 {
            case .箱文字:
                switch $0 {
                case .営業, .管理: // 6営業日後
                    days = 6
                case .原稿, .入力, .出力: // 5営業日後
                    days = 5
                case .フィルム, .レーザー, .照合検査, . 立ち上がり, .立ち上がり_溶接: // 4営業日後
                    days = 4
                default: // 3営業日後
                    days = 3
                }
            case .エッチング, .切文字, .加工:
                switch $0 {
                case .営業, .管理: // 3営業日後
                    days = 4
                case .原稿, .入力, .出力: // 3営業日後
                    days = 3
                case .フィルム, .レーザー, .照合検査, . 立ち上がり, .立ち上がり_溶接: // 2営業日後
                    days = 2
                default: // 3営業日後
                    days = 1
                }
            case .外注, .校正:
                days = 0
            }
            let limit = Day().appendWorkDays(days)
            if self.製作納期 <= limit { return true }
            switch self.伝票種類 {
            case .箱文字:
                if check($0) { return true }
            case .切文字, .エッチング, .加工, .外注, .校正:
                break
            }
            switch $0 {
            case .照合検査: return check(.レーザー) && check(.出力)
            case .立ち上がり, .立ち上がり_溶接: return check(.照合検査) || check(.レーザー)
            default:
                return false
            }
        }
    }
    
    public func 箱文字優先設定(for target: 工程型?, cacheOnly: Bool = false) throws -> 優先設定型 {
        if cacheOnly && !箱文字優先度キャッシュ型.shared.contains(self.伝票番号, target) {
            return .自動判定
        }
        let data = try 箱文字優先度キャッシュ型.shared.find(self.伝票番号, target)
        return data.優先設定
    }
    
    public func set箱文字優先設定(for target: 工程型?, 設定: 優先設定型) throws {
        let data = try 箱文字優先度キャッシュ型.shared.find(self.伝票番号, target)
        data.優先設定 = 設定
        try data.synchronize()
    }
    
    public func 箱文字表示設定(for target: 工程型?, cacheOnly: Bool = false) throws -> 表示設定型 {
        if cacheOnly && !箱文字優先度キャッシュ型.shared.contains(self.伝票番号, target) { return .自動判定 }
        let data = try 箱文字優先度キャッシュ型.shared.find(self.伝票番号, target)
        return data.表示設定
    }
    public func set箱文字表示設定(for target: 工程型?, 設定: 表示設定型) throws {
        let data = try 箱文字優先度キャッシュ型.shared.find(self.伝票番号, target)
        data.表示設定 = 設定
        try data.synchronize()
    }
    
    public func 優先設定(for targets: [工程型], cacheOnly: Bool = false) throws -> 優先設定型? {
        if targets.isEmpty {
            return try self.箱文字優先設定(for: nil, cacheOnly: cacheOnly)
        }
        var settings: 優先設定型? = nil
        for process in targets {
            let tmp = try self.箱文字優先設定(for: process, cacheOnly: cacheOnly)
            if let current = settings {
                if tmp != current { return nil }
            } else {
                settings = tmp
            }
        }
        return settings
    }
    
    public func 表示設定(for targets: [工程型], cacheOnly: Bool = false) throws -> 表示設定型? {
        if targets.isEmpty {
            return try self.箱文字表示設定(for: nil, cacheOnly: cacheOnly)
        }
        var settings: 表示設定型? = nil
        for process in targets {
            let tmp = try self.箱文字表示設定(for: process, cacheOnly: cacheOnly)
            if let current = settings {
                if tmp != current { return nil }
            } else {
                settings = tmp
            }
        }
        return settings
    }
    
    public func set箱文字優先設定(for targets: [工程型], 設定: 優先設定型) throws {
        if targets.isEmpty {
            let list = try 箱文字優先度キャッシュ型.shared.allRegistered(for: self.伝票番号)
            try list.forEach {
                $0.優先設定 = 設定
                try $0.synchronize()
            }
            try self.set箱文字優先設定(for: nil, 設定: 設定)
        } else {
            try targets.forEach { try self.set箱文字優先設定(for: $0, 設定: 設定) }
        }
    }
    
    public func set箱文字表示設定(for targets: [工程型], 設定: 表示設定型) throws {
        if targets.isEmpty {
            let list = try 箱文字優先度キャッシュ型.shared.allRegistered(for: self.伝票番号)
            try list.forEach {
                $0.表示設定 = 設定
                try $0.synchronize()
            }
            try self.set箱文字表示設定(for: nil, 設定: 設定)
        } else {
            try targets.forEach { try self.set箱文字表示設定(for: $0, 設定: 設定) }
        }
    }
}
