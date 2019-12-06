//
//  指示書進捗.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

let 外注先会社コード : Set<String> = ["2971", "2993", "4442",  "3049", "3750"]

public class 指示書型 {
    let record : FileMakerRecord
    
    init?(_ record:FileMakerRecord) {
        self.record = record
    }
    
    public lazy var 伝票番号 : 伝票番号型 = {
        let num = record.integer(forKey: "伝票番号")!
        return 伝票番号型(validNumber: num)
    }()
    public lazy var 比較用伝票番号 : Int = {
        let div = self.表示用伝票番号.split(separator: "-")
        if div.count != 2 { return -1 }
        if div[0].count >= 4 {
            guard let high = Int(div[0]), let low = Int(div[1]) else { fatalError() }
            return high * 1_00_000 + low
        } else {
            guard let high = Int(div[0]), let low = Int(div[1]) else { fatalError() }
            return high * 1_000_000 + low
        }
    }()
    public lazy var 表示用伝票番号 : String = { record.string(forKey: "表示用伝票番号")! }()
    public lazy var 略号 : Set<略号型> = { make略号(record.string(forKey: "略号")!) }()
    
    public lazy var 登録日時 : Date = { record.date(dayKey: "登録日", timeKey: "登録時間")! }()
    public lazy var 受注日 : Day = { record.day(forKey: "受注日")! }()
    public lazy var 伝票種類 : 伝票種類型  = { record.伝票種類(forKey: "伝票種類")! }()
    public lazy var 伝票状態 : 伝票状態型 = { record.伝票状態(forKey: "伝票状態") ?? .未製作 }()
    public lazy var 工程状態 : 工程状態型 = { record.工程状態(forKey: "工程状態")! }()
    public lazy var 承認状態 : 承認状態型 = { record.承認状態(forKey: "承認状態")! }()
    public lazy var 製作納期 : Day = { record.day(forKey: "製作納期")! }()
    public lazy var 出荷納期 : Day = { record.day(forKey: "出荷納期")! }()
    
    public var 品名 : String { record.string(forKey: "品名")! }
    public var 仕様 : String { record.string(forKey: "仕様")! }
    public var 社名 : String { record.string(forKey: "社名")! }
    public var 文字数 : String { record.string(forKey: "文字数")! }
    public var セット数 : String { record.string(forKey: "セット数")! }
    public var 備考 : String { record.string(forKey: "備考")! }
    public var 管理用メモ : String { record.string(forKey: "管理用メモ")! }

    public var 材質1 : String { record.string(forKey: "材質1")! }
    public var 材質2 : String { record.string(forKey: "材質2")! }
    public var 表面仕上1 : String { record.string(forKey: "表面仕上1")! }
    public var 表面仕上2 : String { record.string(forKey: "表面仕上2")! }
    public var 板厚1 : String { record.string(forKey: "板厚1")! }
    public var 板厚2 : String { record.string(forKey: "板厚2")! }

    public var 上段左 : String { record.string(forKey: "上段左")! }
    public var 上段中央 : String { record.string(forKey: "上段中央")! }
    public var 上段右 : String { record.string(forKey: "上段右")! }
    public var 下段左 : String { record.string(forKey: "下段左")! }
    public var 下段中央 : String { record.string(forKey: "下段中央")! }
    public var 下段右 : String { record.string(forKey: "下段右")! }

    public var 単価1 : Int { record.integer(forKey: "単価1") ?? 0 }
    public var 数量1 : Int { record.integer(forKey: "数量1") ?? 0 }
    public lazy var 伝票種別 : 伝票種別型 = { 伝票種別型(self.record.string(forKey: "伝票種別")!)! }()
    public var 経理状態 : 経理状態型 {
        if let state = record.経理状態(forKey: "経理状態") { return state }
        return self.進捗一覧.contains(工程: .経理, 作業内容: .完了) ? .売上処理済 : .未登録
    }
    public var ボルト等1 : String { record.string(forKey: "ボルト等1") ?? "" }
    public var ボルト等2 :  String { record.string(forKey: "ボルト等2") ?? "" }
    public var ボルト等3 : String { record.string(forKey: "ボルト等3") ?? "" }
    public var ボルト等4 : String { record.string(forKey: "ボルト等4") ?? "" }

