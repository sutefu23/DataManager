//
//  進捗出力.swift
//  DataManager
//
//  Created by manager on 2019/12/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct 進捗出力型: FileMakerExportRecord, Hashable, Codable {
    public typealias ImportBuddyType = 進捗型
    public static let layout = "DataAPI_ProcessInput"
    public static let exportScript = "DataAPI_ProcessInput_RecordSet"
    
    public let 登録日: Day
    public let 登録時間: Time

    public let 伝票番号: 伝票番号型
    public let 工程: 工程型
    public let 作業内容: 作業内容型
    public let 作業種別: 作業種別型

    public let 社員: 社員型
    public let 作業系列: 作業系列型?

    public var 登録日時: Date { return Date(self.登録日, self.登録時間) }
    
    enum CodingKeys: String, CodingKey {
        case 登録日
        case 登録時間
        case 伝票番号
        case 工程
        case 作業内容
        case 作業種別
        case 社員
        case 作業系列
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.登録日 = try values.decode(Day.self, forKey: .登録日)
        self.登録時間 = try values.decode(Time.self, forKey: .登録時間)
        self.伝票番号 = try values.decode(伝票番号型.self, forKey: .伝票番号)
        self.工程 = try values.decode(工程型.self, forKey: .工程)
        self.作業内容 = try values.decode(作業内容型.self, forKey: .作業内容)
        self.作業種別 = try values.decode(作業種別型.self, forKey: .作業種別)
        self.社員 = try values.decode(社員型.self, forKey: .社員)
        self.作業系列 = nil
//        self.作業系列 = try values.decodeIfPresent(作業系列型.self, forKey: .作業系列)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.登録日, forKey: .登録日)
        try container.encode(self.登録時間, forKey: .登録時間)
        try container.encode(self.伝票番号, forKey: .伝票番号)
        try container.encode(self.工程, forKey: .工程)
        try container.encode(self.作業内容, forKey: .作業内容)
        try container.encode(self.作業種別, forKey: .作業種別)
        try container.encode(self.社員, forKey: .社員)
//        try container.encodeIfPresent(self.作業系列, forKey: .作業系列)
    }
    
    public init(伝票番号: 伝票番号型, 工程: 工程型, 作業内容: 作業内容型, 社員: 社員型, 登録日時: Date, 作業種別: 作業種別型, 作業系列: 作業系列型?) {
        let 登録日時 = 登録日時.rounded()
        self.伝票番号 = 伝票番号
        self.工程 = 工程
        self.作業内容 = 作業内容
        self.社員 = 社員
        self.登録日 = 登録日時.day
        self.登録時間 = 登録日時.time
        self.作業種別 = 作業種別
        self.作業系列 = 作業系列
    }
    
    public init(_ progress: 進捗型) {
        self.伝票番号 = progress.伝票番号
        self.工程 = progress.工程
        self.作業内容 = progress.作業内容
        self.社員 = progress.作業者
        self.登録日 = progress.登録日
        self.登録時間 = progress.登録時間
        self.作業種別 = progress.作業種別
        self.作業系列 = progress.作業系列
    }
    
    public init?(csvLine line: String) throws {
        if line.isEmpty { return nil } // 空行スキップ
        let cols = line.split(separator: ",")
        if cols.count < 6 { throw ProgressDBError.invalidCSV(line) }
        guard let day = Day(fmDate: cols[0]) else { throw ProgressDBError.invalidCSV(line) }
        guard let time = Time(fmTime: cols[1]) else { throw ProgressDBError.invalidCSV(line) }
        guard let number = try 伝票番号型(invalidString: cols[2]) else { throw ProgressDBError.invalidCSV(line) }
        guard let process = 工程型(cols[3]) else { throw ProgressDBError.invalidCSV(line) }
        guard let state = 作業内容型(cols[4]) else { throw ProgressDBError.invalidCSV(line) }
        guard let worker = 社員型(社員コード: cols[5]) else { throw ProgressDBError.invalidCSV(line) }
        let type : 作業種別型 = (cols.count >= 7) ? 作業種別型(String(cols[6])) : .通常
        let series: 作業系列型? = (cols.count >= 8) ? 作業系列型(系列コード: String(cols[7])) : nil
        let dayTime = Date(day, time)
        self.init(伝票番号: number, 工程: process, 作業内容: state, 社員: worker, 登録日時: dayTime, 作業種別: type, 作業系列: series)
    }

    public func makeCSVLine() -> String {
        return "\(登録日.fmImportString),\(登録時間.fmImportString),\(伝票番号),\(工程.code),\(作業内容.code),\(社員.Hなし社員コード),\(作業種別.code),\(作業系列?.系列コード ?? "")\n"
    }
    
    public func makeExportRecord(exportUUID: UUID) -> FileMakerQuery {
        return self.makeRecord(識別キー: exportUUID)
    }
    
    func makeRecord(識別キー key: UUID) -> [String: String] {
        var record: [String: String] = [
            "識別キー": key.uuidString,
            "登録日": self.登録日.fmString,
            "登録時間": self.登録時間.fmImportString,
            "伝票番号": "\(self.伝票番号.整数値)",
            "工程コード": self.工程.code,
            "作業内容コード": self.作業内容.code,
            "社員コード": self.社員.Hなし社員コード,
            "作業種別コード": self.作業種別.code
        ]
        if let series = self.作業系列 {
            record["作業系列コード"] = series.系列コード
        }
        return record
    }
    
    public static func prepareUploads(uuid: UUID, session: FileMakerSession) throws {
        var query = FileMakerQuery()
        query["指示書進捗入力UUID"] = "==\(uuid.uuidString)"
        _ = try session.find(layout: 進捗型.layout, query: [query])
    }

    /// 重複登録ならtrue
    public func is内容重複(with progress: 進捗出力型) -> Bool {
        if self.伝票番号 != progress.伝票番号 { return false }
        if self.工程 != progress.工程 { return false }
        if self.作業内容 != progress.作業内容 { return false }
        if self.作業種別 != progress.作業種別 { return false }
        if let series1 = self.作業系列, let series2 = progress.作業系列 {
            return series1 == series2
        } else {
            return self.社員 == progress.社員
        }
    }
    
    /// DB内に重複があればtrueを返す
    public var isDBに重複あり: Bool {
        guard let list = try? 進捗型.find(伝票番号: self.伝票番号, 工程: self.工程, 作業内容: self.作業内容, 作業種別: self.作業種別).map({ 進捗出力型($0) }) else { return false }
        for progress in list {
            if progress.is内容重複(with: self) { return true }
        }
        return false
    }
    
    public func find重複候補() throws -> [進捗型] {
        return try 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号).進捗一覧
    }
    
    public func is内容重複(with data: 進捗型) -> Bool {
        return self.伝票番号 == data.伝票番号 && self.工程 == data.工程 && self.作業内容 == data.作業内容 && self.作業種別 == data.作業種別
    }
    
    public func flushCache() {
        return 指示書進捗キャッシュ型.shared.flushCache(伝票番号: self.伝票番号)
    }
}

