//
//  グループ階層.swift
//  DataManager
//
//  Created by manager on 8/21/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

private var serial = 0
private func makeID() -> String {
    serial += 1
    return serial.description
}

public class 工程図工程型 {
    public let 工程ID : String
    public var 名称 : String
    public var 開始日時 : Date
    public var 終了日時 : Date
    public var 進捗度 : Int?
    public var 行番号 : String?
    public var 備考1 : String?

    public init(name:String, from:Date, to:Date) {
        self.名称 = name
        self.開始日時 = from
        self.終了日時 = to
        self.工程ID = makeID()
    }
    
    public func clone() -> 工程図工程型 {
        let clone = 工程図工程型(name: self.名称, from: self.開始日時, to: self.終了日時)
        return clone
    }
}
public class 工程図グループ型 : Hashable {
    public let グループID : String
    public var 名称 : String
    public var order : Double
    
    public init(name:String, order:Double) {
        self.名称 = name
        self.グループID = makeID()
        self.order = order
    }
    
    public static func ==(left:工程図グループ型, right:工程図グループ型) -> Bool {
        return left.グループID == right.グループID && left.名称 == right.名称 && left.order == right.order
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.グループID)
        hasher.combine(self.名称)
        hasher.combine(self.order)
    }
}

extension Sequence where Element == 進捗型 {
    func make工程(name: String, _ picker: (Self) -> (from:Date?, to:Date?)) -> 工程図工程型? {
        let result = picker(self)
        guard let from = result.from, let to = result.to else { return nil }
        let state = 工程図工程型(name: name, from: from, to: to)
        return state
    }
}

public func make工程別進捗リスト(_ orders:[指示書型]) -> [(工程図グループ型, 工程図工程型)]  {
    let group1 = 工程図グループ型(name: "営業", order: 1)
    let group2 = 工程図グループ型(name: "管理", order: 1)
    let group3 = 工程図グループ型(name: "原稿", order: 1)

    var list : [(工程図グループ型, 工程図工程型)] = []
    for order in orders {
        let state1 = order.進捗一覧.make工程(name: order.表示用伝票番号) {
            let from = order.登録日時
            let to = $0.findFirst(工程: .管理, 作業内容: .受取)?.登録日時 ?? $0.findFirst(工程: .管理, 作業内容: .開始)?.登録日時
            return (from, to)
        }
        let state2 = order.進捗一覧.make工程(name: order.表示用伝票番号) {
            let from = $0.findFirst(工程: .管理, 作業内容: .受取)?.登録日時
            let to = $0.findFirst(工程: .管理, 作業内容: .完了)?.登録日時
            return (from, to)
        }
        let state3 = order.進捗一覧.make工程(name: order.表示用伝票番号) {
            let from = $0.findFirst(工程: .原稿, 作業内容: .開始)?.登録日時 ?? $0.findFirst(工程: .管理, 作業内容: .完了)?.登録日時
            let to = $0.findFirst(工程: .原稿, 作業内容: .完了)?.登録日時 ?? $0.findFirst(工程: .入力, 作業内容: .受取)?.登録日時
            return (from, to)
        }
        if let state1 = state1 { list.append((group1, state1)) }
        if let state2 = state2 { list.append((group2, state2)) }
        if let state3 = state3 { list.append((group3, state3)) }
    }
    return list
}

public extension Sequence where Element == (工程図グループ型, 工程図工程型) {
    func make作業別工程情報() -> [作業別工程情報型] {
        let source = self.sorted { $0.0.order < $1.0.order }
        var list = [作業別工程情報型]()
        for (group, state) in source {
            var result = 作業別工程情報型(第1階層グループ名称: group.名称)
            result.第1階層グループID = group.グループID
            result.工程ID = state.工程ID
            result.工程名称 = state.名称
            result.工程開始日 = state.開始日時
            result.工程終了日 = state.終了日時
            list.append(result)
        }
        return list
    }
}

