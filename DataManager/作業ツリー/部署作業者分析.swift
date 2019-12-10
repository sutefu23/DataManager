//
//  部署作業者分析.swift
//  DataManager
//
//  Created by manager on 2019/09/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct GroupSet : Hashable {
    var group1 : 工程図グループ型
    var group2 : 工程図グループ型
    var group3 : 工程図グループ型
    
    init(_ group1:工程図グループ型, _ group2:工程図グループ型, _ group3:工程図グループ型) {
        self.group1 = group1
        self.group2 = group2
        self.group3 = group3
    }
    
    public static func ==(left:GroupSet, right:GroupSet) -> Bool {
        return left.group1 == right.group1 && left.group2 == right.group2 && left.group3 == right.group3
    }
}

public struct 工程社員型 : Hashable, Comparable {
    public let 工程 : 工程型
    public let 社員 : 社員型
    
    public static func <(left:工程社員型, right:工程社員型) -> Bool {
        if left.工程 != right.工程 { return left.工程 < right.工程 }
        return left.社員.社員番号 < right.社員.社員番号
    }
}

class LineCounter {
    var map : [GroupSet : Int] = [:]
    func count(_ group1:工程図グループ型, _ group2:工程図グループ型, _ group3:工程図グループ型) -> Int {
        let key = GroupSet(group1, group2, group3)
        if var result = map[key] {
            result += 1
            map[key] = result
            return result
        }
        map[key] = 0
        return 0
    }
}

public class 部署作業者分析型 {
    public var lines : [(GroupSet, 工程図工程型)]
    public var connections : [コンストレイン情報型] = []
    var range : ClosedRange<Date>
    var type : 伝票種類型?
    
    public init(進捗期間 range:ClosedRange<Date>, 伝票種類 type:伝票種類型?) {
        self.lines = []
        self.type = type
        self.range = range
        self.prepareLines()
    }
    
    func setupLines() {
        var groups = Dictionary(grouping: lines) { $0.0 }
        for line in lines {
            func firstDate(_ val:[(GroupSet, 工程図工程型)]) -> Date {
                var minDate : Date = val.first!.1.開始日時
                for v in val {
                    let date = v.1.開始日時
                    if date < minDate { minDate = date }
                }
                return minDate
            }
            guard let list = groups[line.0] else { continue }
            let numset = Dictionary(grouping: list) { $0.1.備考1! }.sorted {
                let date1 = firstDate($0.value)
                let date2 = firstDate($1.value)
                if date1 != date2 { return date1 < date2 }
                return $0.key < $1.key
            }
            for (index, line) in numset.enumerated() {
                line.value.forEach { $0.1.行番号 = "\(index+1)" }
            }
        }
    }
    
    func prepareLines() {
        var lines : [(工程社員型, 作業型)] = []
        let fromDay = range.lowerBound.前出勤日()
        let toDay = range.lowerBound.翌出勤日()
        guard let orders = (try? 指示書型.find(作業範囲: (fromDay.day)...(toDay.day))) else { return }
        var text = ""
        for order in orders {
            var currentLines : [(工程社員型, 作業型)] = []
            // 範囲内の有効な作業の追加
            func append(_ work:作業型) {
                if range.upperBound < work.開始日時 || work.完了日時 < range.lowerBound { return }
                currentLines.append((work.工程社員, work))
            }

            let orderType = order.伝票種類
            if let type = type {
                if type != orderType { continue }
            }
            if let line = make営業工程(order) {
                append(line)
            } else {
                continue
            }
            if orderType == .外注 || orderType == .校正 { continue }
            if let line = make管理工程(order) { append(line) }
            if let line = make原稿工程(order) { append(line) }
            if let line = make入力工程(order) { append(line) }
            if let line = makeレーザー工程(order) { append(line) }
            lines.append(contentsOf: currentLines)
        }
        lines.sort { (line1, line2) -> Bool in
            if line1.0 != line2.0 { return line1.0 < line2.0 }
            return line1.1.開始日時 < line2.1.開始日時
        }
        let url = URL(fileURLWithPath: "/Users/manager/Downloads/test.csv")
        try! text.write(to: url, atomically: true, encoding: .utf8)
        var order = 1.0
        var map = [工程型 : 工程図グループ型]()
        var map2 = [社員型 : 工程図グループ型]()
        var map3 = [Day : 工程図グループ型]()
        for line in lines {
            let group1, group2, group3 : 工程図グループ型
            if let g = map[line.1.工程] {
                group1 = g
            } else {
                let g = 工程図グループ型(name: line.1.工程.description, order: order)
                map[line.1.工程] = g
                group1 = g
                order += 1
            }
            if let g = map2[line.0.社員] {
                group2 = g
            } else {
                let g = 工程図グループ型(name: line.0.社員.社員名称, order: order)
                map2[line.0.社員] = g
                group2 = g
                order += 1
            }
            let key3 = line.1.開始日時.day
            if let g = map3[key3] {
                group3 = g
            } else {
                let g = 工程図グループ型(name: key3.monthDayString, order: order)
                map3[key3] = g
                group3 = g
                order += 1
            }
            let result = 工程図工程型(name: "\(line.1.伝票番号)", from: line.1.開始日時, to: line.1.完了日時)
            result.備考1 = "\(line.1.伝票番号)"
            self.lines.append((GroupSet(group1, group2, group3), result))
        }
        // 校正・保留の追加
//        let lineCounter = LineCounter()
        var newLines = [(GroupSet, 工程図工程型)]()
        var newLines2 = [(GroupSet, 工程図工程型)]()
        for order in orders {
            workloop: for work in order.校正一覧 + order.保留一覧 {
                if range.upperBound < work.開始日時 || work.完了日時 < range.lowerBound { break }
                let orderString = "\(order.伝票番号)"
                for (groupSet, result) in self.lines + newLines where result.備考1 == orderString {
                    let range = result.開始日時...result.終了日時
                    if range.contains(work.開始日時) && range.contains(work.完了日時) {
                        let head = result
                        let tail = head.clone()
                        head.終了日時 = work.開始日時
                        tail.開始日時 = work.完了日時
                        let name = (order.担当者2 ?? order.担当者1 ?? order.担当者3)?.社員名称 ?? ""
                        let middle = 工程図工程型(name: work.作業種類.string + (name.isEmpty ? "" : ":" + name) , from: work.開始日時.addingTimeInterval(60), to: work.完了日時.addingTimeInterval(-60))
                        middle.進捗度 = 100
                        middle.備考1 = orderString
                        let connect1 = コンストレイン情報型(先行工程ID: head.工程ID, 後続工程ID: middle.工程ID)
                        let connect2 = コンストレイン情報型(先行工程ID: middle.工程ID, 後続工程ID: tail.工程ID)
                        newLines2.append((groupSet, middle))
                        newLines.append((groupSet, tail))
                        self.connections.append(contentsOf: [connect1, connect2])
                        break
                    }
                    
                }
            }
        }
        self.lines.append(contentsOf: newLines2)
        self.lines.append(contentsOf: newLines)
        
        setupLines()
    }
    
