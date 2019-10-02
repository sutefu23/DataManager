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

public class 指示書型 {
    let record : FileMakerRecord
    
    init?(_ record:FileMakerRecord) {
        self.record = record
        guard let numstr = record.string(forKey: "表示用伝票番号"), numstr.count >= 6 else { fatalError() }
        self.表示用伝票番号 = numstr
        let div = numstr.split(separator: "-")
        if div.count != 2 { return nil }
        if div[0].count >= 4 {
            guard let num = Int(div[0]+div[1]), num >= 100000 else { fatalError() }
            self.伝票番号 = num
            guard let high = Int(div[0]), let low = Int(div[1]) else { fatalError() }
            self.比較用伝票番号 = high * 1_00_000 + low
        } else {
            guard let num = Int(div[1]), num >= 1 else { fatalError() }
            self.伝票番号 = num
            guard let high = Int(div[0]), let low = Int(div[1]) else { fatalError() }
            self.比較用伝票番号 = high * 1_000_000 + low
        }
        guard let mark = record.string(forKey: "略号") else { fatalError() }
        self.略号 = make略号(mark)
    }
    
    public let 伝票番号 : Int
    public let 比較用伝票番号 : Int
    public let 表示用伝票番号 : String
    public let 略号 : Set<略号型>
    
    public var 受注日 : Date { return record.date(forKey: "受注日")! }
    public var 伝票種類 : 伝票種類型 { return record.伝票種類(forKey: "伝票種類")! }
    public var 伝票状態 : 伝票状態型 { return record.伝票状態(forKey: "伝票状態")! }
    public var 工程状態 : 工程状態型 { return record.工程状態(forKey: "工程状態")! }
    public var 承認状態 : String { return record.string(forKey: "承認状態")! }
    public var 製作納期 : Date { return record.date(forKey: "製作納期")! }
    public var 出荷納期 : Date { return record.date(forKey: "出荷納期")! }
    
    public var 品名 : String { return record.string(forKey: "品名")! }
    public var 仕様 : String { return record.string(forKey: "仕様")! }
    public var 社名 : String { return record.string(forKey: "社名")! }
    public var 文字数 : String { return record.string(forKey: "文字数")! }
    public var セット数 : String { return record.string(forKey: "セット数")! }
    public var 備考 : String { return record.string(forKey: "備考")! }
    public var 管理用メモ : String { return record.string(forKey: "管理用メモ")! }

    public var 材質1 : String { return record.string(forKey: "材質1")! }
    public var 材質2 : String { return record.string(forKey: "材質2")! }
    public var 表面仕上1 : String { return record.string(forKey: "表面仕上1")! }
    public var 表面仕上2 : String { return record.string(forKey: "表面仕上2")! }
    
    public var 上段左 : String { return record.string(forKey: "上段左")! }
    public var 上段中央 : String { return record.string(forKey: "上段中央")! }
    public var 上段右 : String { return record.string(forKey: "上段右")! }
    public var 下段左 : String { return record.string(forKey: "下段左")! }
    public var 下段中央 : String { return record.string(forKey: "下段中央")! }
    public var 下段右 : String { return record.string(forKey: "下段右")! }

    public var 単価1 : Int { return record.integer(forKey: "単価1") ?? 0 }
    public var 数量1 : Int { return record.integer(forKey: "数量1") ?? 0 }
    public var 伝票種別 : String { return record.string(forKey: "伝票種別")! }
    public var 経理状態 : 経理状態型 {
        if let state = record.経理状態(forKey: "経理状態") { return state }
        return self.進捗一覧.contains(工程: .経理, 作業内容: .完了) ? .売上処理済 : .未登録
    }
    
    public var 合計金額 : Int { return record.integer(forKey: "合計金額") ?? 0}
    
    var 図URL : URL? { return record.url(forKey: "図") }
    fileprivate var imageCache : Any?

    public lazy var 進捗一覧 : [進捗型] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "指示書進捗内訳テーブル") else { return [] }
        return list.compactMap { 進捗型($0) }.sorted { $0.登録日時 < $1.登録日時 }
    }()
    
    lazy var 変更一覧 : [指示書変更内容履歴型] = {
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
    
    lazy var 外注一覧 : [発注型] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "資材発注テーブル") else { return [] }
        return list.compactMap { 発注型($0) }
    }()
    
    lazy var 登録日時 : Date = { record.date(dayKey: "登録日", timeKey: "登録時間")! }()
}

extension 指示書型 {
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

}

