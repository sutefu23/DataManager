//
//  作業ステージ.swift
//  DataManager
//
//  Created by manager on 2020/07/14.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 作業ステージ種類型: Hashable {
    case 手配
    case データ
    case 材料
    case 製作
    case 仕上
    case 出荷
}

public final class 作業ステージ型 {
    public var 種類: 作業ステージ種類型
    public var 関連工程: Set<工程型> = []
    
    public var 開始日時: Date?
    public var 完了日時: Date?
    public var 作業時間: TimeInterval?
    public var 関連進捗コード: [進捗型] = []
    
    public init(種類: 作業ステージ種類型) {
        self.種類 = 種類
    }
}

enum 作業ステージエラー: String, LocalizedError {
    case 箱文字以外を分析しようとした
    case 再製・クレーム指示書は対象外
    
    var errorDescription: String? { self.rawValue }
}

final class 作業計画型 {
    var 手配作業ステージ: 作業ステージ型? = nil
    var データ作業ステージ: 作業ステージ型? = nil
    var 材料作業ステージ: 作業ステージ型? = nil
    var 製作作業ステージ: 作業ステージ型? = nil
    var 仕上作業ステージ: 作業ステージ型? = nil
    var 出荷作業ステージ: 作業ステージ型? = nil
    
    init?(事前計画 order: 指示書型) {
        var stage: 作業ステージ型
        
        guard order.contains(工程: .管理, 作業内容: .完了) else { return nil }
        
        if order.伝票種類 != .箱文字 { return nil }
        if order.伝票種別 != .通常 { return nil }
        
        // 手配
        stage = 作業ステージ型(種類: .手配)
        stage.関連工程 = [.営業, .管理]
        self.手配作業ステージ = stage
        
        // データ
        stage = 作業ステージ型(種類: .データ)
        stage.関連工程 = [.原稿, .入力]
        self.データ作業ステージ = stage

        stage = 作業ステージ型(種類: .材料)
        stage.関連工程 = [.レーザー, .照合検査]
        if order.略号.contains(.腐食) {
            stage.関連工程.insert(.腐蝕)
        }
        self.材料作業ステージ = stage
        
        // 製作
        stage = 作業ステージ型(種類: .製作)
        let 文字数 = order.指示書文字数
        if 文字数.半田文字数 > 0 {
            stage.関連工程.formUnion([.立ち上がり, .半田, .裏加工])
        }
        if 文字数.溶接文字数 > 0 {
            stage.関連工程.formUnion([.立ち上がり_溶接, .溶接, .裏加工_溶接])
        }
        self.製作作業ステージ = stage

        // 仕上
        stage = 作業ステージ型(種類: .仕上)
        stage.関連工程 = [.研磨, .表面仕上]
        if order.社内塗装あり { stage.関連工程.insert(.塗装) }
        self.仕上作業ステージ = stage

        // 出荷
        stage = 作業ステージ型(種類: .出荷)
        stage.関連工程 = [.品質管理, .発送]
        self.出荷作業ステージ = stage
    }
    
    init?(事後計画 order: 指示書型) {
        return nil
    }
}
