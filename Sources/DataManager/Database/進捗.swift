//
//  進捗.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public final class 進捗型: FileMakerSearchObject, Equatable, Identifiable {
    public static var 立ち上り進捗統合 = false
    public static let layout = "DataAPI_3"

    public var recordId: FileMakerRecordID? { self.recordID }
    private(set) var recordID: FileMakerRecordID
    public var id: FileMakerRecordID { recordID }

    public let 登録日: Day // 24
    public let 登録時間: Time // 24
    public let 製作納期: Day // 24
    public let 伝票番号: 伝票番号型 // 8
    public let 登録日時: Date // 8
    public var 工程: 工程型 //8
    public let 作業系列: 作業系列型? // 8
    public let 作業者: 社員型

    public let 伝票種類: 伝票種類型 // 1
    public var 作業内容: 作業内容型 // 1
    public let 作業種別: 作業種別型 // 1

    public var 社員番号: Int { 作業者.社員番号 }
    public var 伝票番号文字列: String { self.伝票番号.整数文字列 }
    public var 社員名称: String { 作業者.社員名称 }
    public var memoryFootPrint: Int { return 22 * 8} // 仮設定のため適当

    public init(_ record: FileMakerRecord) throws {
        func makeError0(_ key: String) -> Error {
            record.makeInvalidRecordError(name: Self.name, mes: key)
        }
        guard let recordID = record.recordId else { throw makeError0("recordId") }
        self.recordID = recordID
        guard let numberStr = record.string(forKey: "伝票番号") else {
            throw makeError0("伝票番号")
        }
        func makeError(_ key: String) -> Error {
            record.makeInvalidRecordError(name: Self.name, mes: "\(key): \(numberStr)")
        }
        guard let orderNumber = 伝票番号型(invalidNumber: numberStr) else { throw makeError("伝票番号[\(numberStr)]") }
        guard var 工程 = record.工程(forKey: "工程コード") ?? record.工程(forKey: "工程名称") else { throw makeError("工程") }
        if 進捗型.立ち上り進捗統合 && 工程 == .立ち上がり_溶接 { 工程 = .立ち上がり }
        self.伝票番号 = orderNumber
        guard let 作業内容 = record.作業内容(forKey: "進捗コード") else { throw makeError("進捗") }
        guard let name = record.string(forKey: "社員名称"), let num = record.integer(forKey: "社員番号") else { throw makeError("作業者") }
        guard let 登録日 = record.day(forKey: "登録日") else { throw makeError("登録日") }
        guard let 登録時間 = record.time(forKey: "登録時間") else { throw makeError("登録時間") }
        guard let 伝票種類 = record.伝票種類(forKey: "伝票種類") else { throw makeError("伝票種類") }
        guard let 製作納期 = record.day(forKey: "製作納期") else { throw makeError("製作納期") }
        self.工程 = 工程
        self.作業内容 = 作業内容
        self.登録日 = 登録日
        self.登録時間 = 登録時間
        self.登録日時 = Date(登録日, 登録時間)
        self.作業種別 = 作業種別型(record.string(forKey: "作業種別コード") ?? "")
        self.作業系列 = 作業系列型(系列コード: record.string(forKey: "作業系列コード") ?? "")
        self.伝票種類 = 伝票種類
        self.製作納期 = 製作納期
        self.作業者 = prepare社員(社員番号: num, 社員名称: name)
    }
    
    init(original: 進捗型, 工程: 工程型? = nil, 作業内容: 作業内容型? = nil) {
        self.recordID = original.recordID
        self.工程 = 工程 ?? original.工程
        self.作業内容 = 作業内容 ?? original.作業内容
        self.作業者 = original.作業者
        self.登録日 = original.登録日
        self.登録時間 = original.登録時間
        self.登録日時 = original.登録日時
        self.伝票番号 = original.伝票番号
        
        self.作業種別 = original.作業種別
        self.作業系列 = original.作業系列
        self.伝票種類 = original.伝票種類
        self.製作納期 = original.製作納期
    }
    
    public func makeClone() -> 進捗型 {
        return 進捗型(original: self)
    }

    public static func ==(left: 進捗型, right: 進捗型) -> Bool {
        return left.工程 == right.工程 && left.作業内容 == right.作業内容 && left.作業者 == right.作業者 && left.登録日時 == right.登録日時 && left.作業種別 == right.作業種別 && left.作業系列 == right.作業系列
    }
    
    public lazy var 同時作業レコード: Set<FileMakerRecordID> = {
        var set = Set<FileMakerRecordID>()
        set.insert(self.recordID)
        switch self.作業内容 {
        case .受取, .開始:
            let list = 同期進捗キャッシュ型.shared.関連進捗(for: self)
            if let centerIndex = list.firstIndex(where: { $0.recordID == self.recordID }) {
                var index = centerIndex
                while index != list.startIndex {
                    index = list.index(before: index)
                    let progress = list[index]
                    if progress.作業内容 != .開始 && progress.作業内容 != .受取 { break }
                    set.insert(progress.recordID)
                }
                index = list.index(after: centerIndex)
                while index < list.endIndex {
                    let progress = list[index]
                    if progress.作業内容 != .開始 && progress.作業内容 != .受取 { break }
                    set.insert(progress.recordID)
                    index = list.index(after: index)
                }
            }
        case .仕掛:
            break
        case .完了:
            set.insert(self.recordID)
            let list = 同期進捗キャッシュ型.shared.関連進捗(for: self)
            if let centerIndex = list.firstIndex(where: { $0.recordID == self.recordID }) {
                var index = centerIndex
                while index != list.startIndex {
                    index = list.index(before: index)
                    let progress = list[index]
                    if progress.作業内容 != .完了 { break }
                    set.insert(progress.recordID)
                }
                index = list.index(after: centerIndex)
                while index < list.endIndex {
                    let progress = list[index]
                    if progress.作業内容 != .完了 { break }
                    set.insert(progress.recordID)
                    index = list.index(after: index)
                }
            }
        }
        return set
    }()
    
    /// 同時にまとめて行われた進捗入力・進捗出力の数。単独の時は1を返す
    public var 同時作業数: Int { self.同時作業レコード.count }
    
    public static func find(querys: [FileMakerQuery]) throws -> [進捗型] {
        let list: [FileMakerRecord] = try 進捗型.db.find(layout: 進捗型.layout, query: querys)
        return try list.map { try 進捗型($0) }.sorted { $0.登録日時 < $1.登録日時 }
    }
}