    public var ボルト本数1 : String { record.string(forKey: "ボルト本数1") ?? "" }
    public var ボルト本数2 : String { record.string(forKey: "ボルト本数2") ?? "" }
    public var ボルト本数3 : String { record.string(forKey: "ボルト本数3") ?? "" }
    public var ボルト本数4 : String { record.string(forKey: "ボルト本数4") ?? "" }
    
    public var 合計金額 : Int { record.integer(forKey: "合計金額") ?? 0}
    public lazy var インシデント一覧 : [インシデント型] = {
        let list = self.進捗一覧.map { インシデント型($0) } + self.変更一覧.map { インシデント型($0) }
        return list.sorted { $0.日時 < $1.日時 }
    }()
    
    var 図URL : URL? { record.url(forKey: "図") }
    #if os(macOS)
    public lazy var 図 : NSImage? = {
        guard let url = self.図URL else { return nil }
        let db = FileMakerDB.pm_osakaname
        guard let data = db.downloadObject(url: url) else { return nil }
        let image = NSImage(data: data)
        return image
    }()
    #elseif os(iOS)
    public lazy var 図 : UIImage? = {
        guard let url = self.図URL else { return nil }
        let db = FileMakerDB.pm_osakaname
        guard let data = db.downloadObject(url: url) else { return nil }
        let image = UIImage(data: data)
        return image
    }()
    #else
    #endif

