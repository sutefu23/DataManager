//
//  DMCacheSystem.swift
//  DataManager
//
//  Created by 四熊泰之 on R 3/09/20.
//

import Foundation
import AVFoundation

/// メモリの使用量を返す
public protocol DMCacheElement {
    /// メモリの使用量
    var memoryFootPrint: Int { get }
}
extension String: DMCacheElement {
    public var memoryFootPrint: Int { return self.utf8.count }
}
extension Optional: DMCacheElement where Wrapped: DMCacheElement {
    public var memoryFootPrint: Int { self?.memoryFootPrint ?? 8 }
}
extension Int: DMCacheElement {
    public var memoryFootPrint: Int { return MemoryLayout<Int>.stride }
}
extension UUID: DMCacheElement {
    public var memoryFootPrint: Int { return MemoryLayout<UUID>.stride }
}

public enum CacheMode {
    /// 有効期限がある
    case `dynamic`
    /// 有効期限がない
    case `static`
}
private var dbCachingMode: CacheMode = .dynamic

extension UserDefaults {
    /// DBのキャッシュモード
    public var dbCachingMode: CacheMode {
        get { return DataManager.dbCachingMode }
        set { DataManager.dbCachingMode = newValue }
    }
}


/// 複数のキャッシュシステムの統合メモリ管理システム。割り当てメモリの上限を超えた場合、古いキャッシュから削除する
public class DMCacheSystem {
    /// キャッシュ管理システム本体
    public static let shared = DMCacheSystem()
    
    public static func calcMaxCacheBytes(for rate: Int? = nil) -> Int {
        let rate = rate ?? defaults.maxCacheRate
        return (Int(ProcessInfo().physicalMemory) * rate) / 100
    }
    /// キャッシュとして必要な最小容量
    static let minMB = 256
    /// キャッシュのリスト
    private var storageList: [CacheStorage] = []
    /// リスト追加用のロック
    private let lock = NSLock()
    
    // MARK: ハンドルリスト（先頭が古い）
    /// ハンドル操作用のqueue
    private let queue = DispatchQueue(label: "cacheSystem.ncengine", qos: .utility)
    ///最古のキャッシュハンドル
    private var firstHandle: CacheHandle?
    /// 最新のキャッシュハンドル
    private var lastHandle: CacheHandle?
    
    /// 最大のメモリ占有量
    private var maxBytesData: Int
    /// 現在のメモリ占有量
    private var currentBytesData: Int = 0
    
    /// 最大キャッシュ容量
    public var maxBytes: Int {
        get {
            var result: Int = 0
            queue.sync { result = maxBytesData }
            return result
        }
        set { // 最大量の変更
            let maxBytes = max(newValue, DMCacheSystem.minMB * 1024 * 1024) //  最小限の容量は必要
            queue.async {
                self.execChangeMaxByte(maxBytes: maxBytes)
            }
        }
    }
    
    /// 現在のキャッシュ使用量
    public var currentBytes: Int {
        get {
            var result: Int = 0
            queue.sync { result = currentBytesData }
            return result
        }
        set { // 設定値以上の使用分を解放する
            queue.async {
                self.execClearLimit(limit: newValue)
            }
        }
    }
    
    /// キャッシュ容量をある程度空ける
    public func reserveCapacity() {
        self.currentBytes = (self.maxBytes / 4) * 3
    }
    
    /// キャッシュメモリの利用状況を人間の読める形で返す（システム情報表示用）
    public var cacheInfo: String {
        let currentBytes = self.currentBytes
        let maxBytes = self.maxBytes
        let cacheMB = currentBytes / (1024 * 1024)
        let cachePer = (currentBytes * 100) / maxBytes
        return "\(cacheMB) MB (\(cachePer)%)"
    }

    // MARK: - 初期化
    private init() {
        let maxCacheRate: Int = defaults.maxCacheRate
        let bytes = DMCacheSystem.calcMaxCacheBytes(for: maxCacheRate)
        self.maxBytesData = max(bytes, DMCacheSystem.minMB * 1024 * 1024) // 最低256MB確保する
    }
    
    // MARK: -
    private func execChangeMaxByte(maxBytes: Int) {
        if maxBytes <= 0 { return }
        self.maxBytesData = maxBytes
    }
    
    /// 管理対象のキャッシュシステムを追加する
    fileprivate func appendCache(_ storage: CacheStorage) {
        lock.lock(); defer { lock.unlock() }
        self.storageList.append(storage)
    }
    
