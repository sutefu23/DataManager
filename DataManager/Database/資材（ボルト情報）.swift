//
//  資材（ボルト情報）.swift
//  DataManager
//
//  Created by manager on 2020/05/13.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 選択ボルト等型 {
    public let 図番: 図番型
    public let 社名先頭1文字: String
    public let 種類: String
    public let サイズ: String
    public let 長さ: String?
    public let 表示名: String
    
    init(図番: 図番型, 種類: String, サイズ: String, 長さ: String? = nil, 表示名: String? = nil) {
        self.図番 = 図番.toJapaneseNormal
        self.種類 = 種類.toJapaneseNormal
        self.長さ = 長さ?.toJapaneseNormal
        self.サイズ = サイズ.toJapaneseNormal
        if let title = 表示名 {
            self.表示名 = title
        } else {
            var name = 種類
            var prefix = "M"
            var suffix = "L"
            switch 種類 {
            case "ボルト":
                name = ""
            case "FB":
                prefix = ""
                suffix = ""
            default:
                break
            }
            if let length = 長さ {
                self.表示名 = "\(name)\(prefix)\(サイズ)x\(length)\(suffix)"
            } else {
                self.表示名 = "\(name)\(prefix)\(サイズ)"
            }
        }
        if let item = 資材型(図番: 図番) {
            if let ch = item.発注先名称.remove㈱㈲.first {
                self.社名先頭1文字 = String(ch)
            } else {
                self.社名先頭1文字 = ""
            }
        } else {
            self.社名先頭1文字 = ""
        }
    }
}

func searchボルト等(種類: String, サイズ: String, 長さ: Double?) -> 選択ボルト等型? {
    guard let list = ボルト等選択肢マップ[種類] else { return nil }
    let size = サイズ.toJapaneseNormal
    return list.first {
        if $0.サイズ != size { return false }
        if let length = 長さ {
            if let str = $0.長さ, Double(str) == length {
                return true
            } else {
                return false 
            }
        } else {
            return $0.長さ == nil
        }
    }
}

func searchボルト等(種類: String, サイズ: String, 長さ: String? = nil) -> 選択ボルト等型? {
    guard let list = ボルト等選択肢マップ[種類] else { return nil }
    let size = サイズ.toJapaneseNormal
    let length = 長さ?.toJapaneseNormal
    return list.first { $0.サイズ == size && $0.長さ == length }
}

let ボルト等選択肢マップ: [String : [選択ボルト等型]] = {
    Dictionary(grouping: ボルト等選択肢リスト) { $0.種類 }
}()