public extension 指示書型 {
    static func find(伝票番号:Int? = nil, 伝票種類:伝票種類型? = nil, 製作納期:Date? = nil, limit:Int = 100) -> [指示書型]? {
        var query = [String:String]()
        if let num = 伝票番号 {
            query["伝票番号"] = "\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        query["製作納期"] = 製作納期?.day.fmString
         let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
//        let list : [FileMakerRecord]? = db.find(layout: "エッチング指示書テーブル詳細営業以外用", query: [query])
        return list?.compactMap { 指示書型($0) }
    }
    
    static func find2(伝票番号:Int? = nil, 伝票種類:伝票種類型? = nil, 製作納期:Date? = nil, limit:Int = 100) -> [指示書型]? {
        var query = [String:String]()
        if let num = 伝票番号 {
            query["伝票番号"] = "\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        query["製作納期"] = 製作納期?.day.fmString
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
//        let list : [FileMakerRecord]? = db.find(layout: "エッチング指示書テーブル詳細", query: [query])
        return list?.compactMap { 指示書型($0) }
    }

    
    static func find(伝票番号:Int? = nil, 伝票種類:伝票種類型? = nil, 受注日 range0:ClosedRange<Date>? = nil, 製作納期 range:ClosedRange<Date>? = nil,  出荷納期 range2:ClosedRange<Date>? = nil) -> [指示書型]? {
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
    
    static func find(作業範囲 range:ClosedRange<Date>, 伝票種類 type:伝票種類型? = nil) -> [指示書型]? {
        var query = [String:String]()
//        query["受注日"] = "<=\(range.upperBound.day.fmString)"
        query["出荷納期"] = ">=\(range.lowerBound.day.fmString)"
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "DataAPI_指示書", query: [query])
        return list?.compactMap { 指示書型($0) }
    }
    
    static func find(進捗入力日 range:ClosedRange<Date>, 伝票種類 type:伝票種類型? = nil, 工程:工程型? = nil, 作業内容:作業内容型? = nil) -> [指示書型]? {
        guard let list = 進捗型.find(登録期間: range, 伝票種類: type, 工程: 工程, 作業内容: 作業内容) else { return nil }
        var numbers = Set<Int>()
        for progress in list {
            if let num = progress.伝票番号 { numbers.insert(num) }
        }
        var result : [指示書型] = []
        for num in numbers {
            if let order = 指示書型.find(伝票番号: num)?.first {
                result.append(order)
            }
        }
        return result
    }
}

extension 指示書型 {
#if os(macOS)
    public var 図 : NSImage? {
        if let image = self.imageCache as? NSImage { return image }
        guard let url = self.図URL else { return nil }
        let db = FileMakerDB.pm_osakaname
        guard let data = db.downloadObject(url: url) else { return nil }
        let image = NSImage(data: data)
        self.imageCache = image
        return image
    }
#else
#endif
}
let 外注先会社コード : Set<String> = ["2971", "2993", "4442",  "3049", "3750"]
public extension 指示書型 {
    var is外注塗装あり : Bool {
        return self.外注一覧.contains { 外注先会社コード.contains($0.会社コード) }
    }
    
    var is内作塗装あり : Bool {
        return self.進捗一覧.contains {
            return $0.工程 == .塗装 && ($0.作業内容 == .開始 || $0.作業内容 == .完了)
        }
    }
    
    var is外注シートあり : Bool {
        return self.外注一覧.contains { $0.会社コード == "0074" }
    }
    
    var is社内研磨あり : Bool {
        return self.進捗一覧.contains {
            return $0.工程 == .研磨 && ($0.作業内容 == .開始 || $0.作業内容 == .完了)
        }
    }
    
    var is半田あり : Bool {
        return self.略号.contains(.半田)
    }
    
    var is溶接あり : Bool {
        return self.略号.contains(.溶接)
    }
    
    var 金額 : Int {
        var value = self.合計金額
        if value <= 0 {
            value = self.単価1
            let count = self.単価1
            if count > 0 { value += count }
        }
        return value
    }
    
    var 担当者1 : 社員型? {
        guard let num = record.integer(forKey: "社員番号1"), let name = record.string(forKey: "担当者1"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    var 担当者2 : 社員型? {
        guard let num = record.integer(forKey: "社員番号1"), let name = record.string(forKey: "担当者1"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    var 担当者3 : 社員型? {
        guard let num = record.integer(forKey: "社員番号1"), let name = record.string(forKey: "担当者1"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    var 保留一覧 : [作業型] {
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
//            switch change.内容 {
//            case "保留開始":
//                from = change.日時
//            case "保留解除":
//                guard let from  = from else { break }
//                let to = change.日時
//                if let work = 作業型(nil, type: .保留, state: .管理, from: from, to: to, worker: change.作業者, 伝票番号: self.伝票番号) {
//                    list.append(work)
//                }
//            default:
//                break
//            }
        }
        return list
    }
    
    var 校正一覧 : [作業型] {
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
    }
}