    /// 管理対象のキャッシュシステムを削除する
    fileprivate func removeCache(_ storage: CacheStorage) {
        // ハンドル処理が未実装のため検証が終わるまで使わない
        lock.lock(); defer { lock.unlock() }
        guard let index = storageList.firstIndex(where: { $0 === storage }) else { return }
        storageList.remove(at: index)
    }
    
    /// キャッシュされたデータを全てクリアする
    public func clearAllCache() {
        lock.lock() // リストの追加を停止
        defer { lock.unlock() }
        self.storageList.forEach { $0.prepareClearAllCache() } // 準備(queueへの新規追加を停止する)
        queue.sync { // 準備中に発行されたコマンドを全て処理してから実行
            guard var handle = self.firstHandle else { return }  // 登録が無ければ作業不要
            handle.prev = nil // 本来は不要だがメモリリークがあった時に役に立つ
            while let next = handle.next { // 次のハンドル処理
                handle.next = nil
                next.prev = nil
                handle = next
            }
            self.firstHandle = nil
            self.lastHandle = nil
        }
        storageList.forEach { $0.completeClearAllCache() } // 完了(queueへの新規追加を許可する)
    }
    
    // MARK: - ハンドル操作
    /// 新規にハンドルを追加する
    fileprivate func append(handle: CacheHandle) {
        queue.async {
            self.execAppend(handle: handle)
        }
    }
    
    /// 登録済みのハンドルを最新に更新する
    fileprivate func touch(handle: CacheHandle) {
        queue.async {
            self.execTouch(handle: handle)
        }
    }
    
    /// 指定されたハンドルの登録を解除する
    fileprivate func remove(handle: CacheHandle) {
        queue.async {
            self.execRemoveHandle(handle: handle)
        }
    }

    // MARK: - serialqueue上で実行
    /// ハンドルを追加する
    private func execAppend(handle: CacheHandle) {
        if let last = self.lastHandle {
            last.next = handle
            handle.prev = last
            lastHandle = handle
        } else {
            firstHandle = handle
            lastHandle = handle
        }
        self.currentBytesData += handle.memoryFootPrint
        self.execClearLimit(limit: self.maxBytesData)
    }
    
    /// メモリの使用量を指定されたサイズまで削減する
    private func execClearLimit(limit: Int) {
        guard currentBytesData > limit else { return }
        // まずは無効なキャッシュを削除する
        lock.lock()
        self.storageList.forEach {
            $0.removeInvalidCache().forEach { self.execRemoveHandle(handle: $0) }
        }
        lock.unlock()
        while currentBytesData > limit, let handle = self.firstHandle {
            handle.storage.removeHandle(for: handle)
            self.currentBytesData -= handle.memoryFootPrint
            self.firstHandle = handle.next
            handle.prev = nil // メモリリーク対策
            handle.next = nil
        }
        if let firstHandle = self.firstHandle {
            if firstHandle.prev != nil { firstHandle.prev = nil }
        } else {
            lastHandle = nil
        }
    }

    /// 指定されたハンドルを削除する
    private func execRemoveHandle(handle: CacheHandle) {
        if let prev = handle.prev {
            if let next = handle.next { // リストの中間のhandle
                prev.next = next
                next.prev = prev
            } else { // 最後尾のhandle
                prev.next = nil
                self.lastHandle = prev
            }
        } else if let next = handle.next { // 先頭のhandle
            next.prev = nil
            self.firstHandle = next
        } else if firstHandle === handle { // 唯一のhandle
            assert(lastHandle === handle)
            firstHandle = nil
            lastHandle = nil
        } else { // パージ済みのhandle
            return
        }
        self.currentBytesData -= handle.memoryFootPrint
    }
    
    /// 指定されたハンドルを削除候補リストの最後尾に回す
    private func execTouch(handle: CacheHandle) {
        assert(firstHandle != nil)
        if let prev = handle.prev {
            if let next = handle.next { // リストの中間のhandle
                // リンクを外す
                prev.next = next
                next.prev = prev
            } else { // 最後尾のhandle
                // 何もしない
                return
            }
        } else if let next = handle.next { // 先頭のhandle
            // リンクを外す
            next.prev = nil
            self.firstHandle = next
        } else { // 唯一のhandle、またはパージ済みのhandle
            // 何もしない
            return
        }
        // 末尾に追加
        handle.next = nil
        self.lastHandle?.next = handle
        handle.prev = self.lastHandle
        self.lastHandle = handle
    }
}

/// 個別キャッシュデータの操作インターフェース
fileprivate class CacheHandle {
    /// 一つ古いハンドル
    final var prev: CacheHandle? = nil
    /// 一つ新しいハンドル
    var next: CacheHandle? = nil
    /// キャッシュデータのストレージ
    let storage: CacheStorage
    /// データのメモリ占有量
    let memoryFootPrint: Int
    
    init(map: CacheStorage, memoryFootPrint: Int) {
        self.storage = map
        self.memoryFootPrint = memoryFootPrint + 4*8 + 3*8
    }
}