public let ボルト等選択肢リスト: [選択ボルト等型] = [
    // FB
    選択ボルト等型(図番: "991200", 種類: "FB", サイズ: "2", 長さ: "6"), //
    選択ボルト等型(図番: "991201", 種類: "FB", サイズ: "2", 長さ: "8"), //
    選択ボルト等型(図番: "991206", 種類: "FB", サイズ: "2", 長さ: "10"), //
    選択ボルト等型(図番: "991207", 種類: "FB", サイズ: "2", 長さ: "12"), //
    選択ボルト等型(図番: "991208", 種類: "FB", サイズ: "2", 長さ: "15"), //
    選択ボルト等型(図番: "991210", 種類: "FB", サイズ: "2", 長さ: "20"), //
    選択ボルト等型(図番: "991212", 種類: "FB", サイズ: "2", 長さ: "25"), //
    選択ボルト等型(図番: "991214", 種類: "FB", サイズ: "2", 長さ: "30"), //
    選択ボルト等型(図番: "996271", 種類: "FB", サイズ: "3", 長さ: "3"), //
    // ボルト
    選択ボルト等型(図番: "333", 種類: "ボルト", サイズ: "3/8"), //
    選択ボルト等型(図番: "301", 種類: "ボルト", サイズ: "2", 長さ: "20"), //
    選択ボルト等型(図番: "302", 種類: "ボルト", サイズ: "2", 長さ: "40"), //
    選択ボルト等型(図番: "943F", 種類: "ボルト", サイズ: "2", 長さ: "60"), //
    選択ボルト等型(図番: "303F", 種類: "ボルト", サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "304F", 種類: "ボルト", サイズ: "3", 長さ: "20"), //
    選択ボルト等型(図番: "305F", 種類: "ボルト", サイズ: "3", 長さ: "30"), //
    選択ボルト等型(図番: "306F", 種類: "ボルト", サイズ: "3", 長さ: "40"), //
    選択ボルト等型(図番: "307F", 種類: "ボルト", サイズ: "3", 長さ: "50"), //
    選択ボルト等型(図番: "308", 種類: "ボルト", サイズ: "4", 長さ: "30"), //
    選択ボルト等型(図番: "309", 種類: "ボルト", サイズ: "4", 長さ: "40"), //
    選択ボルト等型(図番: "310", 種類: "ボルト", サイズ: "4", 長さ: "60"), //
    選択ボルト等型(図番: "311", 種類: "ボルト", サイズ: "5", 長さ: "30"), //
    選択ボルト等型(図番: "312", 種類: "ボルト", サイズ: "5", 長さ: "60"), //
    選択ボルト等型(図番: "315", 種類: "ボルト", サイズ: "5", 長さ: "100"), //
    選択ボルト等型(図番: "316", 種類: "ボルト", サイズ: "6", 長さ: "100"), //
    選択ボルト等型(図番: "321", 種類: "ボルト", サイズ: "4", 長さ: "285"), //
    選択ボルト等型(図番: "322", 種類: "ボルト", サイズ: "5", 長さ: "285"), //
    選択ボルト等型(図番: "323", 種類: "ボルト", サイズ: "6", 長さ: "285"), //
    選択ボルト等型(図番: "324", 種類: "ボルト", サイズ: "8", 長さ: "285"), //
    選択ボルト等型(図番: "325", 種類: "ボルト", サイズ: "3/8", 長さ: "285"), //
    選択ボルト等型(図番: "326", 種類: "ボルト", サイズ: "10", 長さ: "285"), //
    選択ボルト等型(図番: "327", 種類: "ボルト", サイズ: "12", 長さ: "285"), //
    選択ボルト等型(図番: "314", 種類: "ボルト", サイズ: "16", 長さ: "285"), //
    選択ボルト等型(図番: "949", 種類: "ボルト", サイズ: "16", 長さ: "360"), //
    選択ボルト等型(図番: "328I", 種類: "ボルト", サイズ: "3"), //
    選択ボルト等型(図番: "329", 種類: "ボルト", サイズ: "4"), //
    選択ボルト等型(図番: "330", 種類: "ボルト", サイズ: "5"), //
    選択ボルト等型(図番: "331", 種類: "ボルト", サイズ: "6"), //
    選択ボルト等型(図番: "332", 種類: "ボルト", サイズ: "8"), //
    選択ボルト等型(図番: "334", 種類: "ボルト", サイズ: "10"), //
    選択ボルト等型(図番: "335", 種類: "ボルト", サイズ: "12"), //
    選択ボルト等型(図番: "2733", 種類: "ボルト", サイズ: "16"), //
// ナット
    選択ボルト等型(図番: "363", 種類: "ナット", サイズ: "3"), //
    選択ボルト等型(図番: "364", 種類: "ナット", サイズ: "4"), //
    選択ボルト等型(図番: "365", 種類: "ナット", サイズ: "5"), //
    選択ボルト等型(図番: "366", 種類: "ナット", サイズ: "6"), //
    選択ボルト等型(図番: "367", 種類: "ナット", サイズ: "8"), //
    選択ボルト等型(図番: "368", 種類: "ナット", サイズ: "3/8"), //
    選択ボルト等型(図番: "369", 種類: "ナット", サイズ: "10"), //
    選択ボルト等型(図番: "370", 種類: "ナット", サイズ: "12"), //
    
    // ワッシャー
    選択ボルト等型(図番: "381", 種類: "ワッシャー", サイズ: "3"), //
    選択ボルト等型(図番: "382", 種類: "ワッシャー", サイズ: "4"), //
    選択ボルト等型(図番: "383", 種類: "ワッシャー", サイズ: "5"), //
    選択ボルト等型(図番: "384", 種類: "ワッシャー", サイズ: "6"), //
    選択ボルト等型(図番: "385", 種類: "ワッシャー", サイズ: "8"), //
    選択ボルト等型(図番: "386", 種類: "ワッシャー", サイズ: "10"), //
    選択ボルト等型(図番: "387", 種類: "ワッシャー", サイズ: "12"), //
    // Sワッシャー
    選択ボルト等型(図番: "391", 種類: "Sワッシャー", サイズ: "5"), //
    選択ボルト等型(図番: "392", 種類: "Sワッシャー", サイズ: "6"), //
    選択ボルト等型(図番: "393", 種類: "Sワッシャー", サイズ: "8"), //
    選択ボルト等型(図番: "396", 種類: "Sワッシャー", サイズ: "10"), //
    選択ボルト等型(図番: "395", 種類: "Sワッシャー", サイズ: "12"), //
    // Cタッピング
    選択ボルト等型(図番: "996585", 種類: "Cタッピング", サイズ: "4", 長さ: "6"), //
// サンロックトラス
    選択ボルト等型(図番: "991680", 種類: "サンロックトラス", サイズ: "4", 長さ: "6"), //
    選択ボルト等型(図番: "991681", 種類: "サンロックトラス", サイズ: "4", 長さ: "8"), //
    選択ボルト等型(図番: "5827", 種類: "サンロックトラス", サイズ: "4", 長さ: "10"), //
    // サンロック特皿
    選択ボルト等型(図番: "7277", 種類: "サンロック特皿", サイズ: "2", 長さ: "5"),
    選択ボルト等型(図番: "5790", 種類: "サンロック特皿", サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "5922", 種類: "サンロック特皿", サイズ: "4", 長さ: "6"), //
    // 皿
    選択ボルト等型(図番: "7277", 種類: "皿", サイズ: "2", 長さ: "5"), //
    選択ボルト等型(図番: "3161", 種類: "皿", サイズ: "3", 長さ: "12"), //
    // 特皿
    選択ボルト等型(図番: "5020", 種類: "特皿", サイズ: "3", 長さ: "6"), //
    選択ボルト等型(図番: "499", 種類: "特皿", サイズ: "3", 長さ: "10"), //
    // トラス
    選択ボルト等型(図番: "580", 種類: "トラス", サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "39592", 種類: "トラス", サイズ: "4", 長さ: "6"), //
    選択ボルト等型(図番: "582", 種類: "トラス", サイズ: "5", 長さ: "10"), //
    選択ボルト等型(図番: "2569", 種類: "トラス", サイズ: "5", 長さ: "15"), //
    // スリムヘッド
    選択ボルト等型(図番: "9799", 種類: "スリムヘッド", サイズ: "4", 長さ: "6"), //
    選択ボルト等型(図番: "7276", 種類: "スリムヘッド", サイズ: "4", 長さ: "8"), //
    選択ボルト等型(図番: "9699", 種類: "スリムヘッド", サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "6711F", 種類: "スリムヘッド", サイズ: "3", 長さ: "6"), //
    // ナベ
    選択ボルト等型(図番: "3829", 種類: "ナベ", サイズ: "4", 長さ: "10"), //
    // テクスナベ
    選択ボルト等型(図番: "7275", 種類: "テクスナベ", サイズ: "4", 長さ: "19"), //
    // テクス皿
    選択ボルト等型(図番: "6571", 種類: "テクス皿", サイズ: "4", 長さ: "10"), //
    // 六角
    選択ボルト等型(図番: "3135", 種類: "六角", サイズ: "12", 長さ: "30"), //
    // スタッド
    選択ボルト等型(図番: "280", 種類: "スタッド", サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "3564", 種類: "スタッド", サイズ: "3", 長さ: "15"), //
    選択ボルト等型(図番: "281", 種類: "スタッド", サイズ: "3", 長さ: "20"), //
    選択ボルト等型(図番: "282", 種類: "スタッド", サイズ: "3", 長さ: "30"), //
    選択ボルト等型(図番: "283", 種類: "スタッド", サイズ: "3", 長さ: "40"), //
    選択ボルト等型(図番: "284", 種類: "スタッド", サイズ: "3", 長さ: "50"), //
    選択ボルト等型(図番: "2949", 種類: "スタッド", サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "3563", 種類: "スタッド", サイズ: "4", 長さ: "15"), //
    選択ボルト等型(図番: "286", 種類: "スタッド", サイズ: "4", 長さ: "20"), //
    選択ボルト等型(図番: "287", 種類: "スタッド", サイズ: "4", 長さ: "30"), //
    選択ボルト等型(図番: "288", 種類: "スタッド", サイズ: "4", 長さ: "40"), //
    選択ボルト等型(図番: "289", 種類: "スタッド", サイズ: "4", 長さ: "50"), //
    選択ボルト等型(図番: "3285", 種類: "スタッド", サイズ: "5", 長さ: "10"), //
    選択ボルト等型(図番: "9031", 種類: "スタッド", サイズ: "5", 長さ: "15"), //
    選択ボルト等型(図番: "290", 種類: "スタッド", サイズ: "5", 長さ: "20"), //
    選択ボルト等型(図番: "291", 種類: "スタッド", サイズ: "5", 長さ: "30"), //
    選択ボルト等型(図番: "292", 種類: "スタッド", サイズ: "5", 長さ: "40"), //
    選択ボルト等型(図番: "293", 種類: "スタッド", サイズ: "5", 長さ: "50"), //
    選択ボルト等型(図番: "294", 種類: "スタッド", サイズ: "5", 長さ: "60"), //
    選択ボルト等型(図番: "295", 種類: "スタッド", サイズ: "6", 長さ: "10"), //
    選択ボルト等型(図番: "296", 種類: "スタッド", サイズ: "6", 長さ: "20"), //
    選択ボルト等型(図番: "297", 種類: "スタッド", サイズ: "6", 長さ: "40"), //
    選択ボルト等型(図番: "9853", 種類: "スタッド", サイズ: "6", 長さ: "45"), //
    選択ボルト等型(図番: "8168", 種類: "スタッド", サイズ: "6", 長さ: "50"), //
    選択ボルト等型(図番: "298", 種類: "スタッド", サイズ: "6", 長さ: "55"), //
    // ストレートスタッド
    選択ボルト等型(図番: "2951", 種類: "ストレートスタッド", サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "9106", 種類: "ストレートスタッド", サイズ: "3", 長さ: "30"), //
    選択ボルト等型(図番: "9627", 種類: "ストレートスタッド", サイズ: "3", 長さ: "40"), //
    選択ボルト等型(図番: "3652", 種類: "ストレートスタッド", サイズ: "4", 長さ: "20"), //
    // ALスタッド
    選択ボルト等型(図番: "4326", 種類: "ALスタッド", サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "5754", 種類: "ALスタッド", サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "5755", 種類: "ALスタッド", サイズ: "4", 長さ: "20"), //
    // CDスタッド
    選択ボルト等型(図番: "9850", 種類: "CDスタッド", サイズ: "3", 長さ: "45"), //
    選択ボルト等型(図番: "9851", 種類: "CDスタッド", サイズ: "4", 長さ: "45"), //
    選択ボルト等型(図番: "9852", 種類: "CDスタッド", サイズ: "5", 長さ: "45"), //
    // 浮かしパイプ
    選択ボルト等型(図番: "3045", 種類: "浮かしパイプ", サイズ: "4", 長さ: "5"), //
    選択ボルト等型(図番: "3046", 種類: "浮かしパイプ", サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "3047", 種類: "浮かしパイプ", サイズ: "4", 長さ: "15"), //
    選択ボルト等型(図番: "3048", 種類: "浮かしパイプ", サイズ: "4", 長さ: "20"), //
    選択ボルト等型(図番: "407", 種類: "浮かしパイプ", サイズ: "6", 長さ: "5"), //
    選択ボルト等型(図番: "408", 種類: "浮かしパイプ", サイズ: "6", 長さ: "10"), //
    選択ボルト等型(図番: "409", 種類: "浮かしパイプ", サイズ: "6", 長さ: "15"), //
    ] + makeパイプリスト(種類: "浮かしパイプ") + makeパイプリスト(種類: "配線パイプ") + makeパイプリスト(種類: "電源用パイプ") + makeパイプリスト(種類: "丸パイプ")

