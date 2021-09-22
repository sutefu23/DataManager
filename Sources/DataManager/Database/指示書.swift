//
//  指示書進捗.swift
//  DataManager
//
//  Created by manager on 2019/02/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
import Foundation
#endif

public final class 指示書型: FileMakerImportRecord {
    public static let layout: String = "DataAPI_1"
    public static let name: String = "指示書"

    private let lock = NSRecursiveLock()
    
    public let recordId: String?
    public let uuid: UUID
    let 図URL: URL?

    public var 表示用伝票番号: String { 伝票番号.表示用文字列 }
    public let 略号: Set<略号型>
    public let 伝票番号: 伝票番号型

    public let 登録日時: Date
    public let 受注日: Day
    public let 出荷時間: Time?
    public let 伝票種類: 伝票種類型
    public let 伝票状態: 伝票状態型

    public let 工程状態: 工程状態型
    public let 承認状態: 承認状態型
    public let 伝票種別: 伝票種別型
    public let 経理状態: 経理状態型
    public let 部門: 部門型

    public let 製作納期: Day
    public let 出荷納期: Day

    public let 品名: String
    public let 仕様: String
    public let 寸法: String
    
    public let 社名: String
    public let 文字数: String
    public let セット数: String
    public let 備考: String
    public let 管理用メモ: String
    public let 営業用メモ: String

    public let 材質1: String
    public let 材質2: String
    public let 表面仕上1: String
    public let 表面仕上2: String
    public let 側面仕上1: String
    public let 側面仕上2: String
    public let 側面の高さ1: String
    public let 側面の高さ2: String

    public let 板厚1: String
    public let 板厚2: String

    public let 上段左: String
    public let 上段中央: String
    public let 上段右: String
    public let 下段左: String
    public let 下段中央: String
    public let 下段右: String

    public let 会社コード: String

    public let 単価1: Double
    public let 数量1: Int
    public let 単価4: Double
    public let 単価5: Double
    
    public let ボルト等1: String
    public let ボルト等2: String
    public let ボルト等3: String
    public let ボルト等4: String
    public let ボルト等5: String
    public let ボルト等6: String
    public let ボルト等7: String
    public let ボルト等8: String
    public let ボルト等9: String
    public let ボルト等10: String
    public let ボルト等11: String
    public let ボルト等12: String
    public let ボルト等13: String
    public let ボルト等14: String
    public let ボルト等15: String

    public let ボルト本数1: String
    public let ボルト本数2: String
    public let ボルト本数3: String
    public let ボルト本数4: String
    public let ボルト本数5: String
    public let ボルト本数6: String
    public let ボルト本数7: String
    public let ボルト本数8: String
    public let ボルト本数9: String
    public let ボルト本数10: String
    public let ボルト本数11: String
    public let ボルト本数12: String
    public let ボルト本数13: String
    public let ボルト本数14: String
    public let ボルト本数15: String

    public let 付属品1: String
    public let 付属品2: String
    public let 付属品3: String
    public let 付属品4: String
    public let 付属品5: String
    
    public let その他1: String
    public let その他2: String

    public let 枠材質: String
    public let 台板材質: String
    public let 裏仕様: String

    public let 枠仕上: String
    public let 枠寸法1: String
    public let 枠寸法2: String
    public let 枠寸法3: String
    public let 台板寸法: String
    
    public let 合計金額: Double
    
    public let 担当者1: 社員型?
    public let 担当者2: 社員型?
    public let 担当者3: 社員型?

    public let 発送事項: String
    
    public var memoryFootPrint: Int { return 200 * 8 } // 仮設定のため適当
    