    public func make作業別工程情報() -> [作業別工程情報型] {
        var list = [作業別工程情報型]()
        for (groupSet, state) in lines {
            let group = groupSet.group1
            let group2 = groupSet.group2
            let group3 = groupSet.group3
            var result = 作業別工程情報型(第1階層グループ名称: group.名称)
            result.第1階層グループID = group.グループID
            result.第2階層グループ名称 = group2.名称
            result.第2階層グループID = group2.グループID
            result.第3階層グループ名称 = group3.名称
            result.第3階層グループID = group3.グループID
            result.工程ID = state.工程ID
            result.工程名称 = state.名称
            result.工程開始日 = state.開始日時
            result.工程終了日 = state.終了日時
            result.進捗度 = state.進捗度
            result.備考1 = state.備考1
            result.行番号 = state.行番号
            list.append(result)
        }
        return list
    }
    
    func make営業工程(_ order:指示書型) -> 作業型? {
        guard let progress = order.進捗一覧.findFirst(工程: .管理, 作業内容: .受取) else { return nil }
        guard let person = order.担当者2 ?? order.担当者1 ?? order.担当者3 else { return nil }
        return 作業型(progress, state: .営業, from: order.登録日時, worker: person)
    }
    
    func make管理工程(_ order:指示書型) -> 作業型? {
        guard let from = order.進捗一覧.findFirst(工程: .管理, 作業内容: .受取) else { return nil }
        guard let to = order.進捗一覧.findFirst(工程: .管理, 作業内容: .完了) else { return nil }
        return 作業型(to, from: from.登録日時)
    }
    
    func make原稿工程(_ order:指示書型) -> 作業型? {
        guard let from = order.進捗一覧.findFirst(工程: .原稿, 作業内容: .開始) else { return nil }
        guard let to = order.進捗一覧.findFirst(工程: .原稿, 作業内容: .完了) else { return nil }
        return 作業型(to, from: from.登録日時)
    }
    
    func make入力工程(_ order:指示書型) -> 作業型? {
        guard let from = order.進捗一覧.findFirst(工程: .入力, 作業内容: .開始) else { return nil }
        guard let to = order.進捗一覧.findFirst(工程: .入力, 作業内容: .完了) else { return nil }
        return 作業型(to, from: from.登録日時)
    }
    
    func makeレーザー工程(_ order:指示書型) -> 作業型? {
        guard let from = order.進捗一覧.findFirst(工程: .レーザー, 作業内容: .開始) else { return nil }
        guard let to = order.進捗一覧.findFirst(工程: .レーザー, 作業内容: .完了) else { return nil }
        return 作業型(to, from: from.登録日時, worker: from.作業者)
    }
    
    func make照合工程(_ order:指示書型) -> 作業型? {
        guard let from = order.進捗一覧.findFirst(工程: .レーザー, 作業内容: .完了) else { return nil }
        guard let to = order.進捗一覧.findFirst(工程: .照合検査, 作業内容: .完了) else { return nil }
        return 作業型(to, from: from.登録日時)
    }
    
}