// MARK: -
public struct 進捗出力内容型: Hashable {
    public let 伝票番号: 伝票番号型
    public let 工程: 工程型
    public let 作業内容: 作業内容型
    public let 作業種別: 作業種別型

    public init(伝票番号: 伝票番号型, 工程 : 工程型, 作業内容: 作業内容型, 作業種別: 作業種別型) {
        self.伝票番号 = 伝票番号
        self.工程 = 工程
        self.作業内容 = 作業内容
        self.作業種別 = 作業種別
    }

    public init(_ 進捗出力: 進捗出力型) {
        self.伝票番号 = 進捗出力.伝票番号
        self.工程 = 進捗出力.工程
        self.作業内容 = 進捗出力.作業内容
        self.作業種別 = 進捗出力.作業種別
    }

    public func make進捗出力(社員: 社員型, 作業系列: 作業系列型?, 登録日時: Date) -> 進捗出力型 {
        return 進捗出力型(伝票番号: 伝票番号, 工程: 工程, 作業内容: 作業内容, 社員: 社員, 登録日時: 登録日時, 作業種別: 作業種別, 作業系列: 作業系列)
    }
}

// MARK: -
extension Collection where Element == 進捗出力型 {
    /// 参照リストとの重複を削除する
    func 重複登録削除(参照 list: [進捗出力型]) -> [進捗出力型] {
        var map = Dictionary(grouping: list) { 進捗出力内容型($0) }
        var result : [進捗出力型] = []
        mainLoop: for target in self {
            let key = 進捗出力内容型(target)
            if var list = map[key] {
                for member in list {
                    if target.is内容重複(with: member) { continue mainLoop }
                }
                list.append(target)
                map[key] = list
            } else {
                map[key] = [target]
            }
            result.append(target)
        }
        return result
    }
}
    