    public required init(_ record: FileMakerRecord) throws {
        func makeError(_ key: String) -> Error { record.makeInvalidRecordError(name: Self.name, mes: key) }
        func getString(_ key: String) throws -> String {
            guard let string = record.string(forKey: key) else { throw makeError(key) }
            return string
        }
        func getInteger(_ key: String) throws -> Int {
            guard let value = record.integer(forKey: key) else { throw makeError(key) }
            return value
        }
        func getDay(_ key: String) throws -> Day {
            guard let day = record.day(forKey: key) else { throw makeError(key) }
            return day
        }
        func get社員(_ numberKey: String, _ nameKey: String) -> 社員型? {
            guard let num = record.integer(forKey: numberKey), let name = record.string(forKey: nameKey), num > 0 && num < 1000 && !name.isEmpty else { return nil }
            return prepare社員(社員番号: num, 社員名称: name)
        }
        guard let 登録日時 = record.date(dayKey: "登録日", timeKey: "登録時間") else { throw makeError("登録日時") }
        guard let 受注日 = record.day(forKey: "受注日") ?? record.day(forKey: "登録日") else { throw makeError("受注日")}
        guard let 伝票種類 = record.伝票種類(forKey: "伝票種類") else { throw makeError("伝票種類") }
        guard let 工程状態 = record.工程状態(forKey: "工程状態") else { throw makeError("工程状態") }
        guard let 承認状態 = record.承認状態(forKey: "承認状態") else { throw makeError("承認状態") }
        guard let 製作納期 = record.day(forKey: "製作納期") ?? record.day(forKey: "出荷納期") else { throw makeError("製作納期") }
        guard let 出荷納期 = record.day(forKey: "出荷納期") ?? record.day(forKey: "製作納期") else { throw makeError("出荷納期") }
        guard let 部門 = record.部門(forKey: "部門コード") else { throw makeError("部門") }
        guard let 伝票種別str = record.string(forKey: "伝票種別"), let 伝票種別 = 伝票種別型(伝票種別str) else { throw makeError("伝票種別") }
        guard let 経理状態 = record.経理状態(forKey: "経理状態") else { throw makeError("経理状態") }
        guard let uuidStr = record.string(forKey: "UUID"), let uuid = UUID(uuidString: uuidStr) else { throw makeError("UUID") }
        self.登録日時 = 登録日時
        self.受注日 = 受注日
        self.伝票種類 = 伝票種類
        self.工程状態 = 工程状態
        self.承認状態 = 承認状態
        self.製作納期 = 製作納期
        self.出荷納期 = 出荷納期
        self.部門 = 部門
        self.伝票種別 = 伝票種別
        self.経理状態 = 経理状態
        self.uuid = uuid
        
        self.略号 = try make略号(getString("略号"))
        self.伝票番号 = try 伝票番号型(validNumber: getInteger("伝票番号"))
        self.品名 = try getString("品名")
        self.仕様 = try getString("仕様")
        self.寸法 = try getString("寸法")
        
        self.社名 = try getString("社名")
        self.文字数 = try getString("文字数")
        self.セット数 = try getString("セット数")
        self.備考 = try getString("備考")
        self.管理用メモ = try getString("管理用メモ")
        self.営業用メモ = try getString("営業用メモ")

        self.材質1 = try getString("材質1")
        self.材質2 = try getString("材質2")
        self.表面仕上1 = try getString("表面仕上1")
        self.表面仕上2 = try getString("表面仕上2")
        self.側面仕上1 = try getString("側面仕上1")
        self.側面仕上2 = try getString("側面仕上2")
        self.側面の高さ1 = try getString("側面の高さ1")
        self.側面の高さ2 = try getString("側面の高さ2")

        self.板厚1 = try getString("板厚1")
        self.板厚2 = try getString("板厚2")

        self.上段左 = try getString("上段左")
        self.上段中央 = try getString("上段中央")
        self.上段右 = try getString("上段右")
        self.下段左 = try getString("下段左")
        self.下段中央 = try getString("下段中央")
        self.下段右 = try getString("下段右")

        self.担当者1 = get社員("社員番号1", "担当者1")
        self.担当者2 = get社員("社員番号2", "担当者2")
        self.担当者3 = get社員("社員番号3", "担当者3")
        
        
        self.ボルト等1 = try getString("ボルト等1")
        self.ボルト等2 = try getString("ボルト等2")
        self.ボルト等3 = try getString("ボルト等3")
        self.ボルト等4 = try getString("ボルト等4")
        self.ボルト等5 = try getString("ボルト等5")
        self.ボルト等6 = try getString("ボルト等6")
        self.ボルト等7 = try getString("ボルト等7")
        self.ボルト等8 = try getString("ボルト等8")
        self.ボルト等9 = try getString("ボルト等9")
        self.ボルト等10 = try getString("ボルト等10")
        self.ボルト等11 = try getString("ボルト等11")
        self.ボルト等12 = try getString("ボルト等12")
        self.ボルト等13 = try getString("ボルト等13")
        self.ボルト等14 = try getString("ボルト等14")
        self.ボルト等15 = try getString("ボルト等15")

        self.ボルト本数1 = try getString("ボルト本数1")
        self.ボルト本数2 = try getString("ボルト本数2")
        self.ボルト本数3 = try getString("ボルト本数3")
        self.ボルト本数4 = try getString("ボルト本数4")
        self.ボルト本数5 = try getString("ボルト本数5")
        self.ボルト本数6 = try getString("ボルト本数6")
        self.ボルト本数7 = try getString("ボルト本数7")
        self.ボルト本数8 = try getString("ボルト本数8")
        self.ボルト本数9 = try getString("ボルト本数9")
        self.ボルト本数10 = try getString("ボルト本数10")
        self.ボルト本数11 = try getString("ボルト本数11")
        self.ボルト本数12 = try getString("ボルト本数12")
        self.ボルト本数13 = try getString("ボルト本数13")
        self.ボルト本数14 = try getString("ボルト本数14")
        self.ボルト本数15 = try getString("ボルト本数15")

        self.付属品1 = try getString("付属品1")
        self.付属品2 = try getString("付属品2")
        self.付属品3 = try getString("付属品3")
        self.付属品4 = try getString("付属品4")
        self.付属品5 = try getString("付属品5")

        self.その他1 = try getString("その他1")
        self.その他2 = try getString("その他2")

        self.枠材質 = try getString("枠材質")
        self.台板材質 = try getString("台板材質")
        self.裏仕様 = try getString("裏仕様")

        self.枠仕上 = try getString("枠仕上")
        self.枠寸法1 = try getString("枠寸法1")
        self.枠寸法2 = try getString("枠寸法2")
        self.枠寸法3 = try getString("枠寸法3")
        self.台板寸法 = try getString("台板寸法")
        
        self.図URL = record.url(forKey: "図")
        self.伝票状態 = record.伝票状態(forKey: "伝票状態") ?? .未製作
        self.会社コード = record.string(forKey: "会社コード") ?? ""
        
        self.単価1 = record.double(forKey: "単価1") ?? 0
        self.数量1 = record.integer(forKey: "数量1") ?? 0
        self.単価4 = record.double(forKey: "単価4") ?? 0
        self.単価5 = record.double(forKey: "単価5") ?? 0
        self.合計金額 = record.double(forKey: "合計金額") ?? 0
        self.出荷時間 = try Time(fmTime: getString("連絡欄1"))
        self.発送事項 = record.string(forKey: "発送事項") ?? ""
        self.recordId = record.recordId
    }
        
