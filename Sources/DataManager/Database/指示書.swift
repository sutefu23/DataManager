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

let 外注先会社コード: Set<String> = ["2971", "2993", "4442",  "3049", "3750"]
private let lock = NSLock()

public final class 指示書型 {
    let record: FileMakerRecord
    
    init?(_ record: FileMakerRecord) {
        self.record = record
    }
    
    public lazy var 伝票番号: 伝票番号型 = {
        let num = record.integer(forKey: "伝票番号")!
        return 伝票番号型(validNumber: num)
    }()
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
    public lazy var 表示用伝票番号: String = { record.string(forKey: "表示用伝票番号")! }()
    public lazy var 略号: Set<略号型> = { make略号(record.string(forKey: "略号")!) }()
    
    public lazy var 登録日時: Date = { record.date(dayKey: "登録日", timeKey: "登録時間")! }()
    public lazy var 受注日: Day = { record.day(forKey: "受注日") ?? record.day(forKey: "登録日")! }()
    public lazy var 伝票種類: 伝票種類型  = { record.伝票種類(forKey: "伝票種類")! }()
    public lazy var 伝票状態: 伝票状態型 = { record.伝票状態(forKey: "伝票状態") ?? .未製作 }()
    public lazy var 工程状態: 工程状態型 = { record.工程状態(forKey: "工程状態")! }()
    public lazy var 承認状態: 承認状態型 = { record.承認状態(forKey: "承認状態")! }()
    public lazy var 製作納期: Day = { record.day(forKey: "製作納期") ?? record.day(forKey: "出荷納期")! }()
    public lazy var 出荷納期: Day = { record.day(forKey: "出荷納期") ?? record.day(forKey: "製作納期")! }()
    
    public lazy var 取引先: 取引先型? = { try? 取引先型.find(会社コード: self.会社コード) }()
    
    public var 品名: String { record.string(forKey: "品名")! }
    public var 仕様: String { record.string(forKey: "仕様")! }
    public var 寸法: String { record.string(forKey: "寸法")! }
    public lazy var 寸法サイズ: [Double] = { calc寸法サイズ(self.寸法) }()
    public var 社名: String { record.string(forKey: "社名")! }
    public var 文字数: String { record.string(forKey: "文字数")! }
    public var セット数: String { record.string(forKey: "セット数")! }
    public var 備考: String { record.string(forKey: "備考")! }
    public var 管理用メモ: String { record.string(forKey: "管理用メモ")! }

    public var 材質1: String { record.string(forKey: "材質1")! }
    public var 材質2: String { record.string(forKey: "材質2")! }
    public var 表面仕上1: String { record.string(forKey: "表面仕上1")! }
    public var 表面仕上2: String { record.string(forKey: "表面仕上2")! }
    public var 側面仕上1: String { record.string(forKey: "側面仕上1")! }
    public var 側面仕上2: String { record.string(forKey: "側面仕上2")! }
    public lazy var 側面の高さ1: String = { self.record.string(forKey: "側面の高さ1")! }()
    public lazy var 側面の高さ2: String = { self.record.string(forKey: "側面の高さ2")! }()
    public lazy var 箱文字側面高さ: [Double] = { calc箱文字側面高さ(self.側面の高さ1) + calc箱文字側面高さ(self.側面の高さ2) }()
    public lazy var 箱文字以外側面高さ: [Double] = { calc箱文字以外側面高さ(self.側面の高さ1) + calc箱文字以外側面高さ(self.側面の高さ2) }()

    public var 板厚1: String { record.string(forKey: "板厚1")! }
    public var 板厚2: String { record.string(forKey: "板厚2")! }

    public var 上段左: String { record.string(forKey: "上段左")! }
    public var 上段中央: String { record.string(forKey: "上段中央")! }
    public var 上段右: String { record.string(forKey: "上段右")! }
    public var 下段左: String { record.string(forKey: "下段左")! }
    public var 下段中央: String { record.string(forKey: "下段中央")! }
    public var 下段右: String { record.string(forKey: "下段右")! }

    public var 部門: 部門型 { record.部門(forKey: "部門コード")! }
    public var 会社コード: String { record.string(forKey: "会社コード") ?? "" }
    