/// キャッシュのインターフェース
fileprivate protocol CacheStorage: AnyObject {
    /// ハンドルに対応するキャッシュをパージする
    func removeHandle(for handle: CacheHandle)
    /// キャッシュの全消去の準備
    func prepareClearAllCache()
    /// キャッシュの全消去完了時の処理
    func completeClearAllCache()
    /// 無効なデータを削除する
    func removeInvalidCache() -> [CacheHandle]
}

extension CacheStorage {
    func removeInvalidCache() -> [CacheHandle] { [] }
}

/// キー情報付きの個別キャッシュデータの操作インターフェース
private class KeyedCacheHandle<S>: CacheHandle {
    let key: S
    
    init(map: CacheStorage, memoryFootPrint: Int, key: S) {
        self.key = key
        super.init(map: map, memoryFootPrint: memoryFootPrint + MemoryLayout<S>.stride)
    }
}

// MARK: -
/// 変換キャッシュ
public class DMCachingConverter<S: Hashable & DMCacheElement, R: DMCacheElement>: CacheStorage {
    /// データ変換を管理するオブジェクト。複数の同じ変換の待ち合わせに使用する
    private class ConvertData<R: DMCacheElement>: NSLock {
        override init() {
            super.init()
            self.lock()
        }
        /// 計算結果
        private var data: R!
        
        /// 書き込みがあるまで読込はブロックされる
        var value: R {
            get {
                self.lock(); defer { self.unlock() }
                return data
            }
            set {
                data = newValue
                self.unlock()
            }
        }
    }

    fileprivate let lock: NSLock
    private var map: [S: (handle: KeyedCacheHandle<S>, data: R)] = [:]
    
    private let converter: (S) -> R
    private var working: [S: ConvertData<R>] = [:]
    private var terminating: Bool = false
    
    /// 変換式を指定して初期化する
    public init(_ converter: @escaping (S) -> R) {
        self.lock = NSLock()
        self.converter = converter
        DMCacheSystem.shared.appendCache(self)
    }

    /// 変換を行う。キャッシュがある場合、キャッシュされたものを返す
    public func convert(_ keySource: S) -> R {
        lock.lock()
        if let (handle, data) = map[keySource] {
            DMCacheSystem.shared.touch(handle: handle)
            lock.unlock()
            return data
        } else if let data = working[keySource] {
            lock.unlock()
            return data.value
        }
        let data = ConvertData<R>()
        working[keySource] = data
        lock.unlock()
        
        let result = converter(keySource)
        data.value = result
        let handle = KeyedCacheHandle(map: self, memoryFootPrint: keySource.memoryFootPrint + result.memoryFootPrint, key: keySource)

        lock.lock()
        if !terminating {
            if map[keySource] == nil {
                map[keySource] = (handle, result)
                DMCacheSystem.shared.append(handle: handle)
            }
            working.removeValue(forKey: keySource)
        }
        lock.unlock()
        return result
    }
    
    /// キャッシュの取り扱いを終了する（一時的なキャッシュを想定）
    public func terminate() {
        lock.lock(); defer { lock.lock() }
        self.terminating = true
        self.map.values.forEach { DMCacheSystem.shared.remove(handle: $0.handle) }
        self.map.removeAll()
    }
    
    // MARK: DMCacheSystemからの操作インターフェース
    /// キャッシュ全クリアの準備
    fileprivate func prepareClearAllCache() {
        // workingは残しているためロック解除直後にworkingの中身が登録されることがある
        lock.lock()
        map.removeAll()
    }
    
    /// キャッシュ全クリアの完了
    fileprivate func completeClearAllCache() {
        lock.unlock()
    }
    
    /// 指定されたハンドルに対応するデータを消去する
    fileprivate func removeHandle(for handle: CacheHandle) {
        if case let handle as KeyedCacheHandle<S> = handle {
            lock.lock()
            map.removeValue(forKey: handle.key)
        } else { // あり得ないけど念のため
            lock.lock()
            if let index = map.firstIndex(where: { $0.value.handle === handle }) {
                map.remove(at: index)
            } else {
                fatalError() // 完全なロジックエラー
            }
        }
        lock.unlock()
    }
}

