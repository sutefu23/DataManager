//
//  ProgressTVData.swift
//  DataManager
//
//  Created by manager on 2020/04/01.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#else
import Foundation
#endif

#if !os(Linux)
/// 表示モード
public enum ProgressTVMode: Int {
    case 箱文字 = 1
    case 箱文字アクリル = 2
    case 切文字 = 3
    
    public var targetName: String {
        switch self {
        case .箱文字: return "箱文字"
        case .箱文字アクリル: return "箱文字アクリル"
        case .切文字: return "切文字"
        }
    }

    public var simpleTargetName: String {
        switch self {
        case .箱文字: return "箱文字"
        case .箱文字アクリル: return "アクリ"
        case .切文字: return "切文字"
        }
    }

    public var nextMode: ProgressTVMode {
        switch self {
        case .箱文字:
            return .箱文字アクリル
        case .箱文字アクリル:
            return .切文字
        case .切文字:
            return .箱文字
        }
    }
}

private let 注目工程: Set<工程型> = [.立ち上がり, .立ち上がり_溶接]
private let スルー工程一覧: Set<工程型> = [.レーザー（アクリル）, .フォーミング, .シャーリング, .タップ, .タレパン, .プレーナー, .ルーター, .付属品準備]
private let ペア工程: [工程型: 工程型] = [
    .立ち上がり: .立ち上がり_溶接,
    .立ち上がり_溶接: .立ち上がり
]

public final class ProgressTVData {
    private let lock = NSRecursiveLock()

    public let 指示書: 指示書型
    public var 伝票種別: 伝票種別型 { return self.指示書.伝票種別 }
    
    public let 状態表示: String
    public var 納期: Day { return self.指示書.製作納期 }
    public var 伝票状態: 伝票状態型 { return self.指示書.伝票状態 }
    public var 品名: String { return self.指示書.品名 }
    public var 伝票番号: 伝票番号型 { return self.指示書.伝票番号 }
    public var 略号: Set<略号型> { return self.指示書.略号 }
    public var 伝言欄: String { return self.指示書.管理用メモ }
    public var 進捗一覧: [進捗型] { return self.指示書.進捗一覧 }
    
    public init(_ 指示書: 指示書型) {
        self.指示書 = 指示書
        self.状態表示 = 指示書.箱文字前工程状態表示
    }
    

    public func 必要チェック(for target: 工程型) -> Bool {
        return self.指示書.箱文字前工程必要チェック(for: target)
    }
    
    public func 箱文字前工程優先度(of target: 工程型) -> 箱文字前工程優先度型 {
        return self.指示書.箱文字前工程優先度(of: target)
    }
    
    // MARK: - 仮表示
    public func is仮表示(for target: [工程型]) -> Bool {
        return !target.allSatisfy { 箱文字優先度キャッシュ型.shared.contains(self.指示書.伝票番号, $0) }
    }
    
    public var whiteCache: (target: [工程型], result: Bool?)?
    public func 白表示(for target: [工程型]) -> Bool? {
        lock.lock()
        if whiteCache?.target == target {
            lock.unlock()
            return whiteCache?.result
        }
        lock.unlock()
        return self.指示書.白表示(for: target, cacheOnly: true)
    }
    public func update白表示(for target: [工程型]) -> Bool {
        lock.lock()
        if whiteCache != nil {
            lock.unlock()
            return false
        }
        lock.unlock()
        let data = (target, self.指示書.白表示(for: target))
        lock.lock()
        self.whiteCache = data
        lock.unlock()
        return true
    }
    
    public var priorityCache: (target: [工程型], result: Bool?)?
    public func 優先状態(for target: [工程型]) -> Bool? {
        lock.lock()
        if priorityCache?.target == target {
            lock.unlock()
            return priorityCache?.result
        }
        lock.unlock()
        return self.指示書.優先状態(for: target, cacheOnly: true)
    }
    public func update優先状態(for target: [工程型]) -> Bool {
        lock.lock()
        if priorityCache != nil {
            lock.unlock()
            return false
        }
        lock.unlock()
        let data = (target, self.指示書.優先状態(for: target))
        lock.lock()
        self.priorityCache = data
        lock.unlock()
        return true
    }
    
