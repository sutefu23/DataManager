//
//  コンストレイン情報.swift
//  DataManager
//
//  Created by manager on 8/20/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct コンストレイン情報型: 工程図データ型 {
    public static let filename = "constraint.tsv"
    public static let header = "先行工程ID\t後続工程ID\tタイプ\t作業間隔\tカレンダID\t備考\t非表示\t描画順序１\t描画オフセット右１\t描画オフセット下１\t描画順序2\t描画オフセット右2\t描画オフセット下2\t描画順序3\t描画オフセット右3\t描画オフセット下3\t描画順序4\t描画オフセット右4\t描画オフセット下4\t描画順序5\t描画オフセット右5\t描画オフセット下5\t描画順序6\t描画オフセット右6\t描画オフセット下6\tEOR"

    
    public var 先行工程ID: String
    public var 後続工程ID: String
    public var タイプ: 工程図型.コンストレインタイプ型?
    public var 作業間隔: Int?
    public var カレンダID: Int?
    public var 備考: String?
    public var 非表示: 工程図型.オンオフ型?
    public var 描画順序1（作業別）: 工程図型.描画順序型?
    public var 描画オフセット右1: Int?
    public var 描画オフセット下1: Int?
    public var 描画順序2（区分1）: 工程図型.描画順序型?
    public var 描画オフセット右2: Int?
    public var 描画オフセット下2: Int?
    public var 描画順序3（区分2）: 工程図型.描画順序型?
    public var 描画オフセット右3: Int?
    public var 描画オフセット下3: Int?
    public var 描画順序4（区分3）: 工程図型.描画順序型?
    public var 描画オフセット右4: Int?
    public var 描画オフセット下4: Int?
    public var 描画順序5（区分4）: 工程図型.描画順序型?
    public var 描画オフセット右5: Int?
    public var 描画オフセット下5: Int?
    public var 描画順序6（資源別）: 工程図型.描画順序型?
    public var 描画オフセット右6: Int?
    public var 描画オフセット下6: Int?
    
    public init(先行工程ID: String, 後続工程ID: String) {
        self.先行工程ID = 先行工程ID
        self.後続工程ID = 後続工程ID
    }
    
    public func makeColumns() -> [String?] {
        return [
            self.先行工程ID,
            self.後続工程ID,
            self.タイプ?.code,
            self.作業間隔?.description,
            self.カレンダID?.description,
            self.備考,
            self.非表示?.code,
            self.描画順序1（作業別）?.code,
            self.描画オフセット右1?.description,
            self.描画オフセット下1?.description,
            self.描画順序2（区分1）?.code,
            self.描画オフセット右2?.description,
            self.描画オフセット下2?.description,
            self.描画順序3（区分2）?.code,
            self.描画オフセット右3?.description,
            self.描画オフセット下3?.description,
            self.描画順序4（区分3）?.code,
            self.描画オフセット右4?.description,
            self.描画オフセット下4?.description,
            self.描画順序5（区分4）?.code,
            self.描画オフセット右5?.description,
            self.描画オフセット下5?.description,
            self.描画順序6（資源別）?.code,
            self.描画オフセット右6?.description,
            self.描画オフセット下6?.description,
        ]
    }
}