    public lazy var 比較用伝票番号: Int = {
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
    
    public lazy var 取引先: 取引先型? = { try? 取引先型.find(会社コード: self.会社コード) }()

    public lazy var 寸法サイズ: [Double] = { calc寸法サイズ(self.寸法) }()

    public lazy var 箱文字側面高さ: [Double] = { calc箱文字側面高さ(self.側面の高さ1) + calc箱文字側面高さ(self.側面の高さ2) }()
    public lazy var 箱文字以外側面高さ: [Double] = { calc箱文字以外側面高さ(self.側面の高さ1) + calc箱文字以外側面高さ(self.側面の高さ2) }()

    
    public lazy var インシデント一覧: [インシデント型] = {
        let list = self.進捗一覧.map { インシデント型($0) } + self.変更一覧.map { インシデント型($0) }
        return list.sorted { $0.日時 < $1.日時 }
    }()
    
    public var is原稿封筒社名印刷あり: Bool {
        if self.管理用メモ.contain("原稿封筒社名必要") { return true }
        if self.管理用メモ.contain("原稿封筒社名不要") { return false }
        if self.備考.contain("原稿封筒社名必要") { return true }
        if self.備考.contain("原稿封筒社名不要") { return false }
        return self.取引先?.is原稿社名不要 != true
    }
    
    #if os(Linux) || os(Windows)
    #else
    public lazy var 図: DMImage? = {
        lock.lock()
        defer { lock.unlock() }
        guard let url = self.図URL else { return nil }
        let db = FileMakerDB.pm_osakaname
        guard let 一覧 = try? db.downloadObject(url: url) else { return nil }
        let image = DMImage(data: 一覧)
        return image
    }()
    #endif
    public var 進捗一覧: [進捗型] { return (try? 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号)?.進捗一覧) ?? [] }
    public var 工程別進捗一覧: [工程型: [進捗型]] { return (try? 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号)?.工程別進捗一覧) ?? [:] }
    public var 作業進捗一覧: [進捗型] { return (try? 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号)?.作業進捗一覧) ?? [] }
    
    public lazy var 変更一覧: [指示書変更内容履歴型] = {
        let list = (try? 指示書変更内容履歴型.find(指示書uuid: self.uuid))?.sorted { $0.日時 < $1.日時 } ?? []
        return list
    }()
    
    public lazy var 外注一覧: [発注型] = {
        let list = (try? 発注型.find(伝票番号: self.伝票番号, 発注種類: .外注)) ?? []
        return list
    }()
    
    public lazy var 進捗入力記録一覧: [作業記録型] = self.make進捗入力記録一覧()
    public lazy var 工程別作業記録: [工程型 : [作業記録型]] = Dictionary(grouping: self.進捗入力記録一覧) { $0.工程 }
    
    public lazy var 承認情報: 指示書変更内容履歴型? = { return self.変更一覧.filter { $0.種類 == .指示書承認 }.max { $0.日時 < $1.日時 } }()

    public var 塗装文字数概算: Int {
        let leftLast, rightLast: Int
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
    
    public var 製作文字数概算: Int {
        let leftLast, rightLast: Int
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
        return self.isDouble ? total*2 : total
    }

    public var isDouble: Bool {
        switch self.伝票種類 {
        case .箱文字:
            let type = self.仕様
            return type.contains("W") || type.contains("Ｗ") || type.contains("リング") || (type.contains("表") && type.contains("バック"))
        case .切文字, .エッチング, .加工, .外注, .校正:
            return false
        }
    }
    
    public var is外注塗装あり: Bool {
        return self.外注一覧.contains { 取引先型.外注先会社コード.contains($0.会社コード) }
    }
    
    public var is内作塗装あり: Bool {
        return self.進捗一覧.contains {
            return $0.工程 == .塗装 && ($0.作業内容 == .開始 || $0.作業内容 == .完了)
        }
    }
    
    public var is外注シートあり: Bool {
        return self.外注一覧.contains { $0.会社コード == "0074" }
    }
    
    public var is社内研磨あり: Bool {
        return self.進捗一覧.contains {
            return $0.工程 == .研磨 && ($0.作業内容 == .開始 || $0.作業内容 == .完了)
        }
    }
    
    /// 半田かどうか
    public var is半田あり: Bool {
        return self.略号.contains(.半田) || self.is旧半田
    }
    var is旧半田 : Bool { self.伝票種類 == .箱文字 && (self.上段右.contains("ハ") || self.下段右.contains("ハ")) }

    /// 溶接かどうか
    public var is溶接あり: Bool {
        return self.略号.contains(.溶接) || self.is旧溶接
    }
    var is旧溶接 : Bool { self.伝票種類 == .箱文字 && (self.上段右.contains("ヨ") || self.下段右.contains("ヨ")) }

    var is旧美濃在庫 : Bool {
        return 伝票種類 == .切文字 && 社名.contains("美濃クラフト") && 品名.containsOne(of: "AS", "RX", "EP", "MX", "HT", "ワンロック", "モック")
    }
    
    public var is承認済有効: Bool {
        return self.承認状態 == .承認済 && self.伝票状態 != .キャンセル
    }
    
    public var isオブジェ: Bool {
        return self.伝票種類 == .加工 && self.仕様.toJapaneseNormal.contains("オブジェ") == true
    }
    
    public var isフォーミングのみ: Bool {
        return self.略号.contains(.フォーミング) && !self.略号.contains(.レーザー)
    }
    
    public var isレーザーのみ: Bool {
        return !self.略号.contains(.フォーミング) && self.略号.contains(.レーザー)
    }
    
    public var 金額: Double {
        var value = self.合計金額
        if value <= 0 {
            value = self.単価1
            let count = self.単価1
            if count > 0 { value += count }
        }
        return value
    }
    
    public var 保留校正一覧: [作業型] {
        lock.lock()
        defer { lock.unlock() }
        if let cache = 保留校正一覧Cache { return cache }
        let list = (self.保留一覧 + self.校正一覧).sorted { $0.開始日時 < $1.開始日時 }
        保留校正一覧Cache = list
        return list
    }
    private var 保留校正一覧Cache: [作業型]?
    
    public var 保留一覧: [作業型] {
        lock.lock()
        defer { lock.unlock() }
        if let cache = 保留一覧Cache { return cache }
        var list = [作業型]()
        var from: Date?
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
        保留一覧Cache = list
        return list
    }
    private var 保留一覧Cache: [作業型]?
    
    public var 校正一覧: [作業型] {
        lock.lock()
        defer { lock.unlock() }
        if let cache = 校正一覧Cache { return cache }
        var list = [作業型]()
        var from: Date?
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
        校正一覧Cache = list
        return list
    }
    private var 校正一覧Cache: [作業型]?

    public lazy var 半田溶接振り分け: String = {
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
    
    /// FileMakerで指示書を表示する
    public func showInfo() {
        self.伝票番号.showInfo()
    }
    
    func prepareCache() {
        let _ = self.工程別作業記録
    }
    
    public lazy var レーザー加工機: Set<レーザー加工機型> = {
        var set = Set<レーザー加工機型>()
        for progress in self.進捗一覧 where progress.作業内容 == .開始 {
            if let machine = progress.レーザー加工機 {
                set.insert(machine)
            }
        }
        return set
    }()
    
    public lazy var 立ち上がりランク: 立ち上がりランク型 = {
        if let comp = self.進捗一覧.findFirst(工程: .照合検査, 作業内容: .完了) { // 照合完了済み
            if let progress = self.進捗一覧.first(where: { $0.工程 == .立ち上がり }) { // 立ち上がり作業あり
                if comp.登録日時 >= progress.登録日時 { // 立ち上がり作業が先
                    return .立ち上がり先行受取済み_青
                }
            }
        } else { // 照合未完了
            if self.進捗一覧.contains(where: { $0.工程 == .立ち上がり }) { // 立ち上がり作業あり
                return .立ち上がり先行受取待ち_赤
            }
        }
        return .通常_黒
    }()
    
    public lazy var 状態表示（２文字）: String = {
        switch self.伝票状態 {
        case .キャンセル:
            return "キャ"
        case .発送済:
            switch self.経理状態 {
            case .未登録, .受注処理済:
                return "発送"
            case .売上処理済:
                return "売上"
            }
        case .未製作, .製作中:
            switch 工程状態 {
            case .校正中:
                return "校正"
            case .保留:
                return "保留"
            case .通常:
                return "通常"
            }
        }
    }()
    
    public lazy var ボルト資材情報: [Int: 資材要求情報型] = {
        var map: [Int: 資材要求情報型] = [:]
        var sizeSet = Set<String>()
//        let set = self.セット数値
        let set = 1.0
        for index in 1...15 {
            var name = self.ボルト等(index) ?? ""
            let count = self.ボルト本数(index) ?? ""
            if let info = try? 資材要求情報型(ボルト欄: name, 数量欄: count, セット数: set, 伝票種類: self.伝票種類) {
                map[index] = info
                if case .ボルト(let size, _) = info.資材種類 {
                    sizeSet.insert(size)
                }
            }
        }
        if sizeSet.count == 1, let size = sizeSet.first {
            for index in 1...15 {
                guard map[index] == nil else { continue }
                var name = self.ボルト等(index) ?? ""
                var scanner = DMScanner(name, normalizedFullHalf: true, upperCased: true)
                if scanner.hasPrefix("ナット") {
                    guard scanner.scanナット() == nil else { continue }
                    name = "ナットM\(size)"
                } else if scanner.hasPrefix("平W") {
                    name = "ワッシャーM\(size)"
                } else {
                    continue
                }
                let count = self.ボルト本数(index) ?? ""
                if let info = try? 資材要求情報型(ボルト欄: name, 数量欄: count, セット数: set, 伝票種類: self.伝票種類) {
                    map[index] = info
                }
            }
        }
        return map
    }()
    
    public lazy var 付属品: Set<String> = {
        var set = Set<String>()
        for str in [付属品1, 付属品2, 付属品3, 付属品4, 付属品5] {
            if !str.isEmpty {
                set.insert(str)
            }
        }
        return set
    }()
    
    public lazy var 発送事項出荷時間: Time? = {
        var scanner = DMScanner(self.発送事項, normalizedFullHalf: true, skipSpaces: true)
        while let (_, time) = scanner.scanUpToTime() {
            if scanner.scanStrings(出荷時間文言リスト1) != nil { return time }
        }
        scanner.reset()
        scanner.skip数字以外()
        while !scanner.isAtEnd {
            if let value = scanner.scanInteger(), value >= 0 && value <= 24 {
                if scanner.scanStrings(出荷時間文言リスト2) != nil {
                    if let day = scanner.reverseScanDay(), day != self.出荷納期 { return nil } // 出荷納期と違う
                    return Time(value, 00)
                } else if scanner.scanStrings(出荷時間文言リスト3) != nil {
                    if let day = scanner.reverseScanDay(), day != self.出荷納期 { return nil } // 出荷納期と違う
                    return Time(value, 30)
                }
            }
            scanner.skip数字以外()
        }
        return nil
    }()
    public lazy var 発送事項完成時間: Time? = {
        var scanner = DMScanner(self.発送事項, normalizedFullHalf: true, skipSpaces: true)
        while let (_, time) = scanner.scanUpToTime() {
            if scanner.scanString("完成") { return time }
        }
        return nil
    }()
}

extension 指示書型 {
    public var 台板サイズ: (height: Double, width: Double)? {
        var scanner = DMScanner(self.台板寸法, normalizedFullHalf: true, upperCased: true, skipSpaces: true, newlineToSpace: true)
        scanner.scanString("H")
        guard let height = scanner.scanDouble() else { return nil }
        scanner.scanString("*")
        scanner.scanString("W")
        guard let width = scanner.scanDouble() else { return nil }
        return (height: height, width: width)
    }
    
    public func is分納相手完納済み(自工程: 工程型) throws -> Bool? {
        var result: Bool? = nil
        for info in self.ボルト資材情報.values {
            guard let isOk = try info.is分納相手完納済み(self, 自工程: 自工程) else { continue }
            if isOk == false { return false }
            result = true
        }
        return result
    }
    public func isボルト欄資材完了() throws -> Bool {
        for info in self.ボルト資材情報.values {
            if try !info.allRegistered(self) { return false }
        }
        return true
    }
    
    public var 外注メッキあり: Bool {
        return 外注一覧.contains {
            if $0.会社コード == "2981" { return true } // 九州電化
            return false
        }
    }

    public var 外注塗装あり: Bool {
        return 外注一覧.contains {
            if $0.会社コード == "2971" { return true } // アラヤ
            if $0.会社コード == "2993" { return true } // トキワ
            if $0.会社コード == "4442" { return true } // 久野
            return false
        }
    }
    
    public var 社内塗装あり: Bool {
        表面社内塗装あり || 側面社内塗装あり
    }
    
    public var 表面社内塗装あり: Bool {
        func check(_ target: String) -> Bool {
            return target.contains("塗装") && !target.contains("先方")
        }
        return check(表面仕上1) || check(表面仕上2)
    }
    
    public var 側面社内塗装あり: Bool {
        func check(_ target: String) -> Bool {
            return target.contains("塗装") && !target.contains("先方")
        }
        return check(側面仕上1) || check(側面仕上2)
    }
    
    #if os(Linux) || os(Windows)
    #else
    public func 色付き略号(fontSize: CGFloat = 12, colorMapper:(略号型) -> DMColor = { $0.表示色 } ) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        for mark in self.略号.sorted() {
            let color: DMColor = colorMapper(mark) 
            result.append(mark.code.makeAttributedString(color: color, size: fontSize, fontName: nil))
        }
        return result
    }
    #endif
    
    public func contains(工程: 工程型) -> Bool { return self.工程別進捗一覧[工程]?.isEmpty == false }
    public func contains(工程: 工程型, 作業内容: 作業内容型) -> Bool { return self.工程別進捗一覧[工程]?.contains(where: { $0.作業内容 == 作業内容 }) == true }
    public func contains(工程: 工程型, 作業内容: 作業内容型, 作業系列: 作業系列型?) -> Bool {
        guard let 作業系列 = 作業系列 else { return contains(工程: 工程, 作業内容: 作業内容) }
        return self.工程別進捗一覧[工程]?.contains(where: { $0.作業内容 == 作業内容 && $0.作業系列 == 作業系列 }) == true
    }

    public var is箱文字アクリのみ: Bool {
        if self.伝票種類 != .箱文字 { return false }
        return self.管理用メモ.contains("アクリのみ")
    }
    public var セット数値: Double {
        switch self.伝票種類 {
        case .切文字, .箱文字, .校正, .外注:
            var result = 1.0
            var scanner = DMScanner(self.セット数, normalizedFullHalf: true, skipSpaces: true)
            while !scanner.isAtEnd {
                scanner.skip数字以外()
                if let value = scanner.scanDouble(), value > result {
                    result = value
                }
            }
            return result
        case .加工, .エッチング:
            return Double(self.文字数) ?? 1.0
        }
    }
    
    public func 通常最終作業(工程: 工程型, 作業内容: 作業内容型) -> 進捗型? {
        guard let last = self.工程別進捗一覧[工程]?.filter({ $0.作業内容 == 作業内容 && $0.作業種別 == .通常 }).last else { return nil }
        return last
    }
    
    public func ボルト等(_ index: Int) -> String? {
        switch index {
        case 1: return self.ボルト等1
        case 2: return self.ボルト等2
        case 3: return self.ボルト等3
        case 4: return self.ボルト等4
        case 5: return self.ボルト等5
        case 6: return self.ボルト等6
        case 7: return self.ボルト等7
        case 8: return self.ボルト等8
        case 9: return self.ボルト等9
        case 10: return self.ボルト等10
        case 11: return self.ボルト等11
        case 12: return self.ボルト等12
        case 13: return self.ボルト等13
        case 14: return self.ボルト等14
        case 15: return self.ボルト等15
        default: return nil
        }
    }
    
    public func ボルト本数(_ index: Int) -> String? {
        switch index {
        case 1: return self.ボルト本数1
        case 2: return self.ボルト本数2
        case 3: return self.ボルト本数3
        case 4: return self.ボルト本数4
        case 5: return self.ボルト本数5
        case 6: return self.ボルト本数6
        case 7: return self.ボルト本数7
        case 8: return self.ボルト本数8
        case 9: return self.ボルト本数9
        case 10: return self.ボルト本数10
        case 11: return self.ボルト本数11
        case 12: return self.ボルト本数12
        case 13: return self.ボルト本数13
        case 14: return self.ボルト本数14
        case 15: return self.ボルト本数15
        default: return nil
        }
    }
    
    public func 現在資材使用記録() throws -> [資材使用記録型]? {
        return try 資材使用記録キャッシュ型.shared.現在資材使用記録(伝票番号: self.伝票番号)
    }

    public func キャッシュ資材使用記録() throws -> [資材使用記録型]? {
        return try 資材使用記録キャッシュ型.shared.キャッシュ資材使用記録(伝票番号: self.伝票番号)
    }
    
    public func 最終完了日時(_ group: [工程型]) -> Date? {
        var result: Date? = nil
        for process in group {
            guard let date = self.工程別作業記録[process]?.last?.完了日時 else { continue }
            if let current = result, current > date { continue }
            result = date
        }
        return result
    }
    
    public func 最速開始日時(_ group: [工程型]) -> Date? {
        var result: Date? = nil
        for process in group {
            guard let date = self.工程別作業記録[process]?.first?.開始日時 else { continue }
            if let current = result, current < date { continue }
            result = date
        }
        return result
    }
    
    public var 作り直しリードタイム: (isOk: Bool, interval: TimeInterval)? {
        let source = self.進捗一覧.sorted { $0.登録日時 < $1.登録日時 }
        var list = source.filter { $0.作業種別 == .作直 }
        guard let list0 = list.first else { return nil }
        let head = source.filter { $0.作業内容 == .仕掛 }.reversed()
        for progress in head {
            if progress.登録日時 < list0.登録日時 {
                list.insert(progress, at: 0)
                break
            }
        }
        if list.count <= 1 { return nil }
        let first = list[0].登録日時
        let last = list.last!.登録日時
        var isOk = true
        let state0 = list[0].工程
        if list.last!.工程 != state0 {
            let test = source.filter { $0.登録日時 > last }
            for progress in test {
                let state = progress.工程
                if state == state0 || state == .発送 { break }
                if state < state0 {
                    isOk = false
                    break
                }
            }
        }
        return (isOk, TimeInterval(工程: nil, 作業開始: first, 作業完了: last))
    }
    
    public var アクリル開始時間: Date? {
        guard let source = self.工程別進捗一覧[.レーザー（アクリル）] else { return nil }
        return source.filter { $0.作業系列 == .hp && $0.作業内容 == .開始 && $0.作業種別 == .通常 }.last?.登録日時

    }
    
    public var アクリル完了時間: Date? {
        guard let source0 = self.工程別進捗一覧[.レーザー（アクリル）] else { return nil }
        guard let from = source0.filter({ $0.作業系列 == .hp && $0.作業内容 == .開始 && $0.作業種別 == .通常 }).last else { return nil }
        let source2 = self.工程別進捗一覧[.レーザー] ?? []
        let source = self.工程別進捗一覧[.レーザー（アクリル）] ?? []
        let target = (source+source2).filter { ($0.作業系列 == .hp || $0.作業系列 == nil) && $0.作業内容 == .完了 && $0.作業種別 == .通常 && $0.登録日時 > from.登録日時 }.sorted { $0.登録日時 < $1.登録日時 }
        if let result = target.filter({ $0.作業系列 == .hp || $0.作業者 == from.作業者 }).last { return result.登録日時 }
        return target.last?.登録日時
    }
    
    /// 伝票状態が正常ならtrueを返す
    public var isValid伝票状態: Bool {
        switch self.伝票種類 {
        case .校正:
            switch self.伝票状態 {
            case .キャンセル, .未製作:
                return true
            case .製作中, .発送済:
                return false
            }
        case .エッチング, .切文字, .加工, .箱文字, .外注:
            break
        }
        switch self.伝票状態 {
        case .キャンセル, .未製作:
            return true
        case .製作中:
            return
                self.承認状態 == .承認済 &&
                self.進捗一覧.contains(工程: .発送, 作業内容: .完了) == false
        case .発送済:
            return
                self.承認状態 == .承認済 &&
                self.進捗一覧.contains(工程: .発送, 作業内容: .完了) == true
        }
    }
}

