//
//  箱文字優先度キャッシュ.swift
//  DataManager
//
//  Created by manager on 2020/02/26.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public let 箱文字優先度キャッシュ = 箱文字優先度キャッシュ型()

public class 箱文字優先度キャッシュ型 {
    struct CacheKey: Hashable {
        var number: 伝票番号型
        var process: 工程型?
    }
    
    let lock = NSLock()
    var cache: [CacheKey: 箱文字優先度型] = [:]
    
    public func allRegistered(for number: 伝票番号型) throws -> [箱文字優先度型] {
        let all = try 箱文字優先度型.allRegistered(for: number)
        lock.lock()
        all.forEach {
            guard let number = $0.伝票番号 else { return }
            let key = CacheKey(number: number, process: $0.工程)
            cache[key] = $0
        }
        lock.unlock()
        return all
    }
    
    public func find(_ number: 伝票番号型, _ process: 工程型?) throws -> 箱文字優先度型 {
        let key = CacheKey(number: number, process: process)
        lock.lock()
        if let cache = self.cache[key] {
            lock.unlock()
            return cache
        }
        lock.unlock()
        let result: 箱文字優先度型
        do {
            result = try 箱文字優先度型.findDirect(伝票番号: number, 工程: process) ?? 箱文字優先度型(number)
        } catch {
            NSLog(error.localizedDescription)
            result = 箱文字優先度型(number)
        }
        lock.lock()
        cache[key] = result
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
    public func 優先状態(for targets: [工程型]) -> Bool? {
        switch self.優先設定(for: targets) {
        case .優先あり: return true
        case .優先なし: return false
        case nil:
            return nil
        case .自動判定:
            break
        }
        if targets.isEmpty {
            switch self.優先設定(for: []) {
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
    
    public func 白表示(for targets: [工程型]) -> Bool? {
        switch self.表示設定(for: targets) {
        case .白: return true
        case .黒: return true
        case nil: return nil
        case .自動判定:
            break
        }
        if targets.isEmpty {
            switch self.表示設定(for: []) {
            case .白: return true
            case .黒: return true
            case nil: return nil
            case .自動判定:
                break
            }
        }
        let limit = Day().nextWorkDay.nextWorkDay.nextWorkDay // 3営業日後
        return self.製作納期 <= limit
    }
    
    public func 箱文字優先設定(for target: 工程型?) -> 優先設定型 {
        let data = (try? 箱文字優先度キャッシュ.find(self.伝票番号, target))
        return data?.優先設定 ?? .自動判定
    }
    
    public func set箱文字優先設定(for target: 工程型?, 設定: 優先設定型) {
        guard let data = (try? 箱文字優先度キャッシュ.find(self.伝票番号, target)) else { return }
        data.優先設定 = 設定
        data.synchronize()
    }
    
    public func 箱文字表示設定(for target: 工程型?) -> 表示設定型 {
        let data = (try? 箱文字優先度キャッシュ.find(self.伝票番号, target))
        return data?.表示設定 ?? .自動判定
    }
    public func set箱文字表示設定(for target: 工程型?, 設定: 表示設定型) {
        guard let data = (try? 箱文字優先度キャッシュ.find(self.伝票番号, target)) else { return }
        data.表示設定 = 設定
        data.synchronize()
    }
    
    public func 優先設定(for targets: [工程型]) -> 優先設定型? {
        if targets.isEmpty {
            return self.箱文字優先設定(for: nil)
        }
        var settings: 優先設定型? = nil
        for process in targets {
            let tmp = self.箱文字優先設定(for: process)
            if let current = settings {
                if tmp != current { return nil }
            } else {
                settings = tmp
            }
        }
        return settings
    }
    
    public func 表示設定(for targets: [工程型]) -> 表示設定型? {
        if targets.isEmpty {
            return self.箱文字表示設定(for: nil)
        }
        var settings: 表示設定型? = nil
        for process in targets {
            let tmp = self.箱文字表示設定(for: process)
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
            let list = try 箱文字優先度キャッシュ.allRegistered(for: self.伝票番号)
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
            let list = try 箱文字優先度キャッシュ.allRegistered(for: self.伝票番号)
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
