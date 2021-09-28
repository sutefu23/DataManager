//
//  FileMakerRetrySystem.swift
//  DataManager
//
//  Created by manager on 2021/09/28.
//

import Foundation

/// リトライシステム。サーバー停止などの際に出力を記録しておいて後日再出力する（予定）
public class FileMakerRetrySystem: DMLogger {
    public static let shared = FileMakerRetrySystem()
    
    static let filename = "retryList.json"
    static var retryURL: URL { get throws { try applicationSupportURL.appendingPathComponent(filename) } }
    
    private let lock = NSLock()
    private var retryList: [FileMakerCommand] = []
    private var isLoaded = false
    private var needsSave = false

    public init() {
        self.retryList = []
    }
    
    public func load() throws {
        do {
            guard self.isLoaded == false else { return }
            self.log("リトライデータ読み込み開始", level: .information)
            let url = try Self.retryURL
            if !url.isExists {
                self.isLoaded = true
                return
            }
            let data = try Data(contentsOf: url)
            let newList = try JSONDecoder().decode([FileMakerCommand].self, from: data)
            if !newList.isEmpty { needsSave = true }
            self.retryList = newList + self.retryList
            self.log("リトライデータ読み込み完了", level: .information)
            self.isLoaded = true
        } catch {
            self.log("リトライデータ読み込み失敗", detail: error.localizedDescription, level: .critical)
            throw error
        }
    }
    
    public func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self.retryList)
        let url = try Self.retryURL
        try data.write(to: url)
        self.needsSave = false
    }

    /// リトライリストに出力内容を設定する
    func append(_ retry: FileMakerCommand) {
        lock.lock(); defer { lock.unlock() }
        retryList.append(retry)
        self.needsSave = true
    }
    
    /// リトライするものがなければtrue
    public var isEmpty: Bool {
        lock.lock(); defer { lock.unlock() }
        return retryList.isEmpty
    }
    
    /// 古いものから順にリトライする。エラーが出たらそこで止まる
    func retry() throws {
        lock.lock(); defer { lock.unlock() }
        while let target = retryList.first {
            if try target.execute() {
                retryList.removeFirst()
            } else {
                break
            }
        }
    }
}