public extension 進捗型 {
    var 指示書: 指示書型? { try? 指示書型.find(伝票番号: self.伝票番号).first }
    
    var レーザー加工機: レーザー加工機型? {
        switch self.作業系列 {
        case 作業系列型.gx:    return .gx
        case 作業系列型.ex:    return .ex
        case 作業系列型.hp:    return .hp
        case 作業系列型.water: return .sws
        default:
            break
        }
        guard self.工程 == .レーザー || self.工程 == .レーザー（アクリル） else { return nil }
        if self.登録日 >= Day(2019, 12, 6) { return nil }
        switch self.作業者 {
        case .山本_沢:
            return self.登録日 < Day(2019, 11, 10) ? .hv : .gx
        case .平山_裕二:
            return .ex
        case .佐伯_潤一:
            return .hp
        case .坂本_祐樹:
            return self.登録日 < Day(2019, 11, 10) ? .sws : .gx
        case .荒川_謙二:
            return .ex
        default:
            return nil
        }
    }
    
    func 作業時間(from: Date) -> TimeInterval {
        return self.工程.作業時間(from: from, to: self.登録日時)
    }

    func 作業時間(to: Date) -> TimeInterval {
        return self.工程.作業時間(from: self.登録日時, to: to)
    }

    /// 残業の最後に打った進捗ならtrue
    var is最終時間進捗: Bool {
        let work = 標準カレンダー.勤務時間(工程: self.工程, 日付: self.登録日)
        return abs(work.終業 - self.登録時間) < 1 // 残業時間の1秒以内の進捗は残業時間記録仕掛かりとみなす
    }
    
}

public extension Array where Element == 進捗型 {
    var その他以外: [進捗型] { self.filter { $0.作業種別 != .その他 } }
    
    func 作業内容(工程: 工程型, 日時: Day? = nil) -> 作業内容型? {
        var state: 作業内容型? = nil
        for progress in self where progress.工程 == 工程 {
            if let day = 日時, progress.登録日 >= day { continue }
            state = progress.作業内容
        }
        return state
    }
    
    func findLast(工程: 工程型, 作業内容: 作業内容型) -> 進捗型? {
        return self.last { $0.工程 == 工程 && $0.作業内容 == 作業内容 }
    }
}

public extension Sequence where Element == 進捗型 {
    func contains(工程: 工程型, 作業内容: 作業内容型) -> Bool {
        return self.contains { $0.工程 == 工程 && $0.作業内容 == 作業内容}
    }
    
    func findFirst(工程: 工程型, 作業内容: 作業内容型) -> 進捗型? {
        return self.first { $0.工程 == 工程 && $0.作業内容 == 作業内容 }
    }
    
    func contains作り直し仕掛かり(工程: 工程型, 作直開始日時: Date) -> Bool {
        let targets = self.filter { $0.工程 == 工程 && $0.登録日時 < 作直開始日時 }.sorted { $0.登録日時 > $1.登録日時 }
        for progress in targets {
            switch progress.作業種別 {
            case .先行, .在庫, .通常, .その他:
                break
            case .作直, .手直:
                switch progress.作業内容 {
                case .仕掛:
                    return true
                default:
                    break
                }
                return false
            }
            if progress.作業内容 == .完了 { return false }
        }
        return false
    }
    
    func search作直し仕掛かり工程(作直開始日時: Date) -> 工程型? {
        let targets = self.filter { $0.登録日時 < 作直開始日時 }.sorted { $0.登録日時 > $1.登録日時 }
        for progress in targets {
            switch progress.作業種別 {
            case .通常:
                switch progress.作業内容 {
                case .仕掛:
//                    if !progress.is最終時間進捗 {
                        return progress.工程
//                    }
                default:
                    break
                }
            case .先行, .在庫, .その他:
                break
            case .作直, .手直:
                switch progress.作業内容 {
                case .仕掛:
//                    if !progress.is最終時間進捗 {
                        return progress.工程
//                    }
                default:
                    break
                }
                return nil
            }
        }
        return nil
    }
}

