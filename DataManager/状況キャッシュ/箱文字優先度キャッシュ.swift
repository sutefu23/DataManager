//
//  箱文字優先度キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/02/26.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public class 箱文字優先度キャッシュ型 {
    public static let shared = 箱文字優先度キャッシュ型()
    public var キャッシュ寿命: TimeInterval = 60 * 10 // デフォルトは10分間
    
    struct CacheKey: Hashable {
        var number: 伝票番号型
        var process: 工程型?
    }
    struct TimeData {
        let time: Date
        let data: 箱文字優先度型
        
        init(_ data: 箱文字優先度型) {
            self.data = data
            self.time = Date()
        }
    }
    
    let lock = NSLock()
    var cache: [CacheKey: TimeData] = [:]
    
    public func allRegistered(for number: 伝票番号型) throws -> [箱文字優先度型] {
        let all = try 箱文字優先度型.allRegistered(for: number)
        lock.lock()
        all.forEach {
            guard let number = $0.伝票番号 else { return }
            let key = CacheKey(number: number, process: $0.工程)
            cache[key] = TimeData($0)
        }
        lock.unlock()
        return all
    }
    
    public func contains(_ number: 伝票番号型, _ process: 工程型?) -> Bool {
        let key = CacheKey(number: number, process: process)
        lock.lock()
        defer { lock.unlock() }
        guard let cache = self.cache[key] else { return false }
        let time = Date(timeInterval: -キャッシュ寿命, since: Date())
        if cache.time >= time { return true }
        self.cache[key] = nil
        return false
    }
    
    public func find(_ number: 伝票番号型, _ process: 工程型?) throws -> 箱文字優先度型 {
        let key = CacheKey(number: number, process: process)
        lock.lock()
        if let cache = self.cache[key] {
            lock.unlock()
            let time = Date(timeInterval: -キャッシュ寿命, since: Date())
            if cache.time >= time {
                return cache.data
            }
        } else {
            lock.unlock()
        }
        let result: 箱文字優先度型
        do {
            result = try 箱文字優先度型.findDirect(伝票番号: number, 工程: process) ?? 箱文字優先度型(number, 工程: process)
        } catch {
            NSLog(error.localizedDescription)
            result = 箱文字優先度型(number, 工程: process)
        }
        lock.lock()
        cache[key] = TimeData(result)
        lock.unlock()
        return result
    }
    
    public func removeAll() {
        lock.lock()
        self.cache.removeAll()
        lock.unlock()
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
    public func 優先状態(for targets: [工程型], cacheOnly: Bool = false) -> Bool? {
        switch self.優先設定(for: targets, cacheOnly: cacheOnly) {
        case .優先あり: return true
        case .優先なし: return false
        case nil:
            return nil
        case .自動判定:
            break
        }
        if !targets.isEmpty {
            switch self.優先設定(for: [], cacheOnly: cacheOnly) {
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
        default:
            switch self.伝票種別 {
            case .クレーム, .再製:
                return true
            case .通常:
                return false
            }
        }
    }
    
    public func 白表示(for targets: [工程型], cacheOnly: Bool = false) -> Bool? {
        switch self.表示設定(for: targets, cacheOnly: cacheOnly) {
        case .白: return true
        case .黒: return false
        case nil: return nil
        case .自動判定:
            break
        }
        if !targets.isEmpty {
            switch self.表示設定(for: [], cacheOnly: cacheOnly) {
            case .白: return true
            case .黒: return false
            case nil: return nil
            case .自動判定:
                break
            }
        }
        var limit = Day().nextWorkDay.nextWorkDay.nextWorkDay // 3営業日後
        if targets.contains(.原稿) || targets.contains(.入力) || targets.contains(.出力) {
            limit = limit.nextWorkDay // 4営業日後
        } else if targets.contains(.営業) || targets.contains(.管理) {
            limit = limit.nextWorkDay.nextWorkDay // 5営業日後
        }
        return self.製作納期 <= limit
    }
    
    public func 箱文字優先設定(for target: 工程型?, cacheOnly: Bool = false) -> 優先設定型 {
        if cacheOnly && !箱文字優先度キャッシュ型.shared.contains(self.伝票番号, target) {
            return .自動判定
        }
        let data = (try? 箱文字優先度キャッシュ型.shared.find(self.伝票番号, target))
        return data?.優先設定 ?? .自動判定
    }
    
    public func set箱文字優先設定(for target: 工程型?, 設定: 優先設定型) {
        guard let data = (try? 箱文字優先度キャッシュ型.shared.find(self.伝票番号, target)) else { return }
        data.優先設定 = 設定
        data.synchronize()
    }
    
    public func 箱文字表示設定(for target: 工程型?, cacheOnly: Bool = false) -> 表示設定型 {
        if cacheOnly && !箱文字優先度キャッシュ型.shared.contains(self.伝票番号, target) {
            return .自動判定
        }
        let data = (try? 箱文字優先度キャッシュ型.shared.find(self.伝票番号, target))
        return data?.表示設定 ?? .自動判定
    }
    public func set箱文字表示設定(for target: 工程型?, 設定: 表示設定型) {
        guard let data = (try? 箱文字優先度キャッシュ型.shared.find(self.伝票番号, target)) else { return }
        data.表示設定 = 設定
        data.synchronize()
    }
    
    public func 優先設定(for targets: [工程型], cacheOnly: Bool = false) -> 優先設定型? {
        if targets.isEmpty {
            return self.箱文字優先設定(for: nil, cacheOnly: cacheOnly)
        }
        var settings: 優先設定型? = nil
        for process in targets {
            let tmp = self.箱文字優先設定(for: process, cacheOnly: cacheOnly)
            if let current = settings {
                if tmp != current { return nil }
            } else {
                settings = tmp
            }
        }
        return settings
    }
    
    public func 表示設定(for targets: [工程型], cacheOnly: Bool = false) -> 表示設定型? {
        if targets.isEmpty {
            return self.箱文字表示設定(for: nil, cacheOnly: cacheOnly)
        }
        var settings: 表示設定型? = nil
        for process in targets {
            let tmp = self.箱文字表示設定(for: process, cacheOnly: cacheOnly)
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
            list.forEach {
                $0.優先設定 = 設定
                $0.synchronize()
            }
            self.set箱文字優先設定(for: nil, 設定: 設定)
        } else {
            targets.forEach { self.set箱文字優先設定(for: $0, 設定: 設定) }
        }
    }
    
    public func set箱文字表示設定(for targets: [工程型], 設定: 表示設定型) throws {
        if targets.isEmpty {
            let list = try 箱文字優先度キャッシュ型.shared.allRegistered(for: self.伝票番号)
            list.forEach {
                $0.表示設定 = 設定
                $0.synchronize()
            }
            self.set箱文字表示設定(for: nil, 設定: 設定)
        } else {
            targets.forEach { self.set箱文字表示設定(for: $0, 設定: 設定) }
        }
    }

}
