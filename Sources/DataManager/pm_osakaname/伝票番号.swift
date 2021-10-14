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

public struct 伝票番号型: FileMakerObject, DMCacheKey, RawRepresentable, Codable, Comparable, ExpressibleByIntegerLiteral {
    public static var db: FileMakerDB { .pm_osakaname }
    public static var layout: String { "DataAPI_10" }

    public typealias RawValue = Int32 // 厳密にはUInt32だがビットは十分なので他のコードの共有を図る
    
    public let 整数値: RawValue
    
    @inlinable public var rawValue: RawValue { 整数値 }
    
    @inlinable public var intRawValue: Int { Int(整数値) }

    public init?<S: StringProtocol>(invalidNumber: S?) {
        guard let invalidNumber = invalidNumber,
              let number = RawValue(String(invalidNumber.toHalfCharacters.filter{ $0.isASCIINumber })) else { return nil }
        self.init(invalidNumber: number)
    }

    public init?(invalidNumber: Int?) {
        guard let number = invalidNumber else { return nil }
        self.init(rawValue: RawValue(number))
    }

    public init?(invalidNumber: RawValue?) {
        guard let number = invalidNumber else { return nil }
        self.init(rawValue: number)
    }
    
    public init?(rawValue: RawValue) {
        self.整数値 = rawValue
        guard self.isValidNumber() else { return nil }
    }

    public init(validNumber: Int) {
        self.整数値 = RawValue(validNumber)
    }

    public init(validNumber: RawValue) {
        self.整数値 = validNumber
    }

    public init(integerLiteral: RawValue) {
        self.init(validNumber: integerLiteral)
    }
    
    public init?(month: Month, invalidLowNumber lowNumber: RawValue) {
        if lowNumber <= 0 { return nil }
        let number: RawValue
        if lowNumber <= 9999 {
            number = (RawValue(month.shortYear) * 100 + RawValue(month.month)) * 10000 + lowNumber
        } else if lowNumber <= 9_9999 {
            number = (RawValue(month.shortYear) * 100 + RawValue(month.month)) * 100000 + lowNumber
        } else {
            number = lowNumber
        }
        self.整数値 = number
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
        self.整数値 = try values.decode(RawValue.self, forKey: .number)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.整数値, forKey: .number)
    }
    
    // MARK: -
    /// 存在チェックして存在すればtrueを返す。チェックできなかった時はnilを返す
    public var isExists: Bool? {
        do {
            return try 伝票番号キャッシュ型.shared.find(self.整数値) != nil
        } catch {
            return nil
        }
    }
    
    /// 存在しないのが確定した場合truer
    @inlinable
    public var noExists: Bool { return isExists == false }
    
    func isValidNumber() -> Bool {
        let low = self.下位整数値
        if self.is旧伝票暗号 {
            guard low >= 1 && low <= 999999 else { return false }
        } else {
            guard low >= 1 && low <= 99999 else { return false }
        }
        guard let yearMonth = self.newYearMonth else { return self.is旧伝票暗号 } // 伝票番号から年月が取り出せない場合、旧伝票番号の形式を満たしていればokとする
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
    
    public var 上位整数値: RawValue {
        if is旧伝票暗号 { return 0 }
        return 整数値 > 9999_9999 ? 整数値 / 1000_00 : 整数値 / 100_00
    }

    public var 下位整数値: RawValue {
        if is旧伝票暗号 { return 整数値 }
        return 整数値 > 9999_9999 ? 整数値 % 1000_00 : 整数値 % 100_00
    }
    public var 下位文字列: String {
        String(format: "%04d", 下位整数値)
    }

    /// 新形式の伝票番号から計算される年月
    public var newYearMonth: Month? {
        if is旧伝票暗号 {
            return nil
        } else {
            let year = 2000 + 上位整数値 / 100
            let month = 上位整数値 % 100
            return Month(Month.YearType(year), Month.MonthType(month))
        }
    }

    /// 伝票番号から計算される年月（旧形式の伝票番号の場合、検索して年月を確かめる）
    public var yearMonth: Month? {
        if let yearMonth = self.newYearMonth { // 新伝票番号なら伝票番号から年月を取り出す
            return yearMonth
        } else if self.is旧伝票暗号, let date = self.キャッシュ指示書?.受注日 { // 旧伝票番号なら指示書の受注日から年月を取り出す
            return Month(date.year, date.month)
        } else { // 不正な伝票番号
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
        guard let low = RawValue(url.lastPathComponent), 0 < low && low <= 99999  else { return nil }
        url = url.deletingLastPathComponent()
        guard let middle = RawValue(url.lastPathComponent), 1 <= middle && middle <= 31 else { return nil }
        url = url.deletingLastPathComponent()
        guard var high = RawValue(url.lastPathComponent), 2000 <= high && high <= 9999 else { return nil }
        high = (high-2000) * 100 + middle
        let number: RawValue
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
    static func directCheckIsExist(伝票番号: 伝票番号型) throws -> Bool {
        return try findRecords(query: ["伝票番号" : "==\(伝票番号)"]).count == 1
    }
}

// MARK: - 伝票種類キャッシュ
extension 伝票番号型 {
    public var キャッシュ伝票種類: 伝票種類型? {
        return self.キャッシュ指示書?.伝票種類
    }
}

// MARK: - 伝票番号の解析
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

