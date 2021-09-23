//
//  DMCacheSystem.swift
//  DataManager
//
//  Created by 四熊泰之 on R 3/09/20.
//

import Foundation
import AVFoundation

// MARK: -
/// DBのキャッシュモード
public enum CacheMode {
    /// 有効期限がある
    case `dynamic`
    /// 有効期限がない
    case `static`
}

extension UserDefaults {
    /// DBのキャッシュモード
    public var dbCachingMode: CacheMode {
        get { return DataManager.dbCachingMode }
        set { DataManager.dbCachingMode = newValue }
    }
}
/// DBキャッシュモード（実体）
private var dbCachingMode: CacheMode = .dynamic

// MARK: -
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
    /// 外部での生成禁止
    private init() {
        let maxCacheRate: Int = defaults.maxCacheRate
        let bytes = DMCacheSystem.calcMaxCacheBytes(for: maxCacheRate)
        self.maxBytesData = max(bytes, DMCacheSystem.minMB * 1024 * 1024) // 最低256MB確保する
    }
    
    // MARK: -
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
    public func removeAllCache() {
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
        handle.storage = nil
        queue.async {
            self.execRemoveHandle(handle: handle)
        }
    }

    fileprivate func remove(handles: [CacheHandle]) {
        assert(handles.allSatisfy { $0.storage == nil})
        queue.async {
            handles.forEach { self.execRemoveHandle(handle: $0) }
        }
    }

    // MARK: - serialqueue上で実行
    /// 最大キャッシュ容量を変更する
    private func execChangeMaxByte(maxBytes: Int) {
        if maxBytes <= 0 { return }
        self.maxBytesData = maxBytes
    }
    
    /// ハンドルを追加する
    private func execAppend(handle: CacheHandle) {
        if let last = self.lastHandle {
            last.next = handle
            handle.prev = last
            lastHandle = handle
        } else {
            assert(firstHandle == nil)
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
            if let storage = handle.storage {
                storage.removeHandle(for: handle)
                handle.storage = nil
            }
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
        assert(handle.storage == nil) // 事前にsotrageと切り離されている必要がある
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

// MARK: - インターフェース定義
/// 個別キャッシュデータの操作インターフェース
fileprivate class CacheHandle {
    /// 一つ古いハンドル
    final var prev: CacheHandle? = nil
    /// 一つ新しいハンドル
    var next: CacheHandle? = nil
    /// キャッシュデータのストレージ
    unowned var storage: CacheStorage? // unownedは危険だがweakは重過ぎるため使用
    /// データのメモリ占有量
    let memoryFootPrint: Int
    
    /// ハンドルの所有者と占有するメモリ量を登録する
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
    /// 無効なデータを削除して対応するハンドルを返す
    func removeInvalidCache() -> [CacheHandle]
}

// MARK: - 共有コード
/// 個別キャッシュデータの操作インターフェース + キャッシュデータ
private class KeyResultCacheHandle<Key: DMCacheKey, Data: BasicCacheResult>: CacheHandle {
    let key: Key
    var result: Data // 制約:読み書きはlock内でのみ行う
    
    init(map: CacheStorage, memoryFootPrint: Int, key: Key, result: Data) {
        self.key = key
        self.result = result
        super.init(map: map, memoryFootPrint: memoryFootPrint + key.memoryFootPrint)
    }
}

/// キャッシュデータの共通の挙動
public protocol BasicCacheResult {
    associatedtype R2
    
    init(_ data: R2)
    init(_ error: Error)

    func get() throws -> R2
}

public typealias DMCacheKey = DMCacheElement & Hashable & CustomStringConvertible
/// 基本的なキャッシュの基礎
public class BasicCacheStorage<Key: DMCacheKey, Data: BasicCacheResult, R2: DMCacheElement>: CacheStorage where Data.R2 == R2 {
    /// 管理用ロック
    fileprivate let lock: NSLock
    /// 変換関数
    fileprivate let converter: (Key) throws -> R2
    /// キャッシュデータ
    fileprivate var map: [Key: KeyResultCacheHandle<Key, Data>]
    /// 作業中データ
    fileprivate var working: [Key: SearchResult<R2>]

    // MARK: - 汎用インターフェース
    public var isDebug: Bool
    
    public init(_ converter: @escaping (Key) throws -> R2) {
        self.converter = converter
        self.map = [:]
        self.working = [:]
        self.isDebug = false
        self.lock = NSLock()
        DMCacheSystem.shared.appendCache(self)
    }

    deinit {
        removeAllHandles() // handleのstorageがunownedのためここで削除しておかないと危険
    }

    /// map内の全てのハンドルを解除する(mapの全クリアの下準備)
    private func removeAllHandles() {
        let handles: [CacheHandle] = map.values.map {
            $0.storage = nil
            return $0
        }
        DMCacheSystem.shared.remove(handles: handles)
    }
    
    /// 全クリア
    public final func removeAllCache() {
        lock.lock(); defer { lock.unlock() }
        removeAllHandles()
        map.removeAll()
    }
    /// 指定されたキーに対応するキャッシュを消去する
    public final func removeCache(forKey keySource: Key) {
        lock.lock(); defer { lock.unlock() }
        guard let handle = map.removeValue(forKey: keySource) else { return }
        DMCacheSystem.shared.remove(handle: handle)
    }

    /// クラス名文字列(デバッグ用)
    final var name: String {
        let name = String(describing: type(of: self))
        if name.hasSuffix("型") {
            return String(name.dropLast())
        } else {
            return name
        }
    }

    /// キャッシュ変換を行う
    func basic_convert(forceUpdate: Bool, forKey key: Key) throws -> R2 {
        lock.lock()
        // キャッシュにあればそれを返す
        if let handle = map[key] {
            if !forceUpdate {
                let result = handle.result
                if basic_validate(result) {
                    #if DEBUG
                    if isDebug { DMLogSystem.shared.debugLog("キャッシュ有効[\(name)]", detail: key.description, level: .debug) }
                    #endif
                    lock.unlock()
                    DMCacheSystem.shared.touch(handle: handle)
                    return try result.get()
                } else {
                #if DEBUG
                if isDebug { DMLogSystem.shared.debugLog("キャッシュ無効[\(name)]", detail: key.description, level: .debug) }
                #endif
                }
            } else {
                #if DEBUG
                if isDebug { DMLogSystem.shared.debugLog("キャッシュ強制無効[\(name)]", detail: key.description, level: .debug) }
                #endif
            }
            map[key] = nil
            DMCacheSystem.shared.remove(handle: handle)
        }
        // 計算中なら計算を待って結果をもらう
        if let data = working[key] { // この時は寿命は考えない
            lock.unlock()
            return try data.result.get()
        }
        #if DEBUG
        if isDebug { DMLogSystem.shared.debugLog("キャッシュなし[\(name)]", detail: key.description, level: .debug) }
        #endif
        // 新規計算を登録する
        let result = SearchResult<R2>()
        working[key] = result
        lock.unlock()
        defer { // 後処理登録
            working[key] = nil
            lock.unlock()
        }
        do { // 新規計算を登録する
            let data = try converter(key)
            result.result = .success(data)
            basic_lock_regist(data, forKey: key)
            return data
        } catch { // エラー時はエラーを登録する
            do {
                let data = try basic_lock_recovery(error, forKey: key) // リカバリ処理
                DMLogSystem.shared.log("キャッシュエラーリカバリ成功[\(name)]", detail: error.localizedDescription)
                result.result = .success(data)
                return data
            } catch { // リカバリ失敗
                DMLogSystem.shared.log("キャッシュエラー確定[\(name)]", detail: error.localizedDescription)
                result.result = .failure(error)
                throw error
            }
        }
    }
    
    // MARK: - 内部データ処理インターフェース
    /// dataが現在も有効かどうかチェックする
    fileprivate func basic_validate(_ data: Data) -> Bool { true } // デフォルトでは常に有効
    /// dataを登録する
    fileprivate func basic_lock_regist(_ data: R2, forKey key: Key) {
        // 単純にキャッシュする
        basic_lock_regist(Data(data), memoryFootPrint: data.memoryFootPrint, forKey: key)
    }
    /// エラーのリカバリ処理を行う
    fileprivate func basic_lock_recovery(_ error: Error, forKey key: Key) throws -> R2 {
        // デフォルト実装ではリカバリは諦めてエラーそのものをキャッシュする
        basic_lock_regist(Data(error), memoryFootPrint: 24, forKey: key)
        throw error
    }
    /// Dataをキャッシュする
    fileprivate func basic_lock_regist(_ data: Data, memoryFootPrint: Int, forKey key: Key) {
        let handle = KeyResultCacheHandle(map: self, memoryFootPrint: memoryFootPrint, key: key, result: data)
        lock.lock()
        map[key] = handle
        DMCacheSystem.shared.append(handle: handle)
    }

    // MARK: DMCacheSystemからの内部操作インターフェース
    /// ハンドルに対応するキャッシュをパージする
    fileprivate final func removeHandle(for handle: CacheHandle) {
        if case let handle as KeyResultCacheHandle<Key, Data> = handle {
            lock.lock()
            map.removeValue(forKey: handle.key)
        } else { // あり得ないけど念のため
            lock.lock()
            if let index = map.firstIndex(where: { $0.value === handle }) {
                map.remove(at: index)
            } else {
                fatalError() // 完全なロジックエラー
            }
        }
        lock.unlock()
    }
    /// キャッシュの全消去の準備
    fileprivate final func prepareClearAllCache() {
        lock.lock()
        map.removeAll()
    }
    /// キャッシュの全消去完了時の処理
    fileprivate final func completeClearAllCache() {
        lock.unlock()
    }
    /// 無効なデータを削除して対応するハンドルを返す
    fileprivate func removeInvalidCache() -> [CacheHandle] { [] }
}

/// DB検索を管理するオブジェクト。複数の同じ検索の待ち合わせに使用する
fileprivate class SearchResult<R: DMCacheElement>: NSLock {
    override init() {
        super.init()
        self.lock() // 初期化時にロックし書き込み待ちとする
    }
    private var data: Result<R, Error>!
    
    /// 書き込みがあるまで読込はブロックされる
    var result: Result<R, Error> {
        get {
            self.lock()
            defer { self.unlock() }
            return data
        }
        set {
            data = newValue
            self.unlock() // ロック解除
        }
    }
}

// MARK: - 変換キャッシュ
public struct DMResultCacheResult<R2: DMCacheElement>: BasicCacheResult {
    
    let data: Result<R2, Error>
    
    public init(_ data: R2) { self.data = .success(data) }
    public init(_ error: Error) { self.data = .failure(error) }
    
    public func get() throws -> R2 {
        return try data.get()
    }
}

/// 変換エラーのない変換キャッシュ
public final class DMCachingConverter<Key: DMCacheKey, R: DMCacheElement>: BasicCacheStorage<Key, DMResultCacheResult<R>, R> {
    // MARK: - 固有外部インターフェース
    public func convert(_ keySource: Key) -> R {
        return try! basic_convert(forceUpdate: false, forKey: keySource)
    }
}

/// 変換エラーも記録する変換キャッシュ
public final class DMCachingTtyConverter<Key: DMCacheKey, R: DMCacheElement>: BasicCacheStorage<Key, DMResultCacheResult<R>, R> {
    // MARK: - 固有外部インターフェース
    /// 指定されたパラメータで検索を行う
    public func convert(_ keySource: Key) throws -> R {
        return try basic_convert(forceUpdate: false, forKey: keySource)
    }
}

// MARK: - DBキャッシュ
public struct DMDBCacheData<R: DMCacheElement>: BasicCacheResult {
    var date: Date
    let data: Result<R, Error>
    
    public init(_ data: R) {
        self.data = .success(data)
        self.date = Date()
    }

    public init(_ error: Error) {
        self.data = .failure(error)
        self.date = Date()
    }

    public func get() throws -> R {
        return try data.get()
    }
}

/// DB結果についてキャッシュ
public class DMDBCache<Key: DMCacheKey, R: DMCacheElement>: BasicCacheStorage<Key, DMDBCacheData<R?>, R?> {
    /// キャッシュの寿命
    var lifeTime: TimeInterval
    /// falseなら結果がniの場合キャッシュせず毎回検索する
    private let nilCache: Bool

    // MARK: - 固有外部インターフェース
    /// キャッシュの有効期限と検索関数を元に初期化する
    public init(lifeTime: TimeInterval = 60, nilCache: Bool, isDebug: Bool = false, _ converter: @escaping (Key) throws -> R?) {
        self.nilCache = nilCache
        switch dbCachingMode {
        case .dynamic:
            self.lifeTime = lifeTime // 通常の寿命
        case .static:
            self.lifeTime = max(lifeTime, 24 * 60 * 60) // 最低24時間の寿命
        }
        super.init(converter)
        self.isDebug = isDebug
    }

    /// 検索結果を登録する
    public final func regist(_ object: R?, forKey key: Key) {
        let cache = DMDBCacheData(object)
        lock.lock(); defer { lock.unlock() }
        if let handle = map[key] {
            handle.result = cache
            DMCacheSystem.shared.touch(handle: handle) // ハンドル再利用
        } else {
            let handle = KeyResultCacheHandle(map: self, memoryFootPrint: object.memoryFootPrint, key: key, result: cache)
            map[key] = handle
            DMCacheSystem.shared.append(handle: handle) // ハンドル新規登録
        }
    }

    /// 指定のkeyに対して、キャッシュしていればtrueを返す
    public final func isCaching(forKey key: Key) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return map[key] != nil || working[key] != nil
    }

    /// 指定されたキャッシュの寿命を変更する
    public final func changeExpire(_ maxExpire: TimeInterval, forKey key: Key) {
        lock.lock(); defer { lock.unlock() }
        guard let handle = map[key] else { return }
        handle.result.date = handle.result.date.addingTimeInterval(self.lifeTime - maxExpire)
        DMCacheSystem.shared.touch(handle: handle)
    }

    /// 指定されたパラメータで検索を行う
    public final func find(_ keySource: Key, noCache: Bool = false) throws -> R? {
        return try basic_convert(forceUpdate: noCache, forKey: keySource)
    }
    
    // MARK: - 内部データ処理インターフェース
    fileprivate override func basic_validate(_ data: DMDBCacheData<R?>) -> Bool {
        return Date() < data.date.addingTimeInterval(self.lifeTime) // 有効期限内
    }
    
    fileprivate override func basic_lock_regist(_ data: R?, forKey key: Key) {
        if data != nil || self.nilCache {
            super.basic_lock_regist(data, forKey: key)
        } else {
            lock.lock()
        }
    }

    fileprivate override func basic_lock_recovery(_ error: Error, forKey key: Key) throws -> R? {
        switch error {
        case FileMakerError.invalidRecord:
            super.basic_lock_regist(nil, forKey: key)
            return nil
        default:
            lock.lock()
            throw error
        }
    }

    // MARK: DMCacheSystemからの内部操作インターフェース
    /// 保有するキャッシュのうち、有効期限を切れたものを削除し、ハンドルを返す
    fileprivate final override func removeInvalidCache() -> [CacheHandle] {
        var handles: [CacheHandle] = []
        lock.lock(); defer { lock.unlock() }
        let expire = Date(timeIntervalSinceNow: lifeTime)
        for (key, handle) in map where handle.result.date > expire {
            map.removeValue(forKey: key)
            handle.storage = nil
            handles.append(handle)
        }
        return handles
    }
}

// MARK: - キャッシュ要素
/// メモリの使用量を返す
public protocol DMCacheElement {
    /// メモリの使用量
    var memoryFootPrint: Int { get }
}
extension String: DMCacheElement {
    public var memoryFootPrint: Int { return max(self.utf8.count, 16) }
}
extension Optional: DMCacheElement where Wrapped: DMCacheElement {
    public var memoryFootPrint: Int { self?.memoryFootPrint ?? 8 }
}
extension Int: DMCacheElement {
    public var memoryFootPrint: Int { return MemoryLayout<Int>.stride }
}
extension Double: DMCacheElement {
    public var memoryFootPrint: Int { return MemoryLayout<Double>.stride }
}
extension UUID: DMCacheElement {
    public var memoryFootPrint: Int { return MemoryLayout<UUID>.stride }
}
extension Date: DMCacheElement {
    public var memoryFootPrint: Int { return MemoryLayout<Date>.stride }
}