    public lazy var 進捗一覧 : [進捗型] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "指示書進捗内訳テーブル") else { return [] }
        return list.compactMap { 進捗型($0) }.sorted { $0.登録日時 < $1.登録日時 }
    }()
    
    public lazy var 変更一覧 : [指示書変更内容履歴型] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "指示書変更内容履歴テーブル") else { return [] }
        return list.compactMap { 指示書変更内容履歴型($0) }
    }()
    
    lazy var 添付資料一覧 : [FileMakerRecord] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "指示書工程写真保存テーブル") else { return [] }
        return list
    }()
    
    lazy var 集荷時間一覧 : [FileMakerRecord] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "集荷時間マスタ_確認用") else { return [] }
        return list
    }()
    
    public lazy var 外注一覧 : [発注型] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "資材発注テーブル") else { return [] }
        return list.compactMap { 発注型($0) }
    }()
    
    public lazy var 進捗入力記録一覧 : [作業記録型] = self.make進捗入力記録一覧()
    public lazy var 工程別作業記録 : [工程型 : [作業記録型]] = Dictionary(grouping: self.進捗入力記録一覧) { $0.工程 }
    
    public lazy var 承認情報 : 指示書変更内容履歴型? = { return self.変更一覧.filter { $0.種類 == .指示書承認 }.max { $0.日時 < $1.日時 } }()

    public var 塗装文字数概算 : Int {
        let leftLast, rightLast : Int
        var left = self.文字数.makeNumbers()
        if let last = left.last {
            leftLast = last
        } else {
            left = [1]
            leftLast = 1
        }
        var right = (self.伝票種類 == .加工) ? [1] : self.セット数.makeNumbers()
        if let last = right.last {
            rightLast = last
        } else {
            right = [1]
            rightLast = 1
        }
        while left.count < right.count { left.append(leftLast) }
        while right.count < left.count { right.append(rightLast) }
        var total = 0
        for (l, r) in zip(left, right) {
            total += l * r
        }
        return total
    }
    
    public var 製作文字数概算 : Int {
        let leftLast, rightLast : Int
        var left = self.文字数.makeNumbers()
        if let last = left.last {
            leftLast = last
        } else {
            left = [1]
            leftLast = 1
        }
        var right = (self.伝票種類 == .加工) ? [1] : self.セット数.makeNumbers()
        if let last = right.last {
            rightLast = last
        } else {
            right = [1]
            rightLast = 1
        }
        while left.count < right.count { left.append(leftLast) }
        while right.count < left.count { right.append(rightLast) }
        var total = 0
        for (l, r) in zip(left, right) {
            total += l * r
        }
        if self.伝票種類 == .箱文字 {
            let type = self.仕様
            if type.contains("W") || type.contains("リング") || (type.contains("表") && type.contains("バック")) {
                total *= 2
            }
        }
        return total
    }

    public var is外注塗装あり : Bool {
        return self.外注一覧.contains { 外注先会社コード.contains($0.会社コード) }
    }
    
    public var is内作塗装あり : Bool {
        return self.進捗一覧.contains {
            return $0.工程 == .塗装 && ($0.作業内容 == .開始 || $0.作業内容 == .完了)
        }
    }
    
    public var is外注シートあり : Bool {
        return self.外注一覧.contains { $0.会社コード == "0074" }
    }
    
    public var is社内研磨あり : Bool {
        return self.進捗一覧.contains {
            return $0.工程 == .研磨 && ($0.作業内容 == .開始 || $0.作業内容 == .完了)
        }
    }
    
    public var is半田あり : Bool {
        return self.略号.contains(.半田)
    }
    
    public var is溶接あり : Bool {
        return self.略号.contains(.溶接)
    }
    
    public var is承認済有効: Bool {
        return self.承認状態 == .承認済 && self.伝票状態 != .キャンセル
    }
    
    public var 金額 : Int {
        var value = self.合計金額
        if value <= 0 {
            value = self.単価1
            let count = self.単価1
            if count > 0 { value += count }
        }
        return value
    }
    
    public var 担当者1 : 社員型? {
        guard let num = record.integer(forKey: "社員番号1"), let name = record.string(forKey: "担当者1"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    public var 担当者2 : 社員型? {
        guard let num = record.integer(forKey: "社員番号2"), let name = record.string(forKey: "担当者2"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    public var 担当者3 : 社員型? {
        guard let num = record.integer(forKey: "社員番号3"), let name = record.string(forKey: "担当者3"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    public lazy var 保留校正一覧 : [作業型] = {
        return (self.保留一覧 + self.校正一覧).sorted { $0.開始日時 < $1.開始日時 }
    }()
    
    public lazy var 保留一覧 : [作業型] = {
        var list = [作業型]()
        var from : Date?
        for change in self.変更一覧 {
            switch change.種類 {
            case .保留開始:
                from = change.日時
            case .保留解除:
                    guard let from  = from else { break }
                    let to = change.日時
                    if let work = 作業型(nil, type: .保留, state: .管理, from: from, to: to, worker: change.作業者, 伝票番号: self.伝票番号) {
                        list.append(work)
                    }
                default:
                    break
            }
        }
        return list
    }()
    
    public lazy var 校正一覧 : [作業型] = {
        var list = [作業型]()
        var from : Date?
        for change in self.変更一覧 {
            switch change.内容 {
            case "校正開始":
                from = change.日時
            case "校正終了":
                guard let from  = from else { break }
                let to = change.日時
                if let work = 作業型(nil, type: .校正, state: .原稿, from: from, to: to, worker: change.作業者, 伝票番号: self.伝票番号) {
                    list.append(work)
                }
            default:
                break
            }
        }
        return list
    }()
    
    public lazy var 半田溶接振り分け : String = {
        let str = self.上段中央 + self.下段中央
        if !is溶接あり && !is半田あり {
            return self.伝票種類 == .箱文字 ? str : ""
        }
        if str.contains("半田") || str.contains("溶接") { return str }
        
        if is半田あり {
            return is溶接あり ? "半田 溶接" : "半田"
        } else {
            assert(is溶接あり)
            return "溶接"
        }
    }()
    
    public lazy var 指示書文字数: 指示書文字数型 = 指示書文字数型(指示書: self)
    
    public func showInfo() {
        guard let url = URL(string: "fmp://outsideuser:outsideuser!@192.168.1.153/viewer?script=search&param=\(self.伝票番号)") else { return }
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

// MARK: - 検索パターン
public extension 指示書型 {
    static func find(伝票番号:伝票番号型? = nil, 伝票種類:伝票種類型? = nil, 製作納期:Day? = nil, limit:Int = 100) -> [指示書型]? {
        var query = [String:String]()
        if let num = 伝票番号 {
            query["伝票番号"] = "\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        query["製作納期"] = 製作納期?.fmString
         let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
//        let list : [FileMakerRecord]? = db.find(layout: "エッチング指示書テーブル詳細営業以外用", query: [query])
        return list?.compactMap { 指示書型($0) }
    }
    
    static func find2(伝票番号:伝票番号型? = nil, 伝票種類:伝票種類型? = nil, 製作納期:Day? = nil, limit:Int = 100) -> [指示書型]? {
        var query = [String:String]()
        if let num = 伝票番号 {
            query["伝票番号"] = "\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        query["製作納期"] = 製作納期?.fmString
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
//        let list : [FileMakerRecord]? = db.find(layout: "エッチング指示書テーブル詳細", query: [query])
        return list?.compactMap { 指示書型($0) }
    }

    
    static func find(伝票番号:伝票番号型? = nil, 伝票種類:伝票種類型? = nil, 受注日 range0:ClosedRange<Day>? = nil, 製作納期 range:ClosedRange<Day>? = nil,  出荷納期 range2:ClosedRange<Day>? = nil) -> [指示書型]? {
        var query = [String:String]()
        if let num = 伝票番号 {
            query["伝票番号"] = "\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        if let range0 = range0 {
            query["受注日"] = makeQueryDayString(range0)
        }
        if let range = range {
            query["製作納期"] = makeQueryDayString(range)
        }
        if let range2 = range2 {
            query["出荷納期"] = makeQueryDayString(range2)
        }
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
        return list?.compactMap { 指示書型($0) }
    }
    
    static func find(作業範囲 range:ClosedRange<Day>, 伝票種類 type:伝票種類型? = nil) -> [指示書型]? {
        var query = [String:String]()
//        query["受注日"] = "<=\(range.upperBound.fmString)"
        query["出荷納期"] = ">=\(range.lowerBound.fmString)"
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
        return list?.compactMap { 指示書型($0) }
    }
    
    static func find(進捗入力日 range:ClosedRange<Day>, 伝票種類 type:伝票種類型? = nil, 工程:工程型? = nil, 作業内容:作業内容型? = nil) -> [指示書型]? {
        guard let list = 進捗型.find(登録期間: range, 伝票種類: type, 工程: 工程, 作業内容: 作業内容) else { return nil }
        var numbers = Set<伝票番号型>()
        for progress in list {
            let num = progress.伝票番号
            numbers.insert(num)
        }
        var result : [指示書型] = []
        for num in numbers {
            if let order = 指示書型.find(伝票番号: num)?.first {
                result.append(order)
            }
        }
        return result
    }
    
    static func findActive(伝票種類:伝票種類型? = nil) -> [指示書型]? {
        var query = [String:String]()
        let today = Date()
        query["出荷納期"] = ">=\(today.day.fmString)"
        query["伝票種類"] = 伝票種類?.fmString
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
        return list?.compactMap {
            guard let order = 指示書型($0) else { return nil }
            switch order.伝票状態 {
            case .キャンセル, .発送済:
                return nil
            case .未製作, .製作中:
                break
            }
            if order.承認状態 == .未承認 { return nil }
            return order
        }
    }
    
    static func find2(作業範囲 range:ClosedRange<Day>, 伝票種類 type:伝票種類型? = nil) -> [指示書型]? {
        var query = [String:String]()
        query["受注日"] = "<=\(range.upperBound.fmString)"
        query["出荷納期"] = ">=\(range.lowerBound.fmString)"
        query["伝票種類"] = type?.fmString
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
        return list?.compactMap { 指示書型($0) }
    }
    
    static func find(登録日 range:ClosedRange<Day>, 伝票種類 type:伝票種類型? = nil) -> [指示書型]? {
        var query = [String:String]()
        query ["登録日"] = makeQueryDayString(range)
        query["伝票種類"] = type?.fmString
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
        return list?.compactMap { 指示書型($0) }
    }

    static func findDirect(伝票番号: Int) -> 指示書型? {
        var query = [String:String]()
        query["伝票番号"] = "\(伝票番号)"
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
        if list?.count == 1, let record = list?.first, let order = 指示書型(record) {
            return order
        } else {
            return nil
        }
    }
}