    public func backgroundColor(of target: 工程型) -> DMColor? {
        let flg2 = self.白表示(for: [target])
        if flg2 == true {
            return nil
        } else if flg2 == false {
            return .systemGray
        } else {
            return .lightGray
        }
    }
    
    public func updateOneStep(_ target: 工程型) -> Bool {
        assert(!Thread.isMainThread)
        let flg1 = self.update白表示(for: [target])
        let flg2 = self.update優先状態(for: [target])
        return flg1 || flg2
    }
}

// MARK: - Delegate
public protocol ProgressTVCoreOwner: class {
    func showInfo1(_ text: String)
    func showInfo2(_ text: String)
    func showInfo3(_ text: String)
    func showMode(_ text: String)

    func reloadTableViewData()
}

// MARK: - コア
public final class ProgressTVCore {
    weak var owner: ProgressTVCoreOwner!
    public var mode: ProgressTVMode {
        didSet { self.updateNow() }
    }
    public var アクリル有りのみ表示: Bool {
        switch mode {
        case .箱文字, .切文字: return false
        case .箱文字アクリル: return true
        }
    }
    var sourceOrders: [指示書型]?
    var currentTarget: 工程型?
    let queue = DispatchQueue(label: "serial queue")
    var sourceDatas: [ProgressTVData] = []
    var datas: [ProgressTVData] = []
    public private(set) var target: 工程型
    let 工程切り替え待機時間: TimeInterval = 5.0
    let 画面更新間隔: TimeInterval = 10 * 60
    let 項目更新間隔: TimeInterval = 0.25
    var workItem: DispatchWorkItem?
    var lastAllUpdate: Date? = nil
    public var count: Int { return datas.count }

    public init(owner: ProgressTVCoreOwner, target: 工程型 = .立ち上がり, mode: ProgressTVMode, orders: [指示書型]? = nil) {
        owner.showInfo3("Ver " + (Version()?.fullText ?? ""))
        self.mode = mode
        self.owner = owner
        self.target = target
        self.sourceOrders = orders
        prepareFirstLabel()
        startOrderUpdate()
    }
    
    func prepareFirstLabel() {
        if currentTarget != target {
            owner.showInfo1("\(self.target.description) 初回検索中・・・・・")
            owner.showInfo2("")
            owner.showMode(mode.simpleTargetName)
            datas = []
            owner.reloadTableViewData()
        }
    }
    
    public func changeTarget() {
        let list: [工程型] = [.立ち上がり, .照合検査, .レーザー, .出力, .入力, .原稿, .管理, .営業]
        guard let currentIndex = list.firstIndex(of: self.target) else { return }
        var nextIndex = list.index(after: currentIndex)
        if !list.indices.contains(nextIndex) { nextIndex = list.startIndex }
        self.target = list[nextIndex]
        self.updateNow()
    }
    
    public func changeFilter(mode: ProgressTVMode) {
        self.mode = mode
        self.currentTarget = nil
        self.updateNow()
    }
    
    private func updateNow() {
        self.stopUpdateTimer()
        self.prepareFirstLabel()
        self.startOrderUpdate()
    }
    
    // MARK: - updateList
    let orderQueue = DispatchQueue(label: "update order list queue")
    var orderItem: DispatchWorkItem? = nil
    
    func makeList(_ item: DispatchWorkItem?) throws -> [ProgressTVData]? {
        let today = Day()
        let orders: [指示書型]
        if let source = self.sourceOrders {
            orders = source
        } else {
            switch mode {
            case .箱文字, .箱文字アクリル:
                orders = try 指示書型.find(最小製作納期: today, 伝票種類: .箱文字)
            case .切文字:
                orders = try 指示書型.find(最小製作納期: today, 伝票種類: .切文字)
            }
        }
        if item?.isCancelled == true { return nil }
        orders.forEach { let _ = $0.工程別進捗一覧 }
        if item?.isCancelled == true { return nil }
        var list = orders.map { ProgressTVData($0) }
        if アクリル有りのみ表示 {
            list = list.filter(\.指示書.レーザーアクリルあり)
        }
        return list
    }

