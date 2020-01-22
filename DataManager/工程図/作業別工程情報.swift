//
//  作業別工程情報.swift
//  DataManager
//
//  Created by manager on 8/20/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct 作業別工程情報型: 工程図データ型 {
    public static let filename = "koutei.tsv"
    public static let header = "第1階層グループID\t第１階層グループ名称\t第１階層グループ備考１\t第１階層グループ備考２\t第１階層グループ備考３\t第１階層グループ備考４\t第１階層グループ備考５\t第１階層グループ備考６\t第１階層グループ備考７\t第１階層グループ備考８\t第１階層グループ備考９\t第１階層グループ備考10\t第2階層グループID\t第2階層グループ名称\t第3階層グループID\t第3階層グループ名称\t第4階層グループID\t第4階層グループ名称\t第5階層グループID\t第5階層グループ名称\t第6階層グループID\t第6階層グループ名称\t第7階層グループID\t第7階層グループ名称\t第8階層グループID\t第8階層グループ名称\t第9階層グループID\t第9階層グループ名称\t第10階層グループID\t第１0階層グループ名称\t行番号\t工程ID\t工程名称\t初期工程開始日\t初期工程終了日\t工程開始日\t工程終了日\t工程期間\tカレンダID\t進捗度\t数量\t備考１\t備考２\t備考３\t備考４\t備考５\t備考６\t備考７\t備考８\t備考９\t備考10\tバーを移動しない\t後続に影響しない範囲で遅く開始する\t編集不可\t左シンボル形状\t中シンボル形状\t右シンボル形状\t左シンボル色\t中シンボル色\t右シンボル色\tテキストの表示位置\tＵＲＬ表示名１\tＵＲＬ１\tＵＲＬ表示名２\tＵＲＬ２\tＵＲＬ表示名３\tＵＲＬ３\tＵＲＬ表示名４\tＵＲＬ４\tＵＲＬ表示名５\tＵＲＬ５\tEOR"
    
    public var 第1階層グループID: String?
    public var 第1階層グループ名称: String
    public var 第1階層グループ備考1: String?
    public var 第1階層グループ備考2: String?
    public var 第1階層グループ備考3: String?
    public var 第1階層グループ備考4: String?
    public var 第1階層グループ備考5: String?
    public var 第1階層グループ備考6: String?
    public var 第1階層グループ備考7: String?
    public var 第1階層グループ備考8: String?
    public var 第1階層グループ備考9: String?
    public var 第1階層グループ備考10: String?
    public var 第2階層グループID: String?
    public var 第2階層グループ名称: String?
    public var 第3階層グループID: String?
    public var 第3階層グループ名称: String?
    public var 第4階層グループID: String?
    public var 第4階層グループ名称: String?
    public var 第5階層グループID: String?
    public var 第5階層グループ名称: String?
    public var 第6階層グループID: String?
    public var 第6階層グループ名称: String?
    public var 第7階層グループID: String?
    public var 第7階層グループ名称: String?
    public var 第8階層グループID: String?
    public var 第8階層グループ名称: String?
    public var 第9階層グループID: String?
    public var 第9階層グループ名称: String?
    public var 第10階層グループID: String?
    public var 第10階層グループ名称: String?
    public var 行番号: String?
    public var 工程ID: String?
    public var 工程名称: String?
    public var 初期工程開始日: Date?
    public var 初期工程終了日: Date?
    public var 工程開始日: Date?
    public var 工程終了日: Date?
    public var 工程期間: Int?
    public var カレンダID: Int?
    public var 進捗度: Int?
    public var 数量: Double?
    public var 備考1: String?
    public var 備考2: String?
    public var 備考3: String?
    public var 備考4: String?
    public var 備考5: String?
    public var 備考6: String?
    public var 備考7: String?
    public var 備考8: String?
    public var 備考9: String?
    public var 備考10: String?
    public var バーを移動しない: 工程図型.オンオフ型?
    public var 後続に影響しない範囲で遅く開始する: 工程図型.オンオフ型?
    public var 編集不可: 工程図型.編集不可型?
    public var 左シンボル形状: Int?
    public var 中シンボル形状: Int?
    public var 右シンボル形状: Int?
    public var 左シンボル色: Int?
    public var 中シンボル色: Int?
    public var 右シンボル色: Int?
    public var テキストの表示位置: 工程図型.テキストの表示位置型?
    public var url表示名1: String?
    public var url1: String?
    public var url表示名2: String?
    public var url2: String?
    public var url表示名3: String?
    public var url3: String?
    public var url表示名4: String?
    public var url4: String?
    public var url表示名5: String?
    public var url5: String?
    
    public init(第1階層グループ名称: String) {
        self.第1階層グループ名称 = 第1階層グループ名称
    }
    
    public func makeColumns() -> [String?] {
        return [
            self.第1階層グループID,
            self.第1階層グループ名称,
            self.第1階層グループ備考1,
            self.第1階層グループ備考2,
            self.第1階層グループ備考3,
            self.第1階層グループ備考4,
            self.第1階層グループ備考5,
            self.第1階層グループ備考6,
            self.第1階層グループ備考7,
            self.第1階層グループ備考8,
            self.第1階層グループ備考9,
            self.第1階層グループ備考10,
            self.第2階層グループID,
            self.第2階層グループ名称,
            self.第3階層グループID,
            self.第3階層グループ名称,
            self.第4階層グループID,
            self.第4階層グループ名称,
            self.第5階層グループID,
            self.第5階層グループ名称,
            self.第6階層グループID,
            self.第6階層グループ名称,
            self.第7階層グループID,
            self.第7階層グループ名称,
            self.第8階層グループID,
            self.第8階層グループ名称,
            self.第9階層グループID,
            self.第9階層グループ名称,
            self.第10階層グループID,
            self.第10階層グループ名称,
            self.行番号,
            self.工程ID,
            self.工程名称,
            self.初期工程開始日?.工程図日時,
            self.初期工程終了日?.工程図日時,
            self.工程開始日?.工程図日時,
            self.工程終了日?.工程図日時,
            self.工程期間?.description,
            self.カレンダID?.description,
            self.進捗度?.description,
            self.数量?.description,
            self.備考1,
            self.備考2,
            self.備考3,
            self.備考4,
            self.備考5,
            self.備考6,
            self.備考7,
            self.備考8,
            self.備考9,
            self.備考10,
            self.バーを移動しない?.code,
            self.後続に影響しない範囲で遅く開始する?.code,
            self.編集不可?.code,
            self.左シンボル形状?.description,
            self.左シンボル色?.description,
            self.中シンボル形状?.description,
            self.中シンボル色?.description,
            self.右シンボル形状?.description,
            self.右シンボル色?.description,
            self.テキストの表示位置?.code,
            self.url表示名1,
            self.url1,
            self.url表示名2,
            self.url2,
            self.url表示名3,
            self.url3,
            self.url表示名4,
            self.url4,
            self.url表示名5,
            self.url5,
        ]
    }
}