    public var 単価1: Double { record.double(forKey: "単価1") ?? 0 }
    public var 数量1: Int { record.integer(forKey: "数量1") ?? 0 }
    public var 単価4: Double { record.double(forKey: "単価4") ?? 0 }
    public var 単価5: Double { record.double(forKey: "単価5") ?? 0 }
    public lazy var 伝票種別: 伝票種別型 = { 伝票種別型(self.record.string(forKey: "伝票種別")!)! }()
    public var 経理状態: 経理状態型 {
        if let state = record.経理状態(forKey: "経理状態") { return state }
        return self.進捗一覧.contains(工程: .経理, 作業内容: .完了) ? .売上処理済 : .未登録
    }
    public var ボルト等1: String { record.string(forKey: "ボルト等1")! }
    public var ボルト等2: String { record.string(forKey: "ボルト等2")! }
    public var ボルト等3: String { record.string(forKey: "ボルト等3")! }
    public var ボルト等4: String { record.string(forKey: "ボルト等4")! }
    public var ボルト等5: String { record.string(forKey: "ボルト等5")! }
    public var ボルト等6: String { record.string(forKey: "ボルト等6")! }
    public var ボルト等7: String { record.string(forKey: "ボルト等7")! }
    public var ボルト等8: String { record.string(forKey: "ボルト等8")! }
    public var ボルト等9: String { record.string(forKey: "ボルト等9")! }
    public var ボルト等10: String { record.string(forKey: "ボルト等10")! }
    public var ボルト等11: String { record.string(forKey: "ボルト等11")! }
    public var ボルト等12: String { record.string(forKey: "ボルト等12")! }
    public var ボルト等13: String { record.string(forKey: "ボルト等13")! }
    public var ボルト等14: String { record.string(forKey: "ボルト等14")! }
    public var ボルト等15: String { record.string(forKey: "ボルト等15")! }

    public var ボルト本数1: String { record.string(forKey: "ボルト本数1")! }
    public var ボルト本数2: String { record.string(forKey: "ボルト本数2")! }
    public var ボルト本数3: String { record.string(forKey: "ボルト本数3")! }
    public var ボルト本数4: String { record.string(forKey: "ボルト本数4")! }
    public var ボルト本数5: String { record.string(forKey: "ボルト本数5")! }
    public var ボルト本数6: String { record.string(forKey: "ボルト本数6")! }
    public var ボルト本数7: String { record.string(forKey: "ボルト本数7")! }
    public var ボルト本数8: String { record.string(forKey: "ボルト本数8")! }
    public var ボルト本数9: String { record.string(forKey: "ボルト本数9")! }
    public var ボルト本数10: String { record.string(forKey: "ボルト本数10")! }
    public var ボルト本数11: String { record.string(forKey: "ボルト本数11")! }
    public var ボルト本数12: String { record.string(forKey: "ボルト本数12")! }
    public var ボルト本数13: String { record.string(forKey: "ボルト本数13")! }
    public var ボルト本数14: String { record.string(forKey: "ボルト本数14")! }
    public var ボルト本数15: String { record.string(forKey: "ボルト本数15")! }

    public var 付属品1: String { record.string(forKey: "付属品1")! }
    public var 付属品2: String { record.string(forKey: "付属品2")! }
    public var 付属品3: String { record.string(forKey: "付属品3")! }
    public var 付属品4: String { record.string(forKey: "付属品4")! }
    public var 付属品5: String { record.string(forKey: "付属品5")! }
    
    public var その他1: String { record.string(forKey: "その他1")! }
    public var その他2: String { record.string(forKey: "その他2")! }

    public var 枠材質: String { record.string(forKey: "枠材質")! }
    public var 台板材質: String { record.string(forKey: "台板材質")! }
    public var 裏仕様: String { record.string(forKey: "裏仕様")! }

    public var 合計金額: Double { record.double(forKey: "合計金額") ?? 0}
    public lazy var インシデント一覧: [インシデント型] = {
        let list = self.進捗一覧.map { インシデント型($0) } + self.変更一覧.map { インシデント型($0) }
        return list.sorted { $0.日時 < $1.日時 }
    }()
    
