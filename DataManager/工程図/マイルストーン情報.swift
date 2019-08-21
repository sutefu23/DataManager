//
//  マイルストーン情報.swift
//  DataManager
//
//  Created by manager on 8/20/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct マイルストーン情報型 : 工程図データ型 {
    public static let filename = "milestone.tsv"
    public static let header = "マイルストーンID\tマイルストーン名称\t行番号\t初期工程開始日\t初期工程終了日\t工程開始日\t工程終了日\t備考1\t備考2\t備考3\t備考4\t備考5\t備考6\t備考7\t備考8\t備考9\t備考10\tバーを移動しない\t後続に影響しない範囲で遅く開始する\t編集不可\t左シンボル形状\t中シンボル形状\t右シンボル形状\t左シンボル色\t中シンボル色\t右シンボル色\tテキストの表示位置\tURL表示名1\tURL1\tURL表示名2\tURL2\tURL表示名3\tURL3\tURL表示名4\tURL4\tURL表示名5\tURL5\tEOR"

    public var マイルストーンID : String
    public var マイルストーン名称 : String?
    public var 行番号 : String?
    public var 初期工程開始日 : Date?
    public var 初期工程終了日 : Date?
    public var 工程開始日 : Date?
    public var 工程終了日 : Date?
    public var 備考1 : String?
    public var 備考2 : String?
    public var 備考3 : String?
    public var 備考4 : String?
    public var 備考5 : String?
    public var 備考6 : String?
    public var 備考7 : String?
    public var 備考8 : String?
    public var 備考9 : String?
    public var 備考10 : String?
    public var バーを移動しない : 工程図型.オンオフ型?
    public var 後続に影響しない範囲で遅く開始する : 工程図型.オンオフ型?
    public var 編集不可 : 工程図型.編集不可型?
    public var 左シンボル形状 : Int?
    public var 中シンボル形状 : Int?
    public var 右シンボル形状 : Int?
    public var 左シンボル色 : Int?
    public var 中シンボル色 : Int?
    public var 右シンボル色 : Int?
    public var テキストの表示位置 : 工程図型.テキストの表示位置型?
    public var url表示名1 : String?
    public var url1 : String?
    public var url表示名2 : String?
    public var url2 : String?
    public var url表示名3 : String?
    public var url3 : String?
    public var url表示名4 : String?
    public var url4 : String?
    public var url表示名5 : String?
    public var url5 : String?

    public init(マイルストーンID:String) {
        self.マイルストーンID = マイルストーンID
    }
    
    public func makeColumns() -> [String?] {
        return [
            self.マイルストーンID,
            self.マイルストーン名称,
            self.行番号,
            self.初期工程開始日?.工程図日時,
            self.初期工程終了日?.工程図日時,
            self.工程開始日?.工程図日時,
            self.工程終了日?.工程図日時,
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
