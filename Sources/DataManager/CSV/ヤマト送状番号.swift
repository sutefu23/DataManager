//
//  ヤマト送状番号.swift
//  DataManager
//
//  Created by manager on 2021/07/12.
//

import Foundation

let 親伝票番号一覧: ClosedRange<Int> = 2998_6850_900 ... 2998_6863_899
let 子伝票番号一覧: ClosedRange<Int> = 2723_9844_000 ... 2723_9845_199

extension UserDefaults {
    /// 次回採番予定の親伝票番号（チェックディジットを除外したもの）
    public var ヤマト親伝票元番号: Int {
        get { self.integer(forKey: "YamatoMasterOrderNumber") }
        set {
            guard 親伝票番号一覧.contains(newValue) else { return }
            self.setValue(newValue, forKey: "YamatoMasterOrderNumber")
        }
    }
    /// 次回採番予定の子伝票番号（チェックディジットを除外したもの）
    public var ヤマト子伝票元番号: Int {
        get { self.integer(forKey: "YamatoChilOrderNumber") }
        set {
            guard 子伝票番号一覧.contains(newValue) else { return }
            self.setValue(newValue, forKey: "YamatoChilOrderNumber")
        }
    }
}

extension Int {
    func makeヤマト送り状番号() -> String {
        return "\(self)\(self % 7)"
    }
}

public class ヤマト送状管理システム型 {
    public static let shared: ヤマト送状管理システム型 = ヤマト送状管理システム型()

    private let lock = NSLock()
    private var savedState: (親伝票番号: Int, 子伝票番号: Int)? = nil

    public func isValid() -> Bool {
        return 親伝票番号一覧.contains(defaults.ヤマト親伝票元番号) && 子伝票番号一覧.contains(defaults.ヤマト子伝票元番号)
    }

    /// 登録済み送状番号
    private var ngNumber = Set<Int>()
    
    init() {
        self.registNGNumbers()
    }

    public func registNGNumbers() {
        let day = Day().prev(month: 2) // 過去2ヶ月に登録　
        guard let orders = try? 送状型.find最近登録(基準登録日: day, 運送会社: .ヤマト) else { return }
        for order in orders {
            guard let number = order.送り状番号.ヤマト送状元番号 else { continue }
            ngNumber.insert(number)
        }
    }
    
    /// 親伝票番号採番
    public func 送状番号割り当て() -> String? {
        lock.lock()
        var value = defaults.ヤマト親伝票元番号
        guard 親伝票番号一覧.contains(value) else { return nil }
        while ngNumber.contains(value) {
            value = 親伝票番号一覧.contains(value+1) ? value+1 : 親伝票番号一覧.lowerBound
        }
        defaults.ヤマト親伝票元番号 = 親伝票番号一覧.contains(value+1) ? value+1 : 親伝票番号一覧.lowerBound
        lock.unlock()
        return value.makeヤマト送り状番号()
    }

    /// 子伝票番号採番
    func 子伝票番号割り当て() -> String? {
        lock.lock()
        var value = defaults.ヤマト子伝票元番号
        guard 子伝票番号一覧.contains(value) else { return nil }
        while ngNumber.contains(value) {
            value = 子伝票番号一覧.contains(value+1) ? value+1 : 子伝票番号一覧.lowerBound
        }
        defaults.ヤマト子伝票元番号 = 子伝票番号一覧.contains(value+1) ? value+1 : 子伝票番号一覧.lowerBound
        lock.unlock()
        return value.makeヤマト送り状番号()
    }

    public func saveState() {
        lock.lock(); defer { lock.unlock()}
        self.savedState = (defaults.ヤマト親伝票元番号, defaults.ヤマト子伝票元番号)
    }
    
    public func rollBack() {
        lock.lock(); defer { lock.unlock()}
        guard let state = self.savedState else { return }
        defaults.ヤマト親伝票元番号 = state.親伝票番号
        defaults.ヤマト子伝票元番号 = state.子伝票番号
        self.savedState = nil
    }
}

extension 送状型 {
    /// 送り状番号が設定されていない場合、仮で採番する
    public func ヤマト送り状番号仮割り当て() throws {
        guard self.送り状番号.状態 == .処理待ち && self.運送会社 == .ヤマト,
              let number = ヤマト送状管理システム型.shared.送状番号割り当て() else { return }
        self.送り状番号 = 送り状番号型(状態: .仮設定, 送り状番号: number)
        try self.upload送状番号()
    }
    
    ///送り状番号を印刷済みにする
    public func ヤマト送り状番号印刷設定() throws {
        guard self.送り状番号.状態 == .仮設定 && self.運送会社 == .ヤマト, let number = self.送り状番号.送り状番号 else { return }
        self.送り状番号 = 送り状番号型(状態: .仮番号印刷済み, 送り状番号: number)
        try self.upload送状番号()
    }
    
}
