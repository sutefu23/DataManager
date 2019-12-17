//
//  伝票番号.swift
//  DataManager
//
//  Created by 四熊泰之 on 9/29/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

private var lock = NSLock()

/// 存在確認された伝票の伝票番号
private var testCache: Set<Int> = Set<Int>()

func clear伝票番号Cache() {
    lock.lock()
    testCache.removeAll()
    lock.unlock()
}

public struct 伝票番号型 : Hashable, Comparable, CustomStringConvertible {
    public let 整数値 : Int
    
    public init(validNumber:Int) {
        self.整数値 = validNumber
    }

    public init?<S: StringProtocol>(invalidString:S) throws {
        guard let number = Int(invalidString) else { return nil }
        try self.init(invalidNumber:number)
    }
    
    public init?(invalidNumber:Int) throws {
        if !伝票番号型.isValidNumber(invalidNumber) { return nil }
        self.整数値 = invalidNumber
        if try testIsValid() == false { return nil }
    }
    
    public func testIsValid() throws -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        if testCache.contains(self.整数値) { return true }
        let orders = try 指示書型.find(伝票番号: self)
        if orders.isEmpty == false {
            testCache.insert(self.整数値)
            return true
        } else {
            return false
        }
    }
    
    // MARK: -
    public static func isValidNumber(_ number:Int) -> Bool {
        return number >= 10_0000 && number <= 9999_99999
    }
    public static func isValidNumber(_ number:String) -> Bool {
        guard let number = Int(number) else { return false }
        return isValidNumber(number)
//        return number >= 10_0000 && number <= 9999_99999
    }

    
    // MARK: - Comparable
    public static func <(left:伝票番号型, right:伝票番号型) -> Bool {
        if left.上位整数値 != right.上位整数値 {
            return left.上位整数値 < right.上位整数値
        } else {
            return left.下位整数値 < right.下位整数値
        }
    }

    // MARK: - パーツ
    public var 上位整数値 : Int {
        return 整数値 > 9999_9999 ? 整数値 / 1000_00 : 整数値 / 100_00
    }

    public var 下位整数値 : Int {
        return 整数値 > 9999_9999 ? 整数値 % 1000_00 : 整数値 % 100_00
    }
    
    public var 年値 : Int { 2000 + 上位整数値 / 100 }
    public var 月値 : Int { 上位整数値 % 100 }
    
    /// 表示用伝票番号文字列
    public var 表示用文字列 : String {
        return "\(上位整数値)-\(下位整数値)"
    }
    
    // MARK: - CutomString
    public var description: String {
        return String(self.整数値)
    }
    
    public func showInfo() {
        guard let url = URL(string: "fmp://outsideuser:outsideuser!@192.168.1.153/viewer?script=search&param=\(self)") else { return }
        #if os(macOS)
        let ws = NSWorkspace.shared
        ws.open(url)
        #elseif os(iOS)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #else
        
        #endif
    }

}
