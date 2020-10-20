//
//  資材（ボルト情報）.swift
//  DataManager
//
//  Created by manager on 2020/05/13.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 選択ボルト等種類型: String, Hashable {
    case FB
    case ボルト, オールアンカー, アイボルト
    case ナット, 鏡止めナット, 袋ナット, 高ナット
    case ワッシャー, Sワッシャー, 特寸ワッシャー
    case Cタッピング
    case サンロックトラス, サンロック特皿
    case 皿, 特皿
    case トラス
    case スリムヘッド
    case ナベ, なべ
    case テクスナベ, テクス皿, テクス特皿
    case 片ネジ, 木ビス, 皿木ビス
    case 六角
    case スタッド, ストレートスタッド, Sスタッド, ALスタッド
    case 三角コーナー, アングル
    case 浮かしパイプ, 配線パイプ, 電源用パイプ, 丸パイプ
    case 外注
    case SUSヒートン, BSPヒートン, メッキヒートン
    case ブラインドリベット
    case 真鍮釘
    case 角パイプD, 角パイプF, 角パイプHL
}

public struct 選択ボルト等型 {
    public let 図番: 図番型
    public let 社名先頭1文字: String
    public let 種類: 選択ボルト等種類型
    public let サイズ: String
    public let 長さ: String?
    public let 表示名: String
    public let 分割表示名1: String
    public let 分割表示名2: String

    init(図番: 図番型, 種類: 選択ボルト等種類型, サイズ: String, 長さ: String? = nil, 表示名: String? = nil) {
        self.図番 = 図番.toJapaneseNormal
        self.種類 = 種類
        self.長さ = 長さ?.toJapaneseNormal.lowercased()
        self.サイズ = サイズ.toJapaneseNormal.lowercased()
        var prefix: String = ""
        var suffix: String = ""
        var name: String
        if let title = 表示名 {
            name = title
        } else {
            name = 種類.rawValue
            prefix = "M"
            suffix = "L"
            switch 種類 {
            case .ボルト:
                name = ""
            case .FB, .外注, .三角コーナー, .SUSヒートン, .BSPヒートン, .メッキヒートン, .ブラインドリベット:
                prefix = ""
                suffix = ""
            case .鏡止めナット:
                prefix = "C-"
            default:
                break
            }
        }
        self.分割表示名1 = name
        switch 種類 {
        case .特寸ワッシャー:
            if let length = 長さ {
                self.分割表示名2 = "\(prefix)\(サイズ)tx\(length)\(suffix)"
            } else {
                self.分割表示名2 = "\(prefix)\(サイズ)t"
            }
        case .三角コーナー, .アングル:
            self.分割表示名2 = ""
        default:
            if let length = 長さ {
                self.分割表示名2 = "\(prefix)\(サイズ)x\(length)\(suffix)"
            } else {
                self.分割表示名2 = "\(prefix)\(サイズ)"
            }
        }
        self.表示名 = 分割表示名1 + 分割表示名2
        if let item = 資材型(図番: 図番) {
            if let ch = item.発注先名称.remove㈱㈲.first {
                self.社名先頭1文字 = String(ch)
            } else {
                self.社名先頭1文字 = ""
            }
        } else {
            self.社名先頭1文字 = "?"
        }
    }
    
    public var 資材登録あり: Bool {
        let item: 資材型? = 資材型(図番: self.図番)
        return item != nil
    }
}

