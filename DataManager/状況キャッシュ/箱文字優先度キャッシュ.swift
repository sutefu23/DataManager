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
    let lock = NSLock()
    var cache: [伝票番号型: 箱文字優先度型] = [:]
    
    public func find(_ number: 伝票番号型) throws -> 箱文字優先度型 {
        lock.lock()
        if let cache = self.cache[number] {
            lock.unlock()
            return cache
        }
        lock.unlock()
        let result: 箱文字優先度型
        do {
            result = try 箱文字優先度型.findDirect(伝票番号: number) ?? 箱文字優先度型(number)
        } catch {
            NSLog(error.localizedDescription)
            result = 箱文字優先度型(number)
        }
        lock.lock()
        cache[number] = result
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
    public var 箱文字優先設定: 優先設定型 {
        get {
            let data = (try? 箱文字優先度キャッシュ.find(self.伝票番号))
            return data?.優先設定 ?? .自動判定
        }
        set {
            guard let data = (try? 箱文字優先度キャッシュ.find(self.伝票番号)) else { return }
            data.優先設定 = newValue
            data.synchronize()
        }
    }
    
    public var 箱文字表示設定: 表示設定型 {
        get {
            let data = (try? 箱文字優先度キャッシュ.find(self.伝票番号))
            return data?.表示設定 ?? .自動判定
        }
        set {
            guard let data = (try? 箱文字優先度キャッシュ.find(self.伝票番号)) else { return }
            data.表示設定 = newValue
            data.synchronize()
        }
    }
}
