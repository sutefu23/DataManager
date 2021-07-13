//
//  ヤマト送状番号.swift
//  DataManager
//
//  Created by manager on 2021/07/12.
//

import Foundation

extension UserDefaults {
    var ヤマト送状元番号割り当て済みブロック: [ClosedRange<ヤマト送状元番号型>] {
        get {
            self.json(forKey: "YamatoNumberManagerComplete") ?? []
        }
        set {
            self.setJson(object: newValue, forKey: "YamatoNumberManagerComplete")
        }
    }
    var ヤマト送状元番号割り当て待ちブロック: [ClosedRange<ヤマト送状元番号型>] {
        get {
            self.json(forKey: "YamatoNumberManagerReserved") ?? []
        }
        set {
            self.setJson(object: newValue, forKey: "YamatoNumberManagerReserved")
        }
    }
}

private var queue: DispatchQueue = DispatchQueue(label: "yamatoNumberManager", qos: .utility, attributes: [])

public struct ヤマト送状元番号型: Comparable, Codable {
    let rawValue: Int
    var checkDigits: String { "\(rawValue % 7)" }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static func <(left: ヤマト送状元番号型, right: ヤマト送状元番号型) -> Bool {
        return left.rawValue < right.rawValue
    }
    
    var next: ヤマト送状元番号型 { ヤマト送状元番号型(rawValue: rawValue+1) }
    public var 送状番号: String { return "\(rawValue)\(checkDigits)" }
}

public class ヤマト送状管理システム型: CustomStringConvertible {
    public static let shared: ヤマト送状管理システム型 = ヤマト送状管理システム型()
    
    var 割り当て済みブロック: [ClosedRange<ヤマト送状元番号型>]
    var 割り当て待ちブロック: [ClosedRange<ヤマト送状元番号型>]

    
    var savedState: (割り当て済みブロック: [ClosedRange<ヤマト送状元番号型>], 割り当て待ちブロック: [ClosedRange<ヤマト送状元番号型>])? = nil
    
    init() {
        self.割り当て済みブロック = []
        self.割り当て待ちブロック = []
    }
    
    init(割り当て済みブロック: [ClosedRange<ヤマト送状元番号型>], 割り当て待ちブロック: [ClosedRange<ヤマト送状元番号型>]) {
        self.割り当て済みブロック = defaults.ヤマト送状元番号割り当て済みブロック
        self.割り当て待ちブロック = defaults.ヤマト送状元番号割り当て待ちブロック
    }
    
    func next() -> ヤマト送状元番号型 {
        let range = 割り当て待ちブロック[0]
        let data = range.lowerBound
        if range.lowerBound == range.upperBound {
            割り当て待ちブロック.remove(at: 0)
            if 割り当て待ちブロック.isEmpty {
                割り当て待ちブロック = 割り当て済みブロック
                割り当て済みブロック = []
            }
        } else {
            割り当て待ちブロック[0] = (range.lowerBound.next)...range.upperBound
        }
        if let last = 割り当て済みブロック.last, last.upperBound.next == data {
            割り当て済みブロック[割り当て済みブロック.endIndex-1] = last.lowerBound...data
        } else {
            割り当て済みブロック.append(data...data)
        }
        return data
    }
    
    public func 送状番号割り当て() -> String {
        return next().送状番号
    }
    
    public var description: String {
        func makeStr(_ range: ClosedRange<ヤマト送状元番号型>) -> String {
            return "\(range.lowerBound.送状番号) - \(range.upperBound.送状番号)"
        }
        let str1 = "割当済み:" + 割り当て済みブロック.map { makeStr($0) }.joined(separator: ", ")
        let str2 = "割当待ち:" + 割り当て待ちブロック.map { makeStr($0) }.joined(separator: ", ")
        return "\(str1) \n\(str2)"
    }
    
    public func synchronize() {
        let block1 = self.割り当て済みブロック
        let block2 = self.割り当て待ちブロック
        queue.async {
            defaults.ヤマト送状元番号割り当て済みブロック = block1
            defaults.ヤマト送状元番号割り当て待ちブロック = block2
        }
    }
    
    public func saveState() {
        self.savedState = (self.割り当て済みブロック, self.割り当て待ちブロック)
    }
    
    public func rollBack() {
        guard let state = self.savedState else { return }
        self.割り当て済みブロック = state.割り当て済みブロック
        self.割り当て待ちブロック = state.割り当て待ちブロック
        self.savedState = nil
        self.synchronize()
    }
}
