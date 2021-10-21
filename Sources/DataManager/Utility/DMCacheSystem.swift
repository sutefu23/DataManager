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

    // プラットフォームごとのキャッシュのデフォルト使用率（仮想メモリの有無で変える）
    #if os(macOS) || os(Windows) || os(Linux) || targetEnvironment(macCatalyst)
    static let defaultCaheRate = 30 // 仮想メモリあり
    #else
    static let defaultCaheRate = 20 // 仮想メモリなし
    #endif

    public static func calcMaxCacheBytes(for rate: Int? = nil) -> Int {
        let rate = rate ?? defaults.maxCacheRate
        return (Int(ProcessInfo.processInfo.physicalMemory) * rate) / 100
    }
    /// キャッシュとして必要な最小容量
    static let minMB = 256
    /// キャッシュのリスト
    private var storageList: [CacheStorage] = []
    /// リスト追加用のロック
    private let lock = NSLock()
    /// ガーベッジコレクション周期
    private let flushInterval: TimeInterval = 2.0 // 平均１秒で処理
    
    // MARK: ハンドルリスト（先頭が古い）
    /// ハンドル操作用のqueue
    fileprivate let queue = DispatchQueue(label: "cacheSystem.ncengine", qos: .utility)
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
    fileprivate func removeCache(_ storage: CacheStorage, handles: [CacheHandle] = []) {
        // キャッシュシステム削除
        lock.lock(); defer { lock.unlock() }
        if let index = storageList.firstIndex(where: { $0 === storage }) {
            storageList.remove(at: index)
        }
        // ハンドル処理
        if handles.isEmpty { return }
        queue.sync() { // syncが始まる時点でstorageへのアクセスは全て終了している
            handles.forEach { $0.storage = nil } // 最低限の作業
            self.remove(handles: handles) // 重い処理は後に回す
        }
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
            self.execTouch(handle: handle, reuse: false)
        }
    }

    /// 登録済みのハンドルが利用済みなら最新にし、未登録ならリストに追加する
    fileprivate func reuse(handle: CacheHandle) {
        queue.async {
            self.execTouch(handle: handle, reuse: true)
        }
    }

    /// 指定されたハンドルの登録を非同期で解除する
    fileprivate func remove(handle: CacheHandle) {
        queue.async {
            self.execRemoveHandle(handle: handle)
        }
    }

    /// 指定された複数ハンドルの登録を非同期で解除する
    fileprivate func remove(handles: [CacheHandle]) {
        if handles.isEmpty { return }
        queue.async {
            handles.forEach { self.execRemoveHandle(handle: $0) }
        }
    }

    // MARK: - serialqueue上で実行
    /// 最大キャッシュ容量を変更する
    private func execChangeMaxByte(maxBytes: Int) {
        guard maxBytes > 0 else { return }
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
    
    /// 無効なキャッシュを削除する(ためのガーベッジコレクタ起動)
    private func execRemoveInvalidCache() {
        if let diff = self.prevFlushDate?.timeIntervalSinceNow, diff > -self.flushInterval { return } // flushInterval秒以内に実行済みなら何もしない
        lock.lock()
        self.storageList.forEach { $0.removeInvalidCache() }
        lock.unlock()
        self.prevFlushDate = Date() // 完了時刻を記録
    }
    private var prevFlushDate: Date? = nil

    /// メモリの使用量を指定されたサイズまで削減する
    private func execClearLimit(limit: Int) {
        self.execRemoveInvalidCache() // まずは無効なキャッシュを削除する
        if currentBytesData <= limit { return }
        while let handle = self.firstHandle {
            if let storage = handle.storage {
                storage.removeHandle(for: handle)
                handle.storage = nil
            }
            self.firstHandle = handle.next
            handle.prev = nil // メモリリーク対策
            handle.next = nil
            self.currentBytesData -= handle.memoryFootPrint
            if currentBytesData <= limit { break }
        }
        if let firstHandle = self.firstHandle {
            firstHandle.prev = nil
        } else {
            lastHandle = nil
        }
    }

    /// 指定されたハンドルを削除する
    private func execRemoveHandle(handle: CacheHandle) {
        handle.storage = nil
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
    private func execTouch(handle: CacheHandle, reuse: Bool) {
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
            // 再利用不可なら何もしない
            if reuse == false { return }
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
    /// 無効なデータを削除する
    func removeInvalidCache()
    /// キャッシュサブシステムの停止
    func terminate()
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
    /// 保持するデータの型
    associatedtype R2
    /// データで初期化
    init(_ data: R2)
    /// エラーで初期化
    init(_ error: Error)

    /// データを取り出す
    func get() throws -> R2
}

/// キャッシュのキーのインターフェース
public typealias DMCacheKey = DMCacheElement & Hashable & CustomStringConvertible

/// 基本的なキャッシュの基礎
public class BasicCacheStorage<Key: DMCacheKey, Data: BasicCacheResult, R2: DMCacheElement>: CacheStorage where Data.R2 == R2 {
    fileprivate typealias MapData = KeyResultCacheHandle<Key, Data>
    
    /// 管理用ロック
    fileprivate let lock: NSLock
    /// 変換関数
    fileprivate let converter: (Key) throws -> R2
    /// キャッシュデータ
    fileprivate var map: [Key: MapData]
    /// 作業中データ
    fileprivate var working: [Key: WorkingResult<R2>]

    // MARK: - 汎用インターフェース
    public var isDebug: Bool
    
    public init(_ converter: @escaping (Key) throws -> R2) {
        self.converter = converter
        self.map = [:]
        self.working = [:]
        self.isDebug = false
        self.lock = NSLock()
        DMCacheSystem.shared.appendCache(self) // これがあるためdeinitが不要。terminateでオブジェクト廃棄となる
    }
    /// キャッシュサブシステムの停止
    public func terminate() {
        lock.lock(); defer { lock.unlock() }
        // 実行中のworkが終わるまで待つ
        while !working.isEmpty {
            self.working.forEach { let _ = try? $0.value.result.get() }
            self.working.removeAll()
            lock.unlock(); lock.lock() // 追加の隙を与える
        }
        // ハンドルを消去する
        let handles = [MapData](map.values)
        DMCacheSystem.shared.removeCache(self, handles: handles)
        // キャッシュを消去する
        self.map.removeAll()
    }
    
    // MARK: - 共有外部インターフェース
    /// 外部で計算したキャッシュデータを登録する
    public final func regist(_ object: R2, forKey key: Key) {
        let cache = Data(object)
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

    /// 全クリア
    public final func removeAllCache() {
        lock.lock(); defer { lock.unlock() }
        DMCacheSystem.shared.remove(handles: [MapData](map.values))
        map.removeAll()
    }
    /// 指定されたキーに対応するキャッシュを消去する
    public final func removeCache(forKey keySource: Key) {
        lock.lock(); defer { lock.unlock() }
        guard let handle = map.removeValue(forKey: keySource) else { return }
        DMCacheSystem.shared.remove(handle: handle)
    }

    // MARK: - 内部インターフェース
    /// クラス名文字列(デバッグ用)
    final var name: String { return classNameBody(of: self) }

    /// 指定されたキーのデータを更新する。キーに対応するデーターがない場合何もしない
    final func basic_update(forKey key: Key, updator: (inout Data) -> Void) {
        lock.lock(); defer { lock.unlock() }
        guard let handle = map[key] else { return }
        updator(&handle.result)
        DMCacheSystem.shared.touch(handle: handle)
    }
    
    /// キャッシュ変換を行う
    final func basic_convert(forceUpdate: Bool, forKey key: Key) throws -> R2 {
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
        // 新規計算を予約する
        let result = WorkingResult<R2>()
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
            return data // 正常終了
        } catch { // エラー時はリカバリを試み、失敗した場合エラーを登録する
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
            #if DEBUG
            if isDebug { DMLogSystem.shared.debugLog("古キャッシュ廃棄[\(name)]", detail: handle.key.description, level: .debug) }
            #endif
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
    /// 無効なデータを削除する
    fileprivate func removeInvalidCache() { }
}

/// 計算中のデータ。複数のスレッドが計算終了を待つための待ち合わせに使う
fileprivate class WorkingResult<R: DMCacheElement>: NSLock {
    override init() {
        super.init()
        self.lock() // 初期化時にロックし書き込み待ちとする
    }
    /// 　計算結果となるデータ又はエラー
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
    /// データ本体 or エラー
    private let data: Result<R2, Error>
    
    public init(_ data: R2) { self.data = .success(data) }
    public init(_ error: Error) { self.data = .failure(error) }
    
    public func get() throws -> R2 {
        return try data.get()
    }
}

/// 変換エラーのない変換キャッシュ
public class DMCachingConverter<Key: DMCacheKey, R: DMCacheElement>: BasicCacheStorage<Key, DMResultCacheResult<R>, R> {
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
    /// データ登録日時
    fileprivate var date: Date
    /// データ本体 or エラー
    private let data: Result<R, Error>
    
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
    /// キャッシュの寿命。変更すると既存のキャッシュの寿命も同じだけ変化する
    var lifeSpan: TimeInterval
    /// falseなら結果がniの場合キャッシュせず毎回検索する
    private let nilCache: Bool

    // MARK: - 固有外部インターフェース
    /// キャッシュの有効期限と検索関数を元に初期化する
    public init(lifeSpan: TimeInterval = 60, nilCache: Bool, isDebug: Bool = false, _ converter: @escaping (Key) throws -> R?) {
        self.nilCache = nilCache
        switch dbCachingMode {
        case .dynamic:
            self.lifeSpan = lifeSpan // 通常の寿命
        case .static:
            self.lifeSpan = max(lifeSpan, 24 * 60 * 60) // 最低24時間の寿命
        }
        super.init(converter)
        self.isDebug = isDebug
    }

    /// 指定されたキャッシュの寿命を変更する
    public final func updateLifeSpan(_ newLifeSpan: TimeInterval? = nil, forKey key: Key) {
        self.basic_update(forKey: key) {
            if let newLifeSpan = newLifeSpan {
                $0.date = Date(timeIntervalSinceNow: newLifeSpan - self.lifeSpan)
            } else {
                $0.date = Date()
            }
        }
    }

    /// 指定されたキャッシュの寿命の最大値を指定する
    public final func limitLifeSpan(_ maxLifeSpan: TimeInterval, forKey key: Key) {
        self.basic_update(forKey: key) {
            let maxDate = Date(timeIntervalSinceNow: maxLifeSpan - self.lifeSpan)
            if $0.date > maxDate {
                $0.date = maxDate
            }
        }
    }

    /// 指定されたパラメータで検索を行う
    public func find(_ keySource: Key, noCache: Bool = false) throws -> R? {
        return try basic_convert(forceUpdate: noCache, forKey: keySource)
    }
    
    // MARK: - 内部データ処理インターフェース
    fileprivate override func basic_validate(_ data: DMDBCacheData<R?>) -> Bool {
        return Date() < data.date.addingTimeInterval(self.lifeSpan) // 有効期限内
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
        case FileMakerError.invalidRecord: // データ破損はnil（データなし）とする
            super.basic_lock_regist(nil, forKey: key)
            return nil
        default: // それ以外はキャッシュせずにエラーを返し、同じリクエスト発生時に再度アクセスを試みる
            lock.lock()
            throw error
        }
    }

    /// クリーニング中ならtrue
    private var isCleaning: Bool = false
    /// ガーベッジコレクタ起動
    private func startCleaning() {
        lock.lock(); defer { lock.unlock() }
        if isCleaning || self.map.isEmpty { return }
        self.isCleaning = true
        DispatchQueue.global(qos: .background).async {
            self.execCleaning()
        }
    }
    /// ガーベッジコレクタ実行（バックグラウンド）
    private func execCleaning() {
        // データ準備
        lock.lock()
        let lifeSpan = self.lifeSpan
        let checkMap = self.map
        lock.unlock()
        // チェック
        let expireBorder = Date(timeIntervalSinceNow: -lifeSpan) // 有効期限切れとなる登録日時
        var invalidHandles: [MapData] = checkMap.values.filter { $0.result.date < expireBorder } // 有効期限切れを削除
        // チェック結果適用
        lock.lock(); defer { self.isCleaning = false; lock.unlock() }
        invalidHandles = invalidHandles.filter {
            guard map[$0.key] === $0 && $0.result.date < expireBorder else { return false } // 更新されておらず、再チェックでも無効なまま
            map[$0.key] = nil
            return true
        }
        DMCacheSystem.shared.remove(handles: invalidHandles)
    }
    
    // MARK: DMCacheSystemからの内部操作インターフェース
    /// 無効なデータを削除する
    fileprivate final override func removeInvalidCache() {
        self.startCleaning() // バックグラウンドで削除する
    }
}

// MARK: - lightweightキャッシュ（ハンドル操作はしない）
public enum DMCacheState {
    /// 未登録
    case noCheck
    /// 登録済みでキャッシュのクリア時に消去される
    case registered
    /// 登録済みで、キャッシュのクリア時に消去されない
    case permanent
}
/// lightweightキャッシュ対象オブジェクト
public protocol DMLightWeightObjectProtocol: DMLightWeightObject, Hashable {
    /// データの保存場所
    static var cache: LightWeightStorage<Self> { get }
}
public extension DMLightWeightObjectProtocol {
    /// 登録されたオブジェクトを返す
    func regist() -> Self {
        return Self.cache.regist(self)
    }
    /// 永続データとして登録されたオブジェクトを返す
    func registPermanent() -> Self {
        return Self.cache.registPermanent(self)
    }
}

open class DMLightWeightObject {
    public init() {}
    public internal(set) var isRegistered: DMCacheState = .noCheck
}

/// lightweightキャッシュ（ハンドル操作はせずパージ通知のみ利用する）
public class LightWeightStorage<Object: DMLightWeightObjectProtocol>: CacheStorage {
    /// 個別キャッシュデータの操作インターフェース + キャッシュデータ
    private class WeakKeyObject {
        let key: Int
        weak var object: Object? // 制約:読み書きはlock内でのみ行う
        
        init(map: CacheStorage, object: Object, key: Int) {
            self.key = key
            self.object = object
        }
    }
    /// 管理用ロック
    private let lock = NSLock()
    /// キャッシュデータ
    private var map: [Int: [WeakKeyObject]] = [:]

    public init() {
        DMCacheSystem.shared.appendCache(self)
    }
    /// キャッシュサブシステムの停止
    public func terminate() {
        DMCacheSystem.shared.removeCache(self)
        lock.lock(); lock.unlock()
        self.map.removeAll()
    }
    /// 有効なデータ数
    public var count: Int {
        self.startRemoveInvalidCache()
        cleaningGroup.wait()
        lock.lock(); defer { lock.unlock() }
        return map.reduce(0) { $0 + $1.value.count }
    }
    
    // MARK: - 共有外部インターフェース
    /// 外部で計算したキャッシュデータを登録する
    public final func regist(_ object: Object) -> Object {
        lock.lock(); defer { lock.unlock() }
        return self.execRegist(object)
    }

    public final func registPermanent(_ object: Object) -> Object {
        lock.lock(); defer { lock.unlock() }
        switch object.isRegistered {
        case .permanent:
            return object
        case .registered:
            object.isRegistered = .permanent
            return object
        case .noCheck:
            let object = self.execRegist(object)
            object.isRegistered = .permanent
            return object
        }
    }
    /// 全クリア
    public final func removeAllCache() {
        lock.lock(); defer { lock.unlock() }
        self.execRemoveAllCache()
    }

    /// 無効なキャッシュデータを削除する
    public func cleanUp() {
        lock.lock(); defer { lock.unlock() }
        self.startRemoveInvalidCache()
    }
    
    // MARK: - 内部コール
    private func execRegist(_ object: Object) -> Object {
        guard object.isRegistered == .noCheck else { return object }
        let key = object.hashValue
        if let list = map[key] {
            for handle in list {
                if let target = handle.object, target == object {
                    return target
                }
            }
            object.isRegistered = .registered
            let handle = WeakKeyObject(map: self, object: object, key: key)
            map[key] = list + [handle]
        } else {
            object.isRegistered = .registered
            let handle = WeakKeyObject(map: self, object: object, key: key)
            map[key] = [handle]
        }
        return object
    }

    private func execRemoveAllCache() {
        guard !isCleaning else { return }
        var nextMap: [Int: [WeakKeyObject]] = [:]
        map.forEach {
            let newList = $0.value.filter {
                guard let object = $0.object else { return false }
                switch object.isRegistered {
                case .registered:
                    object.isRegistered = .noCheck
                    return false
                case .noCheck:
                    return false
                case .permanent:
                    return true
                }
            }
            if !newList.isEmpty {
                nextMap[$0.key] = newList
            }
        }
        map = nextMap
    }

    private let cleaningGroup = DispatchGroup()
    private var isCleaning: Bool = false
    /// ガーベッジコレクタ起動
    private func startRemoveInvalidCache() {
        lock.lock(); defer { lock.unlock() }
        if isCleaning || map.isEmpty { return } // 既にクリーニング中か対象が空なら何もしない
        self.isCleaning = true
        DispatchQueue.global(qos: .background).async(group: self.cleaningGroup) {
            self.execRemoveInvalidCache()
        }
    }
    /// ガーベッジコレクタ実行（バックグラウンド）
    private func execRemoveInvalidCache() {
        // データ準備
        lock.lock()
        let testMap = self.map
        lock.unlock()
        // チェック
        let checkKeys: [Int] = testMap.compactMap { return $0.value.contains{ $0.object == nil} ? $0.key : nil }
        // チェック結果の適用
        lock.lock(); defer { self.isCleaning = false; lock.unlock() }
        for key in checkKeys {
            guard let list = self.map[key] else { continue }
            let newList = list.filter { $0.object != nil }
            self.map[key] = newList.isEmpty ? nil : newList
        }
    }
    
    // MARK: DMCacheSystemからの内部操作インターフェース
    /// ハンドルに対応するキャッシュをパージする
    fileprivate final func removeHandle(for handle: CacheHandle) {}
    /// キャッシュの全消去の準備
    fileprivate final func prepareClearAllCache() {
        self.startRemoveInvalidCache() // lightWeighの性質上、無効なもののみ消去で良い
    }
    /// キャッシュの全消去完了時の処理
    fileprivate final func completeClearAllCache() {
    }
    
    /// 無効なデータを削除する
    fileprivate func removeInvalidCache() {
        self.startRemoveInvalidCache()
    }
}

// MARK: - キャッシュ要素
/// メモリの使用量を返す
public protocol DMCacheElement {
    /// メモリの使用量
    var memoryFootPrint: Int { get }
}

extension DMCacheElement {
    public var memoryFootPrint: Int { MemoryLayout<Self>.stride }
}
// 個別のメモリ量設定
extension String: DMCacheElement {
    public var memoryFootPrint: Int { return max(self.utf8.count, MemoryLayout<String>.size) }
}
extension Optional: DMCacheElement where Wrapped: DMCacheElement {
    public var memoryFootPrint: Int {
        let base = MemoryLayout<Self>.stride
        guard let data = self?.memoryFootPrint else { return base }
        return max(base, data)
    }
}
extension Int: DMCacheElement {}
extension Int32: DMCacheElement {}
extension Int16: DMCacheElement {}
extension Int8: DMCacheElement {}
extension Double: DMCacheElement {}
extension UUID: DMCacheElement {}
extension Date: DMCacheElement {}

extension Array: DMCacheElement where Element: DMCacheElement {
    public var memoryFootPrint: Int { return reduce(MemoryLayout<Self>.size) { $0 + $1.memoryFootPrint }}
}