func searchボルト等(種類: 選択ボルト等種類型, サイズ: String, 長さ: Double?) -> 選択ボルト等型? {
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

func searchボルト等(種類: 選択ボルト等種類型, サイズ: String?, 長さ: String? = nil) -> 選択ボルト等型? {
    guard let list = ボルト等選択肢マップ[種類] else { return nil }
    let size = サイズ?.toJapaneseNormal.lowercased()
    let length = 長さ?.toJapaneseNormal.lowercased()
    return list.first {
        (size == nil || $0.サイズ == size) && $0.長さ == length
    }
}

let ボルト等選択肢マップ: [選択ボルト等種類型 : [選択ボルト等型]] = {
    Dictionary(grouping: ボルト等選択肢リスト) { $0.種類 }
}()

public let ボルト等選択肢リスト: [選択ボルト等型] = [
    // FB
    選択ボルト等型(図番: "991200", 種類: .FB, サイズ: "2", 長さ: "6"), //
    選択ボルト等型(図番: "991201", 種類: .FB, サイズ: "2", 長さ: "8"), //
    選択ボルト等型(図番: "991205", 種類: .FB, サイズ: "2", 長さ: "10"), //
    選択ボルト等型(図番: "991207", 種類: .FB, サイズ: "2", 長さ: "12"), //
    選択ボルト等型(図番: "991208", 種類: .FB, サイズ: "2", 長さ: "15"), //
    選択ボルト等型(図番: "991210", 種類: .FB, サイズ: "2", 長さ: "20"), //
    選択ボルト等型(図番: "991212", 種類: .FB, サイズ: "2", 長さ: "25"), //
    選択ボルト等型(図番: "991214", 種類: .FB, サイズ: "2", 長さ: "30"), //
    選択ボルト等型(図番: "996271", 種類: .FB, サイズ: "3", 長さ: "3"), //
    選択ボルト等型(図番: "991176", 種類: .FB, サイズ: "5", 長さ: "5"), //
    // ボルト
    選択ボルト等型(図番: "333", 種類: .ボルト, サイズ: "3/8"), //
    選択ボルト等型(図番: "3392", 種類: .ボルト, サイズ: "2", 長さ: "10"), //
    選択ボルト等型(図番: "301", 種類: .ボルト, サイズ: "2", 長さ: "20"), //
    選択ボルト等型(図番: "8906", 種類: .ボルト, サイズ: "2", 長さ: "30"), //
    選択ボルト等型(図番: "302", 種類: .ボルト, サイズ: "2", 長さ: "40"), //
    選択ボルト等型(図番: "943F", 種類: .ボルト, サイズ: "2", 長さ: "60"), //
    選択ボルト等型(図番: "303F", 種類: .ボルト, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "304F", 種類: .ボルト, サイズ: "3", 長さ: "20"), //
    選択ボルト等型(図番: "305F", 種類: .ボルト, サイズ: "3", 長さ: "30"), //
    選択ボルト等型(図番: "306F", 種類: .ボルト, サイズ: "3", 長さ: "40"), //
    選択ボルト等型(図番: "307F", 種類: .ボルト, サイズ: "3", 長さ: "50"), //
    選択ボルト等型(図番: "308", 種類: .ボルト, サイズ: "4", 長さ: "30"), //
    選択ボルト等型(図番: "309", 種類: .ボルト, サイズ: "4", 長さ: "40"), //
    選択ボルト等型(図番: "310", 種類: .ボルト, サイズ: "4", 長さ: "60"), //
    選択ボルト等型(図番: "311", 種類: .ボルト, サイズ: "5", 長さ: "30"), //
    選択ボルト等型(図番: "312", 種類: .ボルト, サイズ: "5", 長さ: "60"), //
    選択ボルト等型(図番: "315", 種類: .ボルト, サイズ: "5", 長さ: "100"), //
    選択ボルト等型(図番: "316", 種類: .ボルト, サイズ: "6", 長さ: "100"), //
    選択ボルト等型(図番: "321", 種類: .ボルト, サイズ: "4", 長さ: "285"), //
    選択ボルト等型(図番: "322", 種類: .ボルト, サイズ: "5", 長さ: "285"), //
    選択ボルト等型(図番: "323", 種類: .ボルト, サイズ: "6", 長さ: "285"), //
    選択ボルト等型(図番: "324", 種類: .ボルト, サイズ: "8", 長さ: "285"), //
    選択ボルト等型(図番: "325", 種類: .ボルト, サイズ: "3/8", 長さ: "285"), //
    選択ボルト等型(図番: "326", 種類: .ボルト, サイズ: "10", 長さ: "285"), //
    選択ボルト等型(図番: "327", 種類: .ボルト, サイズ: "12", 長さ: "285"), //
    選択ボルト等型(図番: "2733", 種類: .ボルト, サイズ: "16", 長さ: "285"), //
    選択ボルト等型(図番: "949", 種類: .ボルト, サイズ: "16", 長さ: "360"), //
    選択ボルト等型(図番: "328F", 種類: .ボルト, サイズ: "3"), //
    選択ボルト等型(図番: "329", 種類: .ボルト, サイズ: "4"), //
    選択ボルト等型(図番: "330", 種類: .ボルト, サイズ: "5"), //
    選択ボルト等型(図番: "331", 種類: .ボルト, サイズ: "6"), //
    選択ボルト等型(図番: "332", 種類: .ボルト, サイズ: "8"), //
    選択ボルト等型(図番: "334", 種類: .ボルト, サイズ: "10"), //
    選択ボルト等型(図番: "335", 種類: .ボルト, サイズ: "12"), //
    選択ボルト等型(図番: "2733", 種類: .ボルト, サイズ: "16"), //
    // オールアンカー
    選択ボルト等型(図番: "991687", 種類: .オールアンカー, サイズ: "10", 長さ: "70"), //
    // アイボルト
    選択ボルト等型(図番: "3846", 種類: .アイボルト, サイズ: "6", 長さ: "14"), //
    選択ボルト等型(図番: "5646", 種類: .アイボルト, サイズ: "6", 長さ: "60"), //
    // ナット
    選択ボルト等型(図番: "362", 種類: .ナット, サイズ: "1.6"), //
    選択ボルト等型(図番: "372", 種類: .ナット, サイズ: "2"), //
    選択ボルト等型(図番: "363", 種類: .ナット, サイズ: "3"), //
    選択ボルト等型(図番: "364", 種類: .ナット, サイズ: "4"), //
    選択ボルト等型(図番: "365", 種類: .ナット, サイズ: "5"), //
    選択ボルト等型(図番: "366", 種類: .ナット, サイズ: "6"), //
    選択ボルト等型(図番: "367", 種類: .ナット, サイズ: "8"), //
    選択ボルト等型(図番: "368", 種類: .ナット, サイズ: "3/8"), //
    選択ボルト等型(図番: "369", 種類: .ナット, サイズ: "10"), //
    選択ボルト等型(図番: "370", 種類: .ナット, サイズ: "12"), //
    // 鏡止めナット
    選択ボルト等型(図番: "481", 種類: .鏡止めナット, サイズ: "10"), //
    選択ボルト等型(図番: "406", 種類: .鏡止めナット, サイズ: "11"), //
    選択ボルト等型(図番: "400", 種類: .鏡止めナット, サイズ: "12"), //
    選択ボルト等型(図番: "405", 種類: .鏡止めナット, サイズ: "13"), //
    選択ボルト等型(図番: "401", 種類: .鏡止めナット, サイズ: "15"), //
    選択ボルト等型(図番: "402", 種類: .鏡止めナット, サイズ: "20"), //
    選択ボルト等型(図番: "403", 種類: .鏡止めナット, サイズ: "25"), //
    // 袋ナット
    選択ボルト等型(図番: "379", 種類: .袋ナット, サイズ: "3"), //
    選択ボルト等型(図番: "373", 種類: .袋ナット, サイズ: "4"), //
    選択ボルト等型(図番: "374", 種類: .袋ナット, サイズ: "5"), //
    選択ボルト等型(図番: "375", 種類: .袋ナット, サイズ: "6"), //
    選択ボルト等型(図番: "376", 種類: .袋ナット, サイズ: "8"), //
    選択ボルト等型(図番: "377", 種類: .袋ナット, サイズ: "3/8"), //
    選択ボルト等型(図番: "359", 種類: .袋ナット, サイズ: "10"), //
    // 高ナット
    選択ボルト等型(図番: "2818", 種類: .高ナット, サイズ: "6", 長さ: "25"), //
    選択ボルト等型(図番: "5033I", 種類: .高ナット, サイズ: "8", 長さ: "50"), //
    選択ボルト等型(図番: "7608", 種類: .高ナット, サイズ: "10", 長さ: "50"), //
    // ワッシャー
    選択ボルト等型(図番: "380", 種類: .ワッシャー, サイズ: "2"), //
    選択ボルト等型(図番: "381", 種類: .ワッシャー, サイズ: "3"), //
    選択ボルト等型(図番: "382", 種類: .ワッシャー, サイズ: "4"), //
    選択ボルト等型(図番: "383", 種類: .ワッシャー, サイズ: "5"), //
    選択ボルト等型(図番: "384", 種類: .ワッシャー, サイズ: "6"), //
    選択ボルト等型(図番: "385", 種類: .ワッシャー, サイズ: "8"), //
    選択ボルト等型(図番: "386", 種類: .ワッシャー, サイズ: "10"), //
    選択ボルト等型(図番: "387", 種類: .ワッシャー, サイズ: "12"), //
    // Sワッシャー
    選択ボルト等型(図番: "3837", 種類: .Sワッシャー, サイズ: "2"), //
    選択ボルト等型(図番: "3206", 種類: .Sワッシャー, サイズ: "3"), //
    選択ボルト等型(図番: "390", 種類: .Sワッシャー, サイズ: "4"), //
    選択ボルト等型(図番: "391", 種類: .Sワッシャー, サイズ: "5"), //
    選択ボルト等型(図番: "392", 種類: .Sワッシャー, サイズ: "6"), //
    選択ボルト等型(図番: "393", 種類: .Sワッシャー, サイズ: "8"), //
    選択ボルト等型(図番: "394", 種類: .Sワッシャー, サイズ: "3/8"), //
    選択ボルト等型(図番: "396", 種類: .Sワッシャー, サイズ: "10"), //
    選択ボルト等型(図番: "395", 種類: .Sワッシャー, サイズ: "12"), //
    // 特寸ワッシャー
    選択ボルト等型(図番: "7399", 種類: .特寸ワッシャー, サイズ: "1.5", 長さ: "15φx6.5φ"), //
    選択ボルト等型(図番: "7400", 種類: .特寸ワッシャー, サイズ: "1.5", 長さ: "20φx6.5φ"), //
    選択ボルト等型(図番: "9890", 種類: .特寸ワッシャー, サイズ: "1.5", 長さ: "20φx8.5φ"), //
    選択ボルト等型(図番: "7401", 種類: .特寸ワッシャー, サイズ: "1.5", 長さ: "20φx10.5φ"), //
    選択ボルト等型(図番: "997147", 種類: .特寸ワッシャー, サイズ: "1.5", 長さ: "25φx8.5φ"), //
    選択ボルト等型(図番: "7299", 種類: .特寸ワッシャー, サイズ: "1.5", 長さ: "25φx10.5φ"), //
    選択ボルト等型(図番: "9794", 種類: .特寸ワッシャー, サイズ: "1.5", 長さ: "30φx10.5φ"), //
    選択ボルト等型(図番: "7377", 種類: .特寸ワッシャー, サイズ: "1.5", 長さ: "50φx8.5φ"), //
    選択ボルト等型(図番: "7291", 種類: .特寸ワッシャー, サイズ: "2", 長さ: "18φx5.4φ"), //
    選択ボルト等型(図番: "7402", 種類: .特寸ワッシャー, サイズ: "2", 長さ: "30φx10.5φ"), //
    選択ボルト等型(図番: "7251", 種類: .特寸ワッシャー, サイズ: "2", 長さ: "40φx8.5φ"), //
    // Cタッピング
    選択ボルト等型(図番: "996585", 種類: .Cタッピング, サイズ: "4", 長さ: "6"), //
    // サンロックトラス
    選択ボルト等型(図番: "991680", 種類: .サンロックトラス, サイズ: "4", 長さ: "6"), //
    選択ボルト等型(図番: "991681", 種類: .サンロックトラス, サイズ: "4", 長さ: "8"), //
    選択ボルト等型(図番: "5827", 種類: .サンロックトラス, サイズ: "4", 長さ: "10"), //
    // サンロック特皿
    選択ボルト等型(図番: "7277", 種類: .サンロック特皿, サイズ: "2", 長さ: "5"),
    選択ボルト等型(図番: "5922", 種類: .サンロック特皿, サイズ: "4", 長さ: "6"), //
    選択ボルト等型(図番: "991682", 種類: .サンロック特皿, サイズ: "4", 長さ: "8"), //
    選択ボルト等型(図番: "5790", 種類: .サンロック特皿, サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "5825", 種類: .サンロック特皿, サイズ: "4", 長さ: "16"), //
    選択ボルト等型(図番: "991593", 種類: .サンロック特皿, サイズ: "4", 長さ: "20"), //
    // 皿
    選択ボルト等型(図番: "3185", 種類: .皿, サイズ: "1.6", 長さ: "12"), //
    選択ボルト等型(図番: "548", 種類: .皿, サイズ: "2", 長さ: "3"), //
    選択ボルト等型(図番: "547", 種類: .皿, サイズ: "2", 長さ: "4"), //
    選択ボルト等型(図番: "3714", 種類: .皿, サイズ: "2", 長さ: "5"), //
    選択ボルト等型(図番: "9094", 種類: .皿, サイズ: "2", 長さ: "8"), //
    選択ボルト等型(図番: "2987", 種類: .皿, サイズ: "2", 長さ: "9"), //
    選択ボルト等型(図番: "5119", 種類: .皿, サイズ: "2", 長さ: "10"), //
    選択ボルト等型(図番: "4912", 種類: .皿, サイズ: "2", 長さ: "15"), //
    選択ボルト等型(図番: "997110", 種類: .皿, サイズ: "2", 長さ: "17"), //
    選択ボルト等型(図番: "6712", 種類: .皿, サイズ: "2", 長さ: "25"), //
    選択ボルト等型(図番: "2033", 種類: .皿, サイズ: "2", 長さ: "30"), //

    選択ボルト等型(図番: "7335", 種類: .皿, サイズ: "3", 長さ: "3"), //
    選択ボルト等型(図番: "8291", 種類: .皿, サイズ: "3", 長さ: "5"), //
    選択ボルト等型(図番: "7353", 種類: .皿, サイズ: "3", 長さ: "6"), //
    選択ボルト等型(図番: "553", 種類: .皿, サイズ: "3", 長さ: "8"), //
    選択ボルト等型(図番: "3161", 種類: .皿, サイズ: "3", 長さ: "12"), //
    選択ボルト等型(図番: "8574", 種類: .皿, サイズ: "3", 長さ: "15"), //
    選択ボルト等型(図番: "3335", 種類: .皿, サイズ: "3", 長さ: "20"), //
    選択ボルト等型(図番: "7285", 種類: .皿, サイズ: "3", 長さ: "50"), //

    選択ボルト等型(図番: "3161", 種類: .皿, サイズ: "4", 長さ: "5"), //
    選択ボルト等型(図番: "3161", 種類: .皿, サイズ: "4", 長さ: "20"), //
    選択ボルト等型(図番: "4377", 種類: .皿, サイズ: "4", 長さ: "25"), //
    選択ボルト等型(図番: "3161", 種類: .皿, サイズ: "4", 長さ: "35"), //
    // 特皿
    選択ボルト等型(図番: "7277", 種類: .特皿, サイズ: "2", 長さ: "5"),
    選択ボルト等型(図番: "5020", 種類: .特皿, サイズ: "3", 長さ: "6"), //
    選択ボルト等型(図番: "499", 種類: .特皿, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "3161", 種類: .特皿, サイズ: "3", 長さ: "12"),
    選択ボルト等型(図番: "7285", 種類: .特皿, サイズ: "3", 長さ: "50"), //
    選択ボルト等型(図番: "3033I", 種類: .特皿, サイズ: "4", 長さ: "6"), //
    選択ボルト等型(図番: "502", 種類: .特皿, サイズ: "4", 長さ: "15"), //
    選択ボルト等型(図番: "503", 種類: .特皿, サイズ: "4", 長さ: "20"), //
    選択ボルト等型(図番: "3374", 種類: .特皿, サイズ: "4", 長さ: "40"), //
    選択ボルト等型(図番: "505", 種類: .特皿, サイズ: "4", 長さ: "50"), //
    // トラス
    選択ボルト等型(図番: "3527", 種類: .トラス, サイズ: "3", 長さ: "6"), //
    選択ボルト等型(図番: "580", 種類: .トラス, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "7341", 種類: .トラス, サイズ: "4", 長さ: "4"), //
    選択ボルト等型(図番: "3959I", 種類: .トラス, サイズ: "4", 長さ: "6"), //
    選択ボルト等型(図番: "7344", 種類: .トラス, サイズ: "4", 長さ: "16"), //
    選択ボルト等型(図番: "591A", 種類: .トラス, サイズ: "4", 長さ: "20"), //
    選択ボルト等型(図番: "582", 種類: .トラス, サイズ: "5", 長さ: "10"), //
    選択ボルト等型(図番: "2569", 種類: .トラス, サイズ: "5", 長さ: "15"), //
    選択ボルト等型(図番: "385", 種類: .トラス, サイズ: "5", 長さ: "16"), //
    // スリムヘッド
    選択ボルト等型(図番: "998174", 種類: .スリムヘッド, サイズ: "2", 長さ: "5"), //
    選択ボルト等型(図番: "9799", 種類: .スリムヘッド, サイズ: "4", 長さ: "6"), //
    選択ボルト等型(図番: "7276", 種類: .スリムヘッド, サイズ: "4", 長さ: "8"), //
    選択ボルト等型(図番: "9699", 種類: .スリムヘッド, サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "6711F", 種類: .スリムヘッド, サイズ: "3", 長さ: "6"), //
    // ナベ
    選択ボルト等型(図番: "525", 種類: .ナベ, サイズ: "3", 長さ: "4"), //
    選択ボルト等型(図番: "528", 種類: .ナベ, サイズ: "3", 長さ: "5"), //
    選択ボルト等型(図番: "526", 種類: .ナベ, サイズ: "3", 長さ: "6"), //
    選択ボルト等型(図番: "527", 種類: .ナベ, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "3829", 種類: .ナベ, サイズ: "4", 長さ: "10"), //
    
    選択ボルト等型(図番: "525", 種類: .なべ, サイズ: "3", 長さ: "4"), //
    選択ボルト等型(図番: "528", 種類: .なべ, サイズ: "3", 長さ: "5"), //
    選択ボルト等型(図番: "526", 種類: .なべ, サイズ: "3", 長さ: "6"), //
    選択ボルト等型(図番: "527", 種類: .なべ, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "3829", 種類: .なべ, サイズ: "4", 長さ: "10"), //
    // テクスナベ
    選択ボルト等型(図番: "7275", 種類: .テクスナベ, サイズ: "4", 長さ: "19"), //
    // テクス皿
    選択ボルト等型(図番: "6571", 種類: .テクス皿, サイズ: "4", 長さ: "10"), //
    // テクス特皿
    選択ボルト等型(図番: "643", 種類: .テクス特皿, サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "6626", 種類: .テクス特皿, サイズ: "4", 長さ: "19"), //
    // 片ネジ
    選択ボルト等型(図番: "9652", 種類: .片ネジ, サイズ: "2", 長さ: "60"), //
    選択ボルト等型(図番: "3200", 種類: .片ネジ, サイズ: "2", 長さ: "100"), //
    // 皿木ビス
    選択ボルト等型(図番: "2631", 種類: .皿木ビス, サイズ: "2.1", 長さ: "10"), //
    選択ボルト等型(図番: "3401", 種類: .皿木ビス, サイズ: "3.1", 長さ: "10"), //
    // 木ビス
    選択ボルト等型(図番: "637", 種類: .木ビス, サイズ: "3.1", 長さ: "20"), //
    // 六角
    選択ボルト等型(図番: "3274I", 種類: .六角, サイズ: "6", 長さ: "10"), //
    選択ボルト等型(図番: "340I", 種類: .六角, サイズ: "6", 長さ: "15"), //
    選択ボルト等型(図番: "341D", 種類: .六角, サイズ: "6", 長さ: "20"), //
    選択ボルト等型(図番: "389I", 種類: .六角, サイズ: "6", 長さ: "50"), //
    選択ボルト等型(図番: "343I", 種類: .六角, サイズ: "8", 長さ: "20"), //
    選択ボルト等型(図番: "344", 種類: .六角, サイズ: "8", 長さ: "25"), //
    選択ボルト等型(図番: "3146", 種類: .六角, サイズ: "8", 長さ: "60"), //
    選択ボルト等型(図番: "3464", 種類: .六角, サイズ: "10", 長さ: "40"), //
    選択ボルト等型(図番: "3135", 種類: .六角, サイズ: "12", 長さ: "30"), //
    // スタッド
    選択ボルト等型(図番: "280", 種類: .スタッド, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "3564", 種類: .スタッド, サイズ: "3", 長さ: "15"), //
    選択ボルト等型(図番: "281", 種類: .スタッド, サイズ: "3", 長さ: "20"), //
    選択ボルト等型(図番: "282", 種類: .スタッド, サイズ: "3", 長さ: "30"), //
    選択ボルト等型(図番: "283", 種類: .スタッド, サイズ: "3", 長さ: "40"), //
    選択ボルト等型(図番: "284", 種類: .スタッド, サイズ: "3", 長さ: "50"), //
    選択ボルト等型(図番: "2949", 種類: .スタッド, サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "3563", 種類: .スタッド, サイズ: "4", 長さ: "15"), //
    選択ボルト等型(図番: "286", 種類: .スタッド, サイズ: "4", 長さ: "20"), //
    選択ボルト等型(図番: "517", 種類: .スタッド, サイズ: "4", 長さ: "25"), //
    選択ボルト等型(図番: "287", 種類: .スタッド, サイズ: "4", 長さ: "30"), //
    選択ボルト等型(図番: "288", 種類: .スタッド, サイズ: "4", 長さ: "40"), //
    選択ボルト等型(図番: "289", 種類: .スタッド, サイズ: "4", 長さ: "50"), //
    選択ボルト等型(図番: "3285", 種類: .スタッド, サイズ: "5", 長さ: "10"), //
    選択ボルト等型(図番: "509", 種類: .スタッド, サイズ: "5", 長さ: "15"), //
    選択ボルト等型(図番: "290", 種類: .スタッド, サイズ: "5", 長さ: "20"), //
    選択ボルト等型(図番: "291", 種類: .スタッド, サイズ: "5", 長さ: "30"), //
    選択ボルト等型(図番: "292", 種類: .スタッド, サイズ: "5", 長さ: "40"), //
    選択ボルト等型(図番: "293", 種類: .スタッド, サイズ: "5", 長さ: "50"), //
    選択ボルト等型(図番: "294", 種類: .スタッド, サイズ: "5", 長さ: "60"), //
    選択ボルト等型(図番: "295", 種類: .スタッド, サイズ: "6", 長さ: "10"), //
    選択ボルト等型(図番: "296", 種類: .スタッド, サイズ: "6", 長さ: "20"), //
    選択ボルト等型(図番: "7286", 種類: .スタッド, サイズ: "6", 長さ: "30"), //
    選択ボルト等型(図番: "297", 種類: .スタッド, サイズ: "6", 長さ: "40"), //
    選択ボルト等型(図番: "497", 種類: .スタッド, サイズ: "6", 長さ: "45"), //
    選択ボルト等型(図番: "508", 種類: .スタッド, サイズ: "6", 長さ: "50"), //
    選択ボルト等型(図番: "298", 種類: .スタッド, サイズ: "6", 長さ: "55"), //
    選択ボルト等型(図番: "512", 種類: .スタッド, サイズ: "8", 長さ: "20"), //
    選択ボルト等型(図番: "7287", 種類: .スタッド, サイズ: "8", 長さ: "30"), //
    選択ボルト等型(図番: "7289", 種類: .スタッド, サイズ: "8", 長さ: "50"), //
    選択ボルト等型(図番: "299", 種類: .スタッド, サイズ: "8", 長さ: "55"), //
    選択ボルト等型(図番: "7290", 種類: .スタッド, サイズ: "8", 長さ: "60"), //
    // ストレートスタッド
    選択ボルト等型(図番: "2951", 種類: .ストレートスタッド, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "9106", 種類: .ストレートスタッド, サイズ: "3", 長さ: "30"), //
    選択ボルト等型(図番: "9627", 種類: .ストレートスタッド, サイズ: "3", 長さ: "40"), //
    選択ボルト等型(図番: "3652", 種類: .ストレートスタッド, サイズ: "4", 長さ: "20"), //
    選択ボルト等型(図番: "2951", 種類: .Sスタッド, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "9106", 種類: .Sスタッド, サイズ: "3", 長さ: "30"), //
    選択ボルト等型(図番: "9627", 種類: .Sスタッド, サイズ: "3", 長さ: "40"), //
    選択ボルト等型(図番: "3652", 種類: .Sスタッド, サイズ: "4", 長さ: "20"), //
    // ALスタッド
    選択ボルト等型(図番: "4326", 種類: .ALスタッド, サイズ: "3", 長さ: "10"), //
    選択ボルト等型(図番: "5754", 種類: .ALスタッド, サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "5755", 種類: .ALスタッド, サイズ: "4", 長さ: "20"), //
    // CDスタッド
    選択ボルト等型(図番: "9850", 種類: .スタッド, サイズ: "3", 長さ: "45"), //
    選択ボルト等型(図番: "9851", 種類: .スタッド, サイズ: "4", 長さ: "45"), //
    選択ボルト等型(図番: "9852", 種類: .スタッド, サイズ: "5", 長さ: "45"), //
    // 三角コーナー
    選択ボルト等型(図番: "2016", 種類: .三角コーナー, サイズ: ""), //
    // アングル
    選択ボルト等型(図番: "996367", 種類: .アングル, サイズ: "30×30", 長さ: "5"), //
    // 外注
    選択ボルト等型(図番: "3734", 種類: .外注, サイズ: "15"), //
    選択ボルト等型(図番: "3590", 種類: .外注, サイズ: "20"), //
    // SUSヒートン
    選択ボルト等型(図番: "2634", 種類: .SUSヒートン, サイズ: ""), //
    // BSPヒートン
    選択ボルト等型(図番: "4457", 種類: .BSPヒートン, サイズ: ""), //
    // メッキヒートン
    選択ボルト等型(図番: "7375", 種類: .メッキヒートン, サイズ: ""), //
    // ブラインドリベット
    選択ボルト等型(図番: "2583", 種類: .ブラインドリベット, サイズ: ""), //
    // 真鍮釘
    選択ボルト等型(図番: "7322", 種類: .真鍮釘, サイズ: "1.8", 長さ: "22"), //
    
    // 浮かしパイプ
    選択ボルト等型(図番: "3045", 種類: .浮かしパイプ, サイズ: "4", 長さ: "5"), //
    選択ボルト等型(図番: "3046", 種類: .浮かしパイプ, サイズ: "4", 長さ: "10"), //
    選択ボルト等型(図番: "3047", 種類: .浮かしパイプ, サイズ: "4", 長さ: "15"), //
    選択ボルト等型(図番: "3048", 種類: .浮かしパイプ, サイズ: "4", 長さ: "20"), //
    選択ボルト等型(図番: "407", 種類: .浮かしパイプ, サイズ: "6", 長さ: "5"), //
    選択ボルト等型(図番: "408", 種類: .浮かしパイプ, サイズ: "6", 長さ: "10"), //
    選択ボルト等型(図番: "409", 種類: .浮かしパイプ, サイズ: "6", 長さ: "15"), //
    
    // 角パイプ
    /*
    選択ボルト等型(図番: "990900", 種類: .角パイプD, サイズ: "1.0t7角", 長さ: "4"), //
    選択ボルト等型(図番: "990904", 種類: .角パイプD, サイズ: "1.0t9角", 長さ: "4"), //
    選択ボルト等型(図番: "990909", 種類: .角パイプD, サイズ: "1.0t10角", 長さ: "4"), //
    選択ボルト等型(図番: "996918", 種類: .角パイプD, サイズ: "1.0t13角", 長さ: "4"), //
    選択ボルト等型(図番: "990912", 種類: .角パイプD, サイズ: "1.2t10角", 長さ: "4"), //
    選択ボルト等型(図番: "990918", 種類: .角パイプD, サイズ: "1.2t12角", 長さ: "4"), //
    選択ボルト等型(図番: "990921", 種類: .角パイプD, サイズ: "1.2t13角", 長さ: "4"), //
    選択ボルト等型(図番: "990924", 種類: .角パイプD, サイズ: "1.2t14角", 長さ: "4"), //
    選択ボルト等型(図番: "990927", 種類: .角パイプD, サイズ: "1.2t16角", 長さ: "5"), //
    選択ボルト等型(図番: "990933", 種類: .角パイプD, サイズ: "1.2t19角", 長さ: "5"), //
    選択ボルト等型(図番: "999854", 種類: .角パイプD, サイズ: "1.2t21角", 長さ: "5"), //
    選択ボルト等型(図番: "990879", 種類: .角パイプD, サイズ: "1.2t25.4角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t16角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t19角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t20角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t21角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t22角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t25角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t30角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t32角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t35角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t40角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t50角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t60角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t14角", 長さ: "4"), //
    
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t32角", 長さ: "6"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t16角", 長さ: "6"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t30角", 長さ: "6"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t30角", 長さ: "4"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t25角", 長さ: "4"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t20角", 長さ: "4"), //
    
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t角", 長さ: "5"), //
    選択ボルト等型(図番: "409", 種類: .角パイプD, サイズ: "1.5t角", 長さ: "5"), //
*/
    ] + makeパイプリスト(種類: .浮かしパイプ) + makeパイプリスト(種類: .配線パイプ) + makeパイプリスト(種類: .電源用パイプ) + makeパイプリスト(種類: .丸パイプ)

func makeパイプリスト(種類: 選択ボルト等種類型) -> [選択ボルト等型] {
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