public enum 立ち上がりランク型: Int, Comparable, Hashable {
    case 立ち上がり先行受取済み_青 = 1
    case 立ち上がり先行受取待ち_赤 = 2
    case 通常_黒 = 3
    
    public static func < (left: 立ち上がりランク型, right: 立ち上がりランク型) -> Bool {
        return left.rawValue < right.rawValue
    }
}

// MARK: - 検索パターン
public extension 指示書型 {
//    static let dbName = "DataAPI_1"
//    static func find(_ query: FileMakerQuery) throws -> [指示書型] {
//        let db = FileMakerDB.pm_osakaname
//        let list: [FileMakerRecord] = try db.find(layout: 指示書型.dbName, query: [query])
//        let orders = try list.map { try 指示書型($0) }
//        return orders
//    }

    /// 通常種類の指示書を検索する
    internal static func normalFind(_ query: FileMakerQuery, filter: (指示書型) -> Bool) throws -> [指示書型] {
        var result: [指示書型] = []
        var error2: Error? = nil
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: 4) {
            lock.lock()
            var query2 = query
            let type: 伝票種類型
            switch $0 {
            case 0:
                type = .切文字
            case 1:
                type = .加工
            case 2:
                type = .箱文字
            case 3:
                type = .エッチング
            default:
                fatalError()
            }
            query2["伝票種類"] = type.fmString
            lock.unlock()
            do {
                let orders = try 指示書型.find(query: query2).filter {
                    switch $0.伝票状態 {
                    case .キャンセル:
                        return false
                    case .未製作, .発送済, .製作中:
                        return filter($0)
                    }
                }
                lock.lock()
                result.append(contentsOf: orders)
                lock.unlock()
            } catch {
                lock.lock()
                error2 = error
                lock.unlock()
            }
        }
        if let error2 = error2 {
            throw error2
        }
        return result
    }

    static func find(伝票番号: 伝票番号型? = nil, 伝票種類: 伝票種類型? = nil, 製作納期: Day? = nil, limit: Int = 100) throws -> [指示書型] {
        var query = FileMakerQuery()
        if let num = 伝票番号 {
            query["伝票番号"] = "==\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        query["製作納期"] = 製作納期?.fmString
        return try find(query: query)
    }
    
    static func find2(伝票番号: 伝票番号型? = nil, 伝票種類: 伝票種類型? = nil, 製作納期: Day? = nil, limit: Int = 100) throws -> [指示書型] {
        var query = FileMakerQuery()
        if let num = 伝票番号 {
            query["伝票番号"] = "==\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        query["製作納期"] = 製作納期?.fmString
        return try find(query: query)
    }
    
    static func find(伝票番号: 伝票番号型? = nil, 伝票種類: 伝票種類型? = nil, 受注日 range0: ClosedRange<Day>? = nil, 製作納期 range: ClosedRange<Day>? = nil,  出荷納期 range2: ClosedRange<Day>? = nil, 伝票状態: 伝票状態型? = nil, 進捗準備: Bool = false) throws -> [指示書型] {
        var query = FileMakerQuery()
        if let num = 伝票番号 {
            query["伝票番号"] = "==\(num)"
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
        query["伝票状態"] = 伝票状態?.description
        let list = try find(query: query)
        if 進捗準備 { list.forEach { let _ = $0.工程別進捗一覧 } }
        return list
    }
        
    static func new_find(作業範囲 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil) throws -> [指示書型] {
        let progress = try 進捗型.find(登録期間: range, 伝票種類: type)
        let list = Set<伝票番号型>(progress.map{ $0.伝票番号 })
        let queue = OperationQueue()
        let queue2 = OperationQueue()
        let lock = NSLock()
        queue.maxConcurrentOperationCount = 2
        var results: [Result<指示書型, Error>] = []
        results.reserveCapacity(list.count)
        for number in list {
            queue.addOperation {
                let result: Result<指示書型, Error>
                do {
                    guard let order = try 指示書型.findDirect(伝票番号: number) else { return }
                    queue2.addOperation { order.prepareCache() }
                    result = .success(order)
                } catch {
                    result = .failure(error)
                }
                lock.lock()
                results.append(result)
                lock.unlock()
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        queue2.waitUntilAllOperationsAreFinished()
        return try results.map { try $0.get() }
    }
    
    /// 指定された範囲内に作業が存在する指示書
    static func find(作業範囲 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["受注日"] = "<=\(range.upperBound.fmString)"
        query["出荷納期"] = ">=\(range.lowerBound.fmString)"
        query["伝票種類"] = type?.fmString
        return try find(query: query)
    }

    static func find(有効日: Day, 伝票種類: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["受注日"] = "<=\(有効日.fmString)"
        query["出荷納期"] = ">=\(有効日.fmString)"
        if let type = 伝票種類 {
            query["伝票種類"] = "==\(type.fmString)"
        }
        return try find(query: query)
    }

    static func find(最小製作納期 day: Day, 伝票種類 type: 伝票種類型?) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["製作納期"] = ">=\(day.fmString)"
        query["伝票種類"] = type?.fmString
        
        return try find(query: query)
    }
    
    static func find(最小製作納期 day: Day, short: 略号型) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["製作納期"] = ">=\(day.fmString)"
        query["略号"] = "=*\(short.code)*"
        
        return try find(query: query)
    }
    
    static func find(出荷納期: Day, 発送事項: String) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["出荷納期"] = 出荷納期.fmString
        query["発送事項"] = 発送事項
        return try find(query: query)
    }

    static func find(出荷納期: ClosedRange<Day>, 発送事項: String) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["出荷納期"] = makeQueryDayString(出荷納期)
        query["発送事項"] = 発送事項
        return try find(query: query)
    }

    static func find(進捗入力日 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil, 工程: 工程型? = nil, 作業内容: 作業内容型? = nil) throws -> [指示書型] {
        let list = try 進捗型.find(登録期間: range, 伝票種類: type, 工程: 工程, 作業内容: 作業内容)
        var numbers = Set<伝票番号型>()
        for progress in list {
            let num = progress.伝票番号
            numbers.insert(num)
        }
        var result: [指示書型] = []
        for num in numbers {
            if let order = try 指示書型.find(伝票番号: num).first {
                result.append(order)
            }
        }
        return result
    }

    var isActive: Bool {
        switch self.伝票状態 {
        case .キャンセル, .発送済:
            return false
        case .未製作, .製作中:
            break
        }
        switch self.承認状態 {
        case .承認済:
            return true
        case .未承認:
            return false
        }
    }
    
    static func find製作納期Active(伝票種類: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        let today = Date()
        query["製作納期"] = ">=\(today.day.fmString)"
        query["伝票種類"] = 伝票種類?.fmString
        return try find(query: query).filter { $0.isActive }
    }

    static func findActive(伝票種類: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        let today = Date()
        query["出荷納期"] = ">=\(today.day.fmString)"
        query["伝票種類"] = 伝票種類?.fmString
        return try find(query: query).filter { $0.isActive }
    }
    
    static func old_find2(作業範囲 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["受注日"] = "<=\(range.upperBound.fmString)"
        query["出荷納期"] = ">=\(range.lowerBound.fmString)"
        query["伝票種類"] = type?.fmString
        return try find(query: query)
    }
    
    static func find(登録日 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        query ["登録日"] = makeQueryDayString(range)
        query["伝票種類"] = type?.fmString
        return try find(query: query)
    }

    static func findDirect(伝票番号文字列: String?) throws -> 指示書型? {
        guard let str = 伝票番号文字列, let number = try 伝票番号型(invalidString: str) else { return nil }
        return try findDirect(伝票番号: number)
    }
    
    static func findDirect(伝票番号: 伝票番号型) throws -> 指示書型? {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号)"
        let orders = try 指示書型.find(query: query)
        if orders.count == 1 {
            return orders[0]
        } else {
            return nil
        }
    }
    
    static func findDirect(uuid: UUID) throws -> 指示書型? {
        var query = FileMakerQuery()
        query["UUID"] = uuid.uuidString
        let orders = try 指示書型.find(query: query)
        if orders.count == 1 {
            return orders[0]
        } else {
            return nil
        }
    }
    
    static func find(工程: 工程型, 伝票種類: Set<伝票種類型>, 基準製作納期: Day) throws -> [指示書型] {
        var plist = [進捗型]()
        for type in 伝票種類 {
            let list = try 進捗型.find(工程: 工程, 伝票種類: type, 基準製作納期: 基準製作納期)
            plist.append(contentsOf: list)
        }
        let orders = try Set<伝票番号型>(plist.map{ $0.伝票番号 }).compactMap { try 指示書型.findDirect(伝票番号: $0) }.filter {
            switch $0.伝票状態 {
            case .キャンセル, .発送済, .未製作:
                return false
            case .製作中:
                return true
            }
        }
        return orders.sorted {
            if $0.製作納期 != $1.製作納期 { return $0.製作納期 < $1.製作納期 }
            return $0.伝票番号 < $1.伝票番号
        }
    }
    
    static func normalFind(作業範囲 range: ClosedRange<Day>, filter: (指示書型) -> Bool = { _ in return true }) throws -> [指示書型] {
        var query1 = FileMakerQuery()
        var query2 = FileMakerQuery()
        query1["出荷納期"] = ">\(range.upperBound.fmString)"
        query1["受注日"] = "<=\(range.upperBound.fmString)"
        query2["出荷納期"] = makeQueryDayString(range)
        return try (normalFind(query1, filter: filter) + normalFind(query2, filter: filter)).sorted { $0.伝票番号 < $1.伝票番号 }
    }
    
    static func normalFind(製作納期 range: ClosedRange<Day>, filter: (指示書型) -> Bool = { _ in return true }) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["製作納期"] = makeQueryDayString(range)
        return try normalFind(query, filter: filter)
    }

    static func normalFind(出荷納期 range: ClosedRange<Day>, filter: (指示書型) -> Bool = { _ in return true }) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["出荷納期"] = makeQueryDayString(range)
        return try normalFind(query, filter: filter)
    }
}

// MARK: - 出荷時間チェック文言
/// hh:mmの後ろに続く文言
private let 出荷時間文言リスト1: [String] = {
    var result: [String] = []
    for word0 in ["", "以降", "までに"] {
        for word1 in ["", "先方"] {
            for word2 in ["出荷", "積込", "持込", "引取", "積み込み", "持ち込み", "引き取り"] {
                result.append(word0 + word1 + word2)
            }
        }
    }
    return result.sorted { $0.count > $1.count }
}()

/// hhの後ろに続く文言を生成する
private func make出荷時間文言リスト23(_ head: String) -> [String] {
    var result: [String] = []
    for word0 in ["", "頃", "まで", "までに", "以降"] {
        for word1 in ["出荷", "積込", "持込", "引取", "積み込み", "持ち込み", "引き取り"] {
            result.append(head + word0 + word1)
        }
    }
    return result.sorted { $0.count > $1.count }
}

/// hhの後ろに続く文言（mm=0）
private let 出荷時間文言リスト2: [String] = make出荷時間文言リスト23("時")
/// hhの後ろに続く文言（mm=30）
private let 出荷時間文言リスト3: [String] = make出荷時間文言リスト23("時半")
