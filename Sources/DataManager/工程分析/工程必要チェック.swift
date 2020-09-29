//
//  工程必要チェック.swift
//  DataManager
//
//  Created by manager on 2020/04/03.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

// 発送完了時点での分析用
// MARK:- 照合関係
extension 指示書型 {
    public var is照合必要: Bool {
        if 社名.contains("美濃クラフト") && 品名.contains("AR-32") { return false } // 直接表面仕上げに持っていく
        if 品名.containsOne(of: "アクリル切板", "アクリルのみ") { return false }
        if 品名.hasPrefix("アクリル(") { return false }
        if (材質1 == "アクリル" || 材質1.isEmpty) && (材質2 == "アクリル" || 材質2.isEmpty) { return false }
        if 工程別進捗一覧[.オブジェ] != nil { return false } // 直接オブジェに持っていく
        if 表面仕上1.contains("タタキ") && 備考.contains("オブジェ") { return false }
        if 社名.contains("月虎金属") && 板厚1.contains("0.5t") { return false }
        if (伝票種別 == .再製 || 伝票種別 == .クレーム) && 工程別進捗一覧[.レーザー（アクリル）] != nil && 工程別進捗一覧[.レーザー]?.contains(工程: .レーザー, 作業内容: .開始) != nil { return false } // アクリの再製は原稿がない場合、直接品質管理に持っていく
        return 工程別進捗一覧[.レーザー] != nil
    }
}

// MARK: - フィルム関係
public let フィルム入力開始日 = Day(2020, 03, 18)
public let フィルム不要伝票番号セット = Set<伝票番号型>( フィルム不要伝票番号数一覧.map { 伝票番号型(validNumber: $0) })

extension 指示書型 {
    public var isフィルム必要: Bool {
        if 工程別進捗一覧[.原稿] != nil { return false }
        guard 受注日 >= フィルム入力開始日 && (略号.contains(.腐食) || 略号.contains(.印刷)) && (伝票種類 == .切文字 || 伝票種類 == .箱文字 || 伝票種類 == .加工) && !フィルム不要伝票番号セット.contains(伝票番号) else { return false }
        if 社名.contains("美濃クラフト") && (品名.contains("クペラ") && (表面仕上2.contains("ﾋﾞﾝﾃｰｼﾞｳｯﾄﾞ")) || (品名.contains("XP-4") && 表面仕上2.contains("ｾﾞﾌﾞﾗｳｯﾄﾞ"))) {
            return false
        }
        return true
    }
}

// MARK: - フィルム不要伝票番号数一覧
private let フィルム不要伝票番号数一覧: [Int] = [
    2003_17665,
]