    var 図URL: URL? { record.url(forKey: "図") }
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
    public var 進捗一覧: [進捗型] { return (try? 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号).進捗一覧) ?? [] }
    public var 工程別進捗一覧: [工程型: [進捗型]] { return (try? 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号).工程別進捗一覧) ?? [:] }
    public var 作業進捗一覧: [進捗型] { return (try? 指示書進捗キャッシュ型.shared.キャッシュ一覧(self.伝票番号).作業進捗一覧) ?? [] }
    public lazy var uuid: String = { self.record.string(forKey: "UUID")! }()
    
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
        return self.外注一覧.contains { 外注先会社コード.contains($0.会社コード) }
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
    
    public var 金額: Double {
        var value = self.合計金額
        if value <= 0 {
            value = self.単価1
            let count = self.単価1
            if count > 0 { value += count }
        }
        return value
    }
    
    public var 担当者1: 社員型? {
        guard let num = record.integer(forKey: "社員番号1"), let name = record.string(forKey: "担当者1"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    public var 担当者2: 社員型? {
        guard let num = record.integer(forKey: "社員番号2"), let name = record.string(forKey: "担当者2"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    public var 担当者3: 社員型? {
        guard let num = record.integer(forKey: "社員番号3"), let name = record.string(forKey: "担当者3"), num > 0 && num < 1000 && !name.isEmpty else { return nil }
        return 社員型(社員番号: num, 社員名称: name)
    }
    
    public lazy var 保留校正一覧: [作業型] = {
        return (self.保留一覧 + self.校正一覧).sorted { $0.開始日時 < $1.開始日時 }
    }()
    
    public lazy var 保留一覧: [作業型] = {
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
        return list
    }()
    
    public lazy var 校正一覧: [作業型] = {
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
        return list
    }()
    
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
        let set = self.セット数値
        for index in 1...15 {
            var name = self.ボルト等(index) ?? ""
            let count = self.ボルト本数(index) ?? ""
            if let info = 資材要求情報型(ボルト欄: name, 数量欄: count, セット数: set, 伝票種類: self.伝票種類) {
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
                if let info = 資材要求情報型(ボルト欄: name, 数量欄: count, セット数: set, 伝票種類: self.伝票種類) {
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

    public lazy var 出荷時間: Time? = {
        guard let string = record.string(forKey: "連絡欄1") else { return nil }
        return Time(fmTime: string.toJapaneseNormal)
    }()
}

extension 指示書型 {
    public var 発送事項: String { record.string(forKey: "発送事項") ?? "" }
    
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
    static let dbName = "DataAPI_1"
    internal static func find(_ query: FileMakerQuery) throws -> [指示書型] {
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 指示書型.dbName, query: [query])
        let orders = list.compactMap { 指示書型($0) }
        return orders
    }

    static func find(伝票番号: 伝票番号型? = nil, 伝票種類: 伝票種類型? = nil, 製作納期: Day? = nil, limit: Int = 100) throws -> [指示書型] {
        var query = FileMakerQuery()
        if let num = 伝票番号 {
            query["伝票番号"] = "==\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        query["製作納期"] = 製作納期?.fmString
        return try find(query)
    }
    
    static func find2(伝票番号: 伝票番号型? = nil, 伝票種類: 伝票種類型? = nil, 製作納期: Day? = nil, limit: Int = 100) throws -> [指示書型] {
        var query = FileMakerQuery()
        if let num = 伝票番号 {
            query["伝票番号"] = "==\(num)"
        }
        query["伝票種類"] = 伝票種類?.fmString
        query["製作納期"] = 製作納期?.fmString
        return try find(query)
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
        let list = try find(query)
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
    
    static func find(作業範囲 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["受注日"] = "<=\(range.upperBound.fmString)"
        query["出荷納期"] = ">=\(range.lowerBound.fmString)"
        query["伝票種類"] = type?.fmString
        return try find(query)
    }

    static func find(有効日: Day, 伝票種類: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["受注日"] = "<=\(有効日.fmString)"
        query["出荷納期"] = ">=\(有効日.fmString)"
        if let type = 伝票種類 {
            query["伝票種類"] = "==\(type.fmString)"
        }
        return try find(query)
    }

    static func find(最小製作納期 day: Day, 伝票種類 type: 伝票種類型?) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["製作納期"] = ">=\(day.fmString)"
        query["伝票種類"] = type?.fmString
        
        return try find(query)
    }
    
    static func find(最小製作納期 day: Day, short: 略号型) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["製作納期"] = ">=\(day.fmString)"
        query["略号"] = "=*\(short.code)*"
        
        return try find(query)
    }
    
    static func find(出荷納期: Day, 発送事項: String) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["出荷納期"] = 出荷納期.fmString
        query["発送事項"] = 発送事項
        return try find(query)
    }

    static func find(出荷納期: ClosedRange<Day>, 発送事項: String) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["出荷納期"] = makeQueryDayString(出荷納期)
        query["発送事項"] = 発送事項
        return try find(query)
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
        return try find(query).filter { $0.isActive }
    }

    static func findActive(伝票種類: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        let today = Date()
        query["出荷納期"] = ">=\(today.day.fmString)"
        query["伝票種類"] = 伝票種類?.fmString
        return try find(query).filter { $0.isActive }
    }
    
    static func old_find2(作業範囲 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        query["受注日"] = "<=\(range.upperBound.fmString)"
        query["出荷納期"] = ">=\(range.lowerBound.fmString)"
        query["伝票種類"] = type?.fmString
        return try find(query)
    }
    
    static func find(登録日 range: ClosedRange<Day>, 伝票種類 type: 伝票種類型? = nil) throws -> [指示書型] {
        var query = FileMakerQuery()
        query ["登録日"] = makeQueryDayString(range)
        query["伝票種類"] = type?.fmString
        return try find(query)
    }

    static func findDirect(伝票番号文字列: String?) throws -> 指示書型? {
        guard let str = 伝票番号文字列, let number = try 伝票番号型(invalidString: str) else { return nil }
        return try findDirect(伝票番号: number)
    }
    
    static func findDirect(伝票番号: 伝票番号型) throws -> 指示書型? {
        var query = FileMakerQuery()
        query["伝票番号"] = "==\(伝票番号)"
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 指示書型.dbName, query: [query])
        if list.count == 1, let record = list.first, let order = 指示書型(record) {
            return order
        } else {
            return nil
        }
    }
    
    static func findDirect(uuid: String) throws -> 指示書型? {
        var query = FileMakerQuery()
        query["UUID"] = uuid
        let db = FileMakerDB.pm_osakaname
        let list: [FileMakerRecord] = try db.find(layout: 指示書型.dbName, query: [query])
        if list.count == 1, let record = list.first, let order = 指示書型(record) {
            return order
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