// MARK: - 検索
extension 進捗型 {
    public static func find(伝票番号 num: 伝票番号型, 工程 state: 工程型? = nil, 作業内容 work: 作業内容型? = nil, 作業種別 type: 作業種別型? = nil) throws -> [進捗型] {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(num)"
        if let state = state {
            query["工程コード"] = "==\(state.code)"
        }
        if let work = work {
            query["進捗コード"] = "==\(work.code)"
        }
        if let type = type {
            query["作業種別コード"] = "==\(type.code)"
        }
        return try self.find(query: query)
    }

    public static func find2(伝票番号 num: 伝票番号型, 工程 state: 工程型? = nil, 作業内容 work: 作業内容型? = nil, 作業種別 type: 作業種別型? = nil) throws -> [進捗型] {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(num)"
        if let state = state {
            query["工程コード"] = "==\(state.code)"
        }
        if let work = work {
            query["進捗コード"] = "==\(work.code)"
        }
        if let type = type {
            query["作業種別コード"] = "==\(type.code)"
        }
        return try self.find(query: query)
    }

    public static func find(製作納期 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil, 工程 state: 工程型? = nil, 作業内容 work: 作業内容型? = nil) throws -> [進捗型] {
        var query = FileMakerQuery()
        query["製作納期"] = makeQueryDayString(range)
        if let type = type {
            query["伝票種類"] = type.fmString
        }
        if let state = state {
            query["工程コード"] = "==\(state.code)"
        }
        if let work = work {
            query["進捗コード"] = "\(work.code)"
        }
        return try self.find(query: query)
    }
    
    public static func find(登録期間 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil, 工程 state: 工程型? = nil, 作業内容 work: 作業内容型? = nil, 作業種別: 作業種別型? = nil) throws -> [進捗型] {
        var query = FileMakerQuery()
        query["登録日"] = makeQueryDayString(range)
        if let type = type {
            query["伝票種類"] = type.fmString
        }
        if let state = state {
            query["工程コード"] = "==\(state.code)"
        }
        if let work = work {
            query["進捗コード"] = "\(work.code)"
        }
        if let code = 作業種別?.code {
            query["作業種別コード"] = code
        }
        return try self.find(query: query)
    }
    
    public static func find(伝票作業期間 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil, 工程 state: 工程型? = nil, 作業内容 work: 作業内容型? = nil) throws -> [進捗型] {
        let list = try 進捗型.find(登録期間: range, 伝票種類: type, 工程: state, 作業内容: work)
        
        var numbers = Set<伝票番号型>()
        for progress in list {
            let num = progress.伝票番号
            numbers.insert(num)
        }
        
        var result: [進捗型] = []
        for num in numbers {
            let tmp = try 進捗型.find(伝票番号: num)
            result.append(contentsOf: tmp)
        }
        return result
    }

    public static func find(工程 state: 工程型, 作業者: 社員型, 登録日 day: Day) throws -> [進捗型] {
        var query = FileMakerQuery()
        query["工程コード"] = "==\(state.code)"
        query["登録日"] = day.fmString
        return try self.find(query: query)
    }
    
    public static func find(工程 state: 工程型? = nil, 伝票種類 type: 伝票種類型? = nil, 登録日 day: Day, 作業種別: 作業種別型? = nil) throws -> [進捗型] {
        var query = FileMakerQuery()
        query["登録日"] = day.fmString
        if let state = state {
            query["工程コード"] = "==\(state.code)"
        }
        if let code = 作業種別?.code {
            query["作業種別コード"] = code
        }
        query["伝票種類"] = type?.description
        return try self.find(query: query)
    }
    
    public static func find(登録日 day: Day, 作業内容: 作業内容型) throws -> [進捗型] {
        var query = FileMakerQuery()
        query["登録日"] = day.fmString
        query["進捗コード"] = 作業内容.code
        return try self.find(query: query)
    }

    public static func find(工程: 工程型, 伝票種類: 伝票種類型?, 基準製作納期: Day) throws -> [進捗型] {
        var query = FileMakerQuery()
        if let type = 伝票種類 {
            query["伝票種類"] = type.fmString
        }
        query["製作納期"] = ">=\(基準製作納期.fmString)"
        query["工程コード"] = "=\(工程.code)"
        query["進捗コード"] = "=\(作業内容型.開始.code)"
        return try find(query: query)
    }
    
    public static func find(工程: 工程型, 作業内容: 作業内容型, 開始日時: Date) throws -> [進捗型] {
        var query = FileMakerQuery()
        query["工程コード"] = "=\(工程.code)"
        query["進捗コード"] = "=\(作業内容.code)"
        query["登録日"] = ">=\(開始日時.day.fmString)"
        query["登録時間"] = "\(開始日時.time.fmImportString)...24:00:00"
        return try find(query: query)
    }
}