func makeパイプリスト(種類: String) -> [選択ボルト等型] {
    return [
        選択ボルト等型(図番: "991070", 種類: 種類, サイズ: "5"), //
        選択ボルト等型(図番: "991071", 種類: 種類, サイズ: "6"), //
        選択ボルト等型(図番: "991069", 種類: 種類, サイズ: "7"), //
        選択ボルト等型(図番: "991072", 種類: 種類, サイズ: "8"), //
        選択ボルト等型(図番: "996019", 種類: 種類, サイズ: "9"), //
        選択ボルト等型(図番: "991073", 種類: 種類, サイズ: "10"), //
        選択ボルト等型(図番: "991076", 種類: 種類, サイズ: "12"), //
        選択ボルト等型(図番: "996200", 種類: 種類, サイズ: "13"), //
        選択ボルト等型(図番: "991768", 種類: 種類, サイズ: "14"), //
        選択ボルト等型(図番: "991082", 種類: 種類, サイズ: "15"), //
        選択ボルト等型(図番: "991083", 種類: 種類, サイズ: "16"), //
        選択ボルト等型(図番: "991085", 種類: 種類, サイズ: "19"), //
        選択ボルト等型(図番: "996310", 種類: 種類, サイズ: "21.7"), //
        選択ボルト等型(図番: "996139", 種類: 種類, サイズ: "22"), //
        選択ボルト等型(図番: "996085", 種類: 種類, サイズ: "25"), //
        選択ボルト等型(図番: "991113", 種類: 種類, サイズ: "32"), //
    ]
}