// MARK: - CSV関連
extension Array where Element == 進捗出力型 {
    public init(csv url: URL, 重複排除: Bool = true)  throws {
        var targets: [進捗出力型] = []
        if url.isExists {
            let source = try String(contentsOf: url, encoding: .utf8)
            var convertError: Error? = nil
            source.enumerateLines { (line, stop) in
                do {
                    if let pl = try 進捗出力型(csvLine: line) {
                        targets.append(pl)
                    }
                } catch {
                    convertError = error
                    stop = true
                }
            }
            if 重複排除 {
                let lock = NSLock()
                var tmp: [進捗出力型] = []
                DispatchQueue.concurrentPerform(iterations: targets.count) {
                    let object = targets[$0]
                    if !object.isDBに重複あり {
                        lock.lock()
                        tmp.append(object)
                        lock.unlock()
                    }
                }
                targets = tmp
            }
            if let error = convertError { throw error }
        }
        self.init(targets)
    }
}

extension Sequence where Element == 進捗出力型 {
    func 生産管理との重複削除() -> [進捗出力型] {
        return self.filter { !$0.isDBに重複あり }
    }
    
    /// CSVとして出力する
    public func writeToCSV(url: URL) throws {
        let outputLines = self.map { $0.makeCSVLine() }.joined()
        guard let data = outputLines.data(using: .utf8, allowLossyConversion: true) else {
            throw ProgressDBError.cantConvert
        }
        try data.write(to: url, options: [.atomic])
    }
}

// MARK: -
public extension URL {
    func export進捗出力CSV(_ newlines: [進捗出力型], 重複チェック: Bool) throws {
        let lines = try [進捗出力型](csv: self).生産管理との重複削除()
        let newlines2 = !重複チェック ? newlines : newlines.重複登録削除(参照: lines)
        try (lines+newlines2).writeToCSV(url: self)
    }
    
    func refres進捗出力CSV() throws {
        let lines = try [進捗出力型](csv: self).生産管理との重複削除()
        try lines.writeToCSV(url: self)
    }
}

// MARK: - エラーコード
public enum ProgressDBError: LocalizedError {
    case invalidProcess
    case invalidWorker
    case invalidState
    case invalidOrder
    case noOrder(Int)
    case cantConvert
    case invalidURL
    case invalidCSV(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidProcess: return "不正な工程コード"
        case .invalidWorker: return "不正な作業者コード"
        case .invalidState: return "不正な作業内容コード"
        case .invalidOrder: return "不正な伝票番号"
        case .noOrder(let order): return "存在しない伝票番号:\(order)"
        case .cantConvert : return "不正な文字列"
        case .invalidURL: return "不正なURL"
        case .invalidCSV(let line): return "不正なCSV:\(line)"
        }
    }
}