// MARK: -
/// 変換エラーも記録する変換キャッシュ
public class DMCachingTtyConverter<S: Hashable & DMCacheElement, R: DMCacheElement>: CacheStorage {
    /// DB検索を管理するオブジェクト。複数の同じ検索の待ち合わせに使用する
    private class SearchResult<R: DMCacheElement>: NSLock {
        override init() {
            super.init()
            self.lock()
        }
        private var data: Result<R, Error>!
        
        /// 書き込みがあるまで読込はブロックされる
        var value: Result<R, Error> {
            get {
                self.lock()
                defer { self.unlock() }
                return data
            }
            set {
                data = newValue
                self.unlock()
            }
        }
    }

    fileprivate let lock: NSLock
    private var map: [S: (handle: KeyedCacheHandle<S>, data: Result<R, Error>)] = [:]
    
    private let converter: (S) throws -> R
    private var working: [S: SearchResult<R>] = [:]

    /// 検索関数を元に初期化する
    public init(_ converter: @escaping (S) throws -> R) {
        self.converter = converter
        self.lock = NSLock()
        DMCacheSystem.shared.appendCache(self)
    }

    /// 指定されたパラメータで検索を行う
    public func find(_ keySource: S) throws -> R {
        lock.lock()
        if let (handle, result) = map[keySource] {
            DMCacheSystem.shared.touch(handle: handle)
            lock.unlock()
            return try result.get()
        } else if let data = working[keySource] { // この時は寿命は考えない
            lock.unlock()
            return try data.value.get()
        }
        let result = SearchResult<R>()
        working[keySource] = result
        lock.unlock()
        do {
            let data = try converter(keySource)
            let handle = KeyedCacheHandle(map: self, memoryFootPrint: keySource.memoryFootPrint + data.memoryFootPrint, key: keySource)
            result.value = .success(data)
            lock.lock()
            DMCacheSystem.shared.append(handle: handle)
            working.removeValue(forKey: keySource)
            map[keySource] = (handle, .success(data))
            lock.unlock()
            return data
        } catch {
            result.value = .failure(error)
            let handle = KeyedCacheHandle(map: self, memoryFootPrint: keySource.memoryFootPrint + 24, key: keySource)
            lock.lock()
            working.removeValue(forKey: keySource)
            map[keySource] = (handle, .failure(error))
            lock.unlock()
            throw error
        }
    }

    public func clearAll() {
        let cacheSystem = DMCacheSystem.shared
        lock.lock(); defer { lock.unlock() }
        map.values.forEach { cacheSystem.remove(handle: $0.handle) }
        map.removeAll()
    }
    /// 指定されたキーに対応するキャッシュを消去する
    public func flushCache(_ keySource: S) {
        lock.lock(); defer { lock.unlock() }
        map[keySource] = nil
    }
    
    // MARK: DMCacheSystemからの操作インターフェース
    /// キャッシュ全クリアの準備
    fileprivate func prepareClearAllCache() {
        // workingは残しているためロック解除直後にworkingの中身が登録されることがある
        lock.lock()
        map.removeAll()
    }
    
    /// キャッシュ全クリアの完了
    fileprivate func completeClearAllCache() {
        lock.unlock()
    }
    
    /// 指定されたハンドルに対応するデータを消去する
    fileprivate func removeHandle(for handle: CacheHandle) {
        if case let handle as KeyedCacheHandle<S> = handle {
            lock.lock()
            map.removeValue(forKey: handle.key)
        } else { // あり得ないけど念のため
            lock.lock()
            if let index = map.firstIndex(where: { $0.value.handle === handle }) {
                map.remove(at: index)
            } else {
                fatalError() // 完全なロジックエラー
            }
        }
        lock.unlock()
    }
}

// MARK: -
/// DB結果について正しく帰ってきた時のみキャッシュ
public class DMDBCache<S: Hashable & DMCacheElement, R: DMCacheElement>: CacheStorage {
    /// DB検索を管理するオブジェクト。複数の同じ検索の待ち合わせに使用する
    private class SearchResult<R: DMCacheElement>: NSLock {
        override init() {
            super.init()
            self.lock()
        }
        private var data: Result<R, Error>!
        
        /// 書き込みがあるまで読込はブロックされる
        var value: Result<R, Error> {
            get {
                self.lock()
                defer { self.unlock() }
                return data
            }
            set {
                data = newValue
                self.unlock()
            }
        }
    }

    fileprivate let lock: NSLock
    private var map: [S: (handle: KeyedCacheHandle<S>, date: Date, data: R)] = [:]
    private let lifeTime: TimeInterval
    
    private let converter: (S) throws -> R?
    private var working: [S: SearchResult<R?>] = [:]