    func startOrderUpdate() {
        assert(Thread.isMainThread)
        orderItem?.cancel()
        orderItem = nil
        var item: DispatchWorkItem?
        item = DispatchWorkItem { [unowned item] in
            assert(!Thread.isMainThread)
            do {
                guard let datas = try self.makeList(item) else { return }
                DispatchQueue.main.async {
                    if item?.isCancelled == true { return }
                    self.sourceDatas = datas
                    self.currentIndex = datas.firstIndex { $0.is仮表示(for: [self.target])} ?? 0
                    self.prepareData()
                    self.orderItem = nil
                    self.startOrderTimer()
                    self.startUpdateTimer()
                }

            } catch {
            }
        }
        self.orderItem = item
        orderQueue.asyncAfter(deadline: .now()+self.工程切り替え待機時間, execute: item!)
    }

    var orderTimerWorkItem: DispatchWorkItem?  = nil
    func startOrderTimer() {
        assert(Thread.isMainThread)
        orderTimerWorkItem?.cancel()
        var item: DispatchWorkItem? = nil
        item = DispatchWorkItem { [unowned item] in
            assert(Thread.isMainThread)
            if item?.isCancelled == true { return }
            self.orderTimerWorkItem = nil
            self.startOrderUpdate()
        }
        self.orderTimerWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + self.画面更新間隔, execute: item!)
    }

    // MARK: - updateObject
    var currentIndex = 0

    var updateTimerWorkItem: DispatchWorkItem?  = nil
    func updateOneStep(_ data: ProgressTVData, _ target:工程型) -> Bool {
        assert(!Thread.isMainThread)
        let flg1 = data.update白表示(for: [target])
        let flg2 = data.update優先状態(for: [target])
        return flg1 || flg2
    }
    
    func stopUpdateTimer() {
        updateTimerWorkItem?.cancel()
        updateTimerWorkItem = nil
    }
    
    func startUpdateTimer() {
        assert(Thread.isMainThread)
        updateTimerWorkItem?.cancel()
        if datas.isEmpty {
            self.prepareData(allChange: true)
            return
        }
        var index = currentIndex + 1
        if !datas.indices.contains(index) { index = 0 }
        var steps = 10
        while !datas[index].is仮表示(for: [self.target]) {
            index = currentIndex + 1
            if !datas.indices.contains(index) { index = 0 }
            if index == currentIndex {
                self.prepareData(allChange: true)
                return
            }
            steps -= 1
            if steps < 0 { break }
        }
        currentIndex = index
        let target = self.target
        let data = datas[currentIndex]
        var item: DispatchWorkItem? = nil
        item = DispatchWorkItem { [unowned item] in
            assert(!Thread.isMainThread)
            if item?.isCancelled == true { return }
            let allChange = self.updateOneStep(data, target)
            DispatchQueue.main.async {
                if item?.isCancelled == true { return }
                self.prepareData(allChange: allChange)
            }
        }
        self.updateTimerWorkItem = item
        DispatchQueue.global().asyncAfter(deadline: .now() + self.項目更新間隔, execute: item!)
    }
    
    // MARK: -
    func reloadAll() throws {
        assert(Thread.isMainThread)
        self.startOrderUpdate()
    }

    public func prepareData(allChange: Bool = true) {
        assert(Thread.isMainThread)
        if owner == nil  {return }
        let today = Day()
        let now = Time()
        if allChange {
            self.datas = self.sourceDatas.filter{ $0.必要チェック(for: target) }.sorted{ 箱文字前工程比較($0.指示書, $1.指示書, 工程: target) }
        }
        let targets = [self.target]

        let count = datas.reduce(0) { $0 + ($1.白表示(for: targets) != false ? 1 : 0) }
        owner.showInfo1("\(today.monthDayWeekJString) \(self.target.description)待ち分 (\(now.hourMinuteString)時点)")

        let count2 = datas.reduce(0) { $0 + ($1.is仮表示(for: targets) ? 1 : 0) }
        var label2 = "残り\(count)件"
        if count2 > 0 {
            label2 += " (仮表示\(count2)件)"
        }
        owner.showInfo2(label2)
        owner.showMode(mode.simpleTargetName)
        self.currentTarget = self.target
        if allChange {
            owner.reloadTableViewData()
        }
        if count2 != 0 {
            startUpdateTimer()
        }
    }
    
    // TableView表示用
    public func tableViewRowBackgroundColor(row: Int) -> DMColor? {
        let data = datas[row]
        return data.backgroundColor(of: self.target)
    }
    
    public func tableViewData(row: Int, col: String, font: DMFont) -> NSAttributedString {
        let data = datas[row]
        var text: String = ""
        var color: DMColor? = nil
        switch col {
        case "Check":
            let flg1 = data.優先状態(for: [target])
            if flg1 == true {
                text = "優先"
            } else if flg1 == false {
            } else {
                text = "?"
            }
        case "LimitDay":
            let limitDay: Int
            switch data.指示書.伝票種類 {
            case .箱文字:
                limitDay = 3
            case .エッチング, .切文字, .加工, .外注, .校正:
                limitDay = 1
            }
            let day3 = Day().appendWorkDays(limitDay)
            color = (data.納期 <= day3) ? .red : .black
            text = data.納期.monthDayJString
        case "State":
            text = data.状態表示
        case "Progress":
            text = String(data.指示書.箱文字前工程_進捗表示(of: target))
        case "Progress2":
            text = data.指示書.箱文字前工程_最終工程(of: target)?.登録日時.dayWeekToMinuteString ?? ""
        case "Name":
            text = data.品名
        case "Number":
            text = data.伝票番号.表示用文字列
            switch data.伝票種別 {
            case .通常:
                color = .black
            case .クレーム:
                color = .red
            case .再製:
                color = .blue
            }
        case "Message":
            text = data.伝言欄
        case "Mark":
            let fontSize = font.pointSize
            let rs2: NSMutableAttributedString = data.指示書.色付き略号(fontSize: fontSize)
            let depthSet = Set<Double>(data.指示書.箱文字側面高さ)
            for depth in depthSet {
                if depth <= 20 {
                    rs2.append(" \(depth)".makeAttributedString(color: .black, size: fontSize, fontName: nil))
                }
            }
            return rs2
        default:
            break
        }
        if let color = color {
            return text.makeAttributedString(color: color, font: font)
        } else {
            return text.makeAttributedString(font: font)
        }
    }
    
    public func data(at row: Int) -> ProgressTVData {
        return datas[row]
    }
    
    
    #if os(iOS) || os(tvOS)
    public func updateLabel(view: DMView, row: Int, col: String) {
        guard let label = view.searchLabel(col) else { return }
        let font = label.font!
        let utf8 = tableViewData(row: row, col: col, font: font)
        label.attributedText = utf8
    }
    #endif
}
#endif

#if os(iOS) || os(tvOS)
extension ProgressTVCore{
    public func updateTableViewCell(cell: UITableViewCell, row: Int) {
        let view = cell.contentView
        self.updateLabel(view: view, row: row, col: "Check")
        self.updateLabel(view: view, row: row, col: "LimitDay")
        self.updateLabel(view: view, row: row, col: "State")
        self.updateLabel(view: view, row: row, col: "Progress")
        self.updateLabel(view: view, row: row, col: "Progress2")
        self.updateLabel(view: view, row: row, col: "Name")
        self.updateLabel(view: view, row: row, col: "Number")
        self.updateLabel(view: view, row: row, col: "Mark")
        self.updateLabel(view: view, row: row, col: "Message")
        view.backgroundColor = self.tableViewRowBackgroundColor(row: row)
    }
}
#endif

public extension 指示書型 {
    var レーザーアクリルあり: Bool {
        func isレーザーアクリ(_ material: String, _ other: String) -> Bool {
            if material.contains("拡散") || other.contains("社内ルーター") { return false }
            return material.contains("アクリル") || material.contains("ｱｸﾘﾙ")
        }
        return isレーザーアクリ(材質1, その他1) || isレーザーアクリ(材質2, その他2)
    }
}
