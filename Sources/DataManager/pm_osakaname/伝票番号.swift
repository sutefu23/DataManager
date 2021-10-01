//
//  伝票番号.swift
//  DataManager
//
//  Created by 四熊泰之 on 9/29/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

#if os(macOS)
import Cocoa
#elseif os(Linux) || os(Windows)
import Foundation
#else
import UIKit
#endif

public final class 伝票番号解析型 {
    private var mainNumber: 伝票番号型?
    private var subNumber: 伝票番号型?
    private var mainChecked: Bool
    
    public init<S: StringProtocol>(_ value: S) {
        if let order = 伝票番号型(invalidNumber: value) {
            self.mainNumber = nil
            self.subNumber = order
            self.mainChecked = true
        } else {
            self.mainNumber = nil
            self.subNumber = nil
            self.mainChecked = true
        }
    }
    /// 存在確認済み
    public var 本番号: 伝票番号型? {
        get throws {
            if !mainChecked, let number = subNumber?.整数値 {
                if try 伝票番号キャッシュ型.shared.isExists(number) {
                    mainNumber = subNumber
                }
                mainChecked = true
            }
            return mainNumber
        }
    }
    /// 存在未確認
    public var 仮番号: 伝票番号型? {
        return subNumber
    }
}

public struct 伝票番号型: FileMakerObject, DMCacheKey, Codable, Comparable, ExpressibleByIntegerLiteral {
    public static var db: FileMakerDB { .pm_osakaname }
    public static var layout: String { "DataAPI_10" }

    public let 整数値: Int

    public init?<S: StringProtocol>(invalidNumber: S) {
        guard let number = Int(String(invalidNumber.toHalfCharacters.filter{ $0.isASCIINumber })) else { return nil }
        self.init(invalidNumber: number)
    }
    
    public init?(invalidNumber: Int?) {
        guard let number = invalidNumber else { return nil }
        self.整数値 = number
        guard self.isValidNumber() else { return nil }
    }

    public init(validNumber: Int) {
        self.整数値 = validNumber
    }

    public init(integerLiteral: Int) {
        self.init(validNumber: integerLiteral)
    }
    
    public init?(month: Month, lowNumber: Int) throws {
        if lowNumber <= 0 { return nil }
        let number: Int
        if lowNumber <= 9999 {
            number = (month.shortYear * 100 + month.month) * 10000 + lowNumber
        } else if lowNumber <= 9_9999 {
            number = (month.shortYear * 100 + month.month) * 100000 + lowNumber
        } else {
            number = lowNumber
        }
        guard let result = try 伝票番号キャッシュ型.shared.find(number) else { return nil }
        self = result
    }
    
    public var memoryFootPrint: Int {
        return MemoryLayout<伝票番号型>.stride
    }
    
    // MARK: <Codable>
    enum CodingKeys: String, CodingKey {
        case number
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.整数値 = try values.decode(Int.self, forKey: .number)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.整数値, forKey: .number)
    }
    
    // MARK: -
    func isValidNumber() -> Bool {
        let low = self.下位整数値
        if self.is旧伝票暗号 {
            guard low >= 1 && low <= 999999 else { return false }
        } else {
            guard low >= 1 && low <= 99999 else { return false }
        }
        guard let yearMonth = self.yearMonth else { return false }
        let month = yearMonth.month
        guard month >= 1 && month <= 12 else { return false }
        let year = yearMonth.longYear
        guard year >= 2000 && year <= 2099 else { return false }
        return true
    }

    // MARK: - Comparable
    public static func <(left: 伝票番号型, right: 伝票番号型) -> Bool {
        if left.上位整数値 != right.上位整数値 {
            return left.上位整数値 < right.上位整数値
        } else {
            return left.下位整数値 < right.下位整数値
        }
    }

    // MARK: - パーツ
    public var is旧伝票暗号: Bool { 整数値 <= 999_9999 }
    
    public var 上位整数値: Int {
        if is旧伝票暗号 { return 0 }
        return 整数値 > 9999_9999 ? 整数値 / 1000_00 : 整数値 / 100_00
    }

    public var 下位整数値: Int {
        if is旧伝票暗号 { return 整数値 }
        return 整数値 > 9999_9999 ? 整数値 % 1000_00 : 整数値 % 100_00
    }
    public var 下位文字列: String {
        String(format: "%04d", 下位整数値)
    }
    
    public var yearMonth: Month? {
        guard is旧伝票暗号 else {
            let year = 2000 + 上位整数値 / 100
            let month = 上位整数値 % 100
            return Month(year, month)
        }
        do {
            guard let date = try 指示書型.findDirect(伝票番号: self)?.受注日 else { return nil }
            return Month(date.year, date.month)
        } catch {
            return nil
        }
    }
    
    /// 表示用伝票番号文字列
    public var 表示用文字列: String {
        if is旧伝票暗号 {
            if let month = self.yearMonth?.shortYear2String {
                return "\(month)-\(下位文字列)"
            } else {
                return self.下位文字列
            }
        } else {
            return "\(上位整数値)-\(下位文字列)"
        }
    }
    
    public var 整数文字列: String { String(整数値) }
    
    public var バーコード: String {
        return "*\(整数値)*"
    }
    
    // MARK: - CutomString
    public var description: String {
        return String(self.整数値)
    }
    /// FileMakerで指示書を表示する
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
    
    public init?(validStructured url: URL?) {
        guard var url = url else { return nil }
        if url.isFileURL { url = url.deletingPathExtension() }
        guard let low = Int(url.lastPathComponent), 0 < low && low <= 99999  else { return nil }
        url = url.deletingLastPathComponent()
        guard let middle = Int(url.lastPathComponent), 1 <= middle && middle <= 31 else { return nil }
        url = url.deletingLastPathComponent()
        guard var high = Int(url.lastPathComponent), 2000 <= high && high <= 9999 else { return nil }
        high = (high-2000) * 100 + middle
        let number: Int
        if low < 10000 {
            number = high * 10000 + low
        } else {
            number = high * 10_0000 + low
        }
        self.init(validNumber: number)
    }
    
    public var キャッシュ指示書: 指示書型? { try? 指示書伝票番号キャッシュ型.shared.find(self) }
}

extension FileMakerRecord {
    func 伝票番号(forKey key: String) -> 伝票番号型? {
        guard let number = self.string(forKey: key) else { return nil }
        return 伝票番号型(invalidNumber: number)
    }
}

extension 伝票番号型 {
    static func isExist(伝票番号: 伝票番号型) throws -> Bool {
        return try findRecords(query: ["伝票番号" : "==\(伝票番号)"]).count == 1
    }
}

// MARK: - 伝票種類キャッシュ
extension 伝票番号型 {
    public var キャッシュ伝票種類: 伝票種類型? {
        return self.キャッシュ指示書?.伝票種類
    }
}
