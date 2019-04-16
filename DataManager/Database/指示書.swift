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
        } else {
            guard let num = Int(div[1]), num >= 1 else { fatalError() }
            self.伝票番号 = num
        }
        guard let mark = record.string(forKey: "略号") else { fatalError() }
        self.略号 = make略号(mark)
    }
    
    public let 伝票番号 : Int
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

    public var 合計金額 : Int { return record.integer(forKey: "合計金額") ?? 0}
    
    var 図URL : URL? { return record.url(forKey: "図") }
    fileprivate var imageCache : Any?

    public lazy var 進捗一覧 : [進捗型] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "指示書進捗内訳テーブル") else { return [] }
        return list.compactMap { 進捗型($0) }.sorted { $0.登録日時 < $1.登録日時 }
    }()
    
    lazy var 変更一覧 : [FileMakerRecord] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "指示書変更内容履歴テーブル") else { return [] }
        return list
    }()
    
    lazy var 添付資料一覧 : [FileMakerRecord] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "指示書工程写真保存テーブル") else { return [] }
        return list
    }()
    
    lazy var 集荷時間一覧 : [FileMakerRecord] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "集荷時間マスタ_確認用") else { return [] }
        return list
    }()
    
    lazy var 外注一覧 : [FileMakerRecord] = {
        guard let list : [FileMakerRecord] = record.portal(forKey: "資材発注テーブル") else { return [] }
        return list
    }()
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
        let list : [FileMakerRecord]? = db.find(layout: "エッチング指示書テーブル詳細営業以外用", query: [query])
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
        let list : [FileMakerRecord]? = db.find(layout: "エッチング指示書テーブル詳細", query: [query])
        return list?.compactMap { 指示書型($0) }
    }

    
    static func find(伝票番号:Int? = nil, 伝票種類:伝票種類型? = nil, 製作納期 range:ClosedRange<Date>? = nil,  出荷納期 range2:ClosedRange<Date>? = nil, limit:Int = 100) -> [指示書型]? {
        var query = [String:String]()
        if let num = 伝票番号 {
            query["伝票番号"] = "\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        if let range = range {
            query["製作納期"] = makeQueryDayString(range)
        }
        if let range2 = range2 {
            query["出荷納期"] = makeQueryDayString(range2)
        }
        let db = FileMakerDB.pm_osakaname
        let list : [FileMakerRecord]? = db.find(layout: "エッチング指示書テーブル詳細営業以外用", query: [query])
        return list?.compactMap { 指示書型($0) }
    }
    static func update(new管理用メモ:String, for伝票番号:Int? = nil) {
//        let fields = [String:String]()
//        fields[""]
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
