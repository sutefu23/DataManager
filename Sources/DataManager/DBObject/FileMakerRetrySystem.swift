//
//  FileMakerRetrySystem.swift
//  DataManager
//
//  Created by manager on 2021/09/28.
//

import Foundation

/// リトライシステム。サーバー停止などの際に出力を記録しておいて後日再出力する
public class FileMakerRetrySystem: DMLogger {
    public static let shared = FileMakerRetrySystem()
    
    static var filename: String { "Retry-\(defaults.programName).json" }
    static var retryURL: URL { get throws { try applicationSupportURL.appendingPathComponent(filename) } }
    
    private let lock = NSRecursiveLock()
    private var retryList: [FileMakerCommand] = []
    private var isLoaded = false
    private var needsSave = false

    private init() {}
    
    public func load() throws {
        lock.lock(); defer { lock.unlock() }
        do {
            guard self.isLoaded == false else { return }
            let url = try Self.retryURL
            if !url.isExists {
                self.log("リトライデータ読み込みなし", level: .information)
                self.isLoaded = true
                return
            }
            self.log("リトライデータ読み込み開始", level: .information)
            let data = try Data(contentsOf: url)
            let newList = try JSONDecoder().decode([FileMakerCommand].self, from: data)
            if !newList.isEmpty {
                self.retryList = newList + self.retryList
                needsSave = true
            }
            self.isLoaded = true
            self.log("リトライデータ読み込み完了[\(newList.count)件]", level: .information)
        } catch {
            self.log("リトライデータ読み込み失敗", detail: error.localizedDescription, level: .critical)
            throw error
        }
    }
    
    public func save() throws {
        lock.lock(); defer { lock.unlock() }

        guard self.needsSave else { return }
        do {
            self.log("リトライデータ保存開始", level: .information)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self.retryList)
            let url = try Self.retryURL
            try data.write(to: url)
            self.needsSave = false
            self.log("リトライデータ保存完了", level: .information)
        } catch {
            self.log("リトライデータ保存失敗", detail: error.localizedDescription, level: .critical)
            throw error
        }
    }

    /// リトライリストに出力内容を設定する
    func append(_ command: FileMakerCommand) {
        // テストサーバーのリトライは禁止(名前がpm_osakanameでメインサーバーと区別できない)
        if command.db === FileMakerDB.pm_osakaname2 { return }
        lock.lock(); defer { lock.unlock() }
        retryList.append(command)
        self.needsSave = true
    }
    
    /// リトライするものがなければtrue
    public var isEmpty: Bool {
        lock.lock(); defer { lock.unlock() }
        return retryList.isEmpty
    }
    
    /// 古いものから順にリトライする。エラーが出たらそこで止まる
    public func retry() throws {
        lock.lock(); defer { lock.unlock() }
        try load() // 読み込まれていないものがある場合、そちらが優先
        defer { try? self.save() } // 都度保存する
        while let target = retryList.first {
            guard try target.execute() else { return }
            retryList.removeFirst()
            self.needsSave = true
        }
    }
}