    /// キャッシュの有効期限と検索関数を元に初期化する
    public init(lifeTime: TimeInterval = 60, _ converter: @escaping (S) throws -> R?) {
        switch dbCachingMode {
        case .dynamic:
            self.lifeTime = lifeTime // 通常の寿命
        case .static:
            self.lifeTime = max(lifeTime, 24 * 60 * 60) // 最低24時間の寿命
        }
        self.converter = converter
        self.lock = NSLock()
        DMCacheSystem.shared.appendCache(self)
    }

    /// 検索結果を登録する
    public func regist(_ object: R, forKey key: S) {
        lock.lock(); defer { lock.unlock() }
        if let handle = map[key]?.handle {
            DMCacheSystem.shared.touch(handle: handle) // ハンドル再利用
            map[key] = (handle, Date(), object)
        } else {
            let handle = KeyedCacheHandle(map: self, memoryFootPrint: key.memoryFootPrint + object.memoryFootPrint, key: key)
            DMCacheSystem.shared.append(handle: handle) // ハンドル新規登録
            map[key] = (handle, Date(), object)
        }
    }

    /// 指定のkeyに対して、キャッシュしていればtrueを返す
    public func isCaching(forKey key: S) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return map[key] != nil || working[key] != nil
    }
    
    /// 指定されたパラメータで検索を行う
    public func find(_ keySource: S, noCache: Bool = false) throws -> R? {
        lock.lock()
        if let (handle, date, data) = map[keySource] {
            if !noCache, date < Date(timeIntervalSinceNow: self.lifeTime) {
                if date < Date(timeIntervalSinceNow: self.lifeTime / 2) { // 寿命の半分までは積極的に保護する
                    DMCacheSystem.shared.touch(handle: handle)
                }
                lock.unlock()
                return data
            } else {
                map[keySource] = nil
                DMCacheSystem.shared.remove(handle: handle)
            }
        }
        if let data = working[keySource] { // この時は寿命は考えない
            lock.unlock()
            return try data.value.get()
        }
        let result = SearchResult<R?>()
        working[keySource] = result
        lock.unlock()
        do {
            if let data = try converter(keySource) {
                let date = Date()
                result.value = .success(data)
                let handle = KeyedCacheHandle(map: self, memoryFootPrint: keySource.memoryFootPrint + data.memoryFootPrint, key: keySource)
                lock.lock()
                DMCacheSystem.shared.append(handle: handle)
                working.removeValue(forKey: keySource)
                map[keySource] = (handle, date, data)
                lock.unlock()
                return data
            } else {
                result.value = .success(nil)
                lock.lock()
                working.removeValue(forKey: keySource)
                lock.unlock()
                return nil
            }
        } catch {
            result.value = .failure(error)
            lock.lock()
            working.removeValue(forKey: keySource)
            lock.unlock()
            throw error
        }
    }

    public func clearAll() {
        let cacheSystem = DMCacheSystem.shared
        lock.lock(); defer { lock.unlock() }
        map.values.forEach { cacheSystem.remove(handle: $0.handle) }
        map.removeAll()
    }
    /// 指定されたキーに対応するキャッシュを消去する
    public func flushCache(_ keySource: S) {
        lock.lock(); defer { lock.unlock() }
        guard let handle = map.removeValue(forKey: keySource)?.handle else { return }
        DMCacheSystem.shared.remove(handle: handle)
    }
    
    // MARK: DMCacheSystemからの操作インターフェース
    /// キャッシュ全クリアの準備
    fileprivate func prepareClearAllCache() {
        // workingは残しているためロック解除直後にworkingの中身が登録されることがある
        lock.lock()
        map.removeAll()
    }
    
    /// キャッシュ全クリアの完了
    fileprivate func completeClearAllCache() {
        lock.unlock()
    }
    
    /// 指定されたハンドルに対応するデータを消去する
    fileprivate func removeHandle(for handle: CacheHandle) {
        if case let handle as KeyedCacheHandle<S> = handle {
            lock.lock()
            map.removeValue(forKey: handle.key)
        } else { // あり得ないけど念のため
            lock.lock()
            if let index = map.firstIndex(where: { $0.value.handle === handle }) {
                map.remove(at: index)
            } else {
                fatalError() // 完全なロジックエラー
            }
        }
        lock.unlock()
    }
    
    /// 保有するキャッシュのうち、有効期限を切れたものを削除し、ハンドルを返す
    fileprivate func removeInvalidCache() -> [CacheHandle] {
        var handles: [CacheHandle] = []
        lock.lock(); defer { lock.unlock() }
        let expire = Date(timeIntervalSinceNow: lifeTime)
        for (key, data) in map where data.date > expire {
            map.removeValue(forKey: key)
            handles.append(data.handle)
        }
        return handles
    }
}
