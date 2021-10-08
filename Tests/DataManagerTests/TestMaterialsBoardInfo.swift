//
//  Test資材板情報.swift
//  DataManagerTests
//
//  Created by manager on 2020/03/28.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import XCTest
@testable import DataManager

class TestSizaiSheetInfo: XCTestCase {
    var info: 資材板情報型!

    func testEmpty() {
        info = 資材板情報型(製品名称: "", 規格: "")
        XCTAssertEqual(info.材質, "")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "")
        XCTAssertEqual(info.サイズ, "")
        XCTAssertEqual(info.高さ, nil)
        XCTAssertEqual(info.横幅, nil)
        XCTAssertEqual(info.備考, "")
    }
    
    // MARK: - ステンレス
    func testステンレス() {
        info = 資材板情報型(製品名称: "SUS304板 HL　310GH5", 規格: "1.5t　4x8(1219x2438)")
        XCTAssertEqual(info.材質, "SUS304")
        XCTAssertEqual(info.種類, "HL")
        XCTAssertEqual(info.板厚, "1.5")
        XCTAssertEqual(info.サイズ, "4x8")
        XCTAssertEqual(info.高さ, 1219)
        XCTAssertEqual(info.横幅, 2438)
        XCTAssertEqual(info.備考, "310GH5")
        
        info = 資材板情報型(製品名称: "ｶﾗｰｽﾃﾝﾚｽ HLチタンゴールド　SPV", 規格: "1.5t　4×8(1219×2438)")
        XCTAssertEqual(info.材質, "SUS304")
        XCTAssertEqual(info.種類, "HLチタンゴールド")
        XCTAssertEqual(info.板厚, "1.5")
        XCTAssertEqual(info.サイズ, "4×8")
        XCTAssertEqual(info.高さ, 1219)
        XCTAssertEqual(info.横幅, 2438)
        XCTAssertEqual(info.備考, "SPV")

        info = 資材板情報型(製品名称: "ｶﾗｰｽﾃﾝﾚｽ板 ﾌﾞﾛﾝｽﾞHL(SP-17/L-1)　SPV", 規格: "1.5t　4×8(1219×2438)")
        XCTAssertEqual(info.材質, "SUS304")
        XCTAssertEqual(info.種類, "ブロンズHL(SP-17/L-1)")
        XCTAssertEqual(info.板厚, "1.5")
        XCTAssertEqual(info.サイズ, "4×8")
        XCTAssertEqual(info.高さ, 1219)
        XCTAssertEqual(info.横幅, 2438)
        XCTAssertEqual(info.備考, "SPV")

        info = 資材板情報型(製品名称: "SUS304板 塗装用研磨  SPV\n", 規格: "8.0t　1x1(1000x1000)")
        XCTAssertEqual(info.材質, "SUS304")
        XCTAssertEqual(info.種類, "塗装用研磨")
        XCTAssertEqual(info.板厚, "8.0")
        XCTAssertEqual(info.サイズ, "1x1")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 1000)
        XCTAssertEqual(info.備考, "SPV")
        
        info = 資材板情報型(製品名称: "SUS304板 ｶﾗｰｽﾃﾝﾚｽ ﾌﾞﾗｯｸHL SR-15", 規格: "0.8t　1219x2000")
        XCTAssertEqual(info.材質, "SUS304")
        XCTAssertEqual(info.種類, "ブラックHL")
        XCTAssertEqual(info.板厚, "0.8")
        XCTAssertEqual(info.サイズ, "1219x2000")
        XCTAssertEqual(info.高さ, 1219)
        XCTAssertEqual(info.横幅, 2000)
        XCTAssertEqual(info.備考, "SR-15")
        
        info = 資材板情報型(製品名称: "ｶﾗｰｽﾃﾝﾚｽ HLﾌﾞﾗｯｸ　SR-15(Z-1)　SPV", 規格: "0.8t　1×2(1000×2000)")
        XCTAssertEqual(info.材質, "SUS304")
        XCTAssertEqual(info.種類, "HLブラック")
        XCTAssertEqual(info.板厚, "0.8")
        XCTAssertEqual(info.サイズ, "1×2")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 2000)
        XCTAssertEqual(info.備考, "SR-15(Z-1) SPV")
    }

    // MARK: - スチール
    func testスチール() {
        info = 資材板情報型(製品名称: "スチール　ボンデ鋼板(表面処理ﾃﾞﾝｷ)", 規格: "1.6t　5×10")
        XCTAssertEqual(info.材質, "スチール")
        XCTAssertEqual(info.種類, "ボンデ鋼板(表面処理デンキ)")
        XCTAssertEqual(info.板厚, "1.6")
        XCTAssertEqual(info.サイズ, "5×10")
        XCTAssertEqual(info.高さ, 1524)
        XCTAssertEqual(info.横幅, 3048)
        XCTAssertEqual(info.備考, "")
        
        info = 資材板情報型(製品名称: "コールテン鋼", 規格: "4.5t　4×8")
        XCTAssertEqual(info.材質, "コールテン鋼")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "4.5")
        XCTAssertEqual(info.サイズ, "4×8")
        XCTAssertEqual(info.高さ, 1219)
        XCTAssertEqual(info.横幅, 2438)
        XCTAssertEqual(info.備考, "")

        info = 資材板情報型(製品名称: "スチール　黒皮鉄板(鋼板)", 規格: "4.5t　3×6")
        XCTAssertEqual(info.材質, "スチール")
        XCTAssertEqual(info.種類, "黒皮鉄板(鋼板)")
        XCTAssertEqual(info.板厚, "4.5")
        XCTAssertEqual(info.サイズ, "3×6")
        XCTAssertEqual(info.高さ, 914)
        XCTAssertEqual(info.横幅, 1829)
        XCTAssertEqual(info.備考, "")
    }
    
    // MARK: - 真鍮
    func test真鍮() {
        info = 資材板情報型(製品名称: "BSP板　SPV", 規格: "0.5t　小板(365×1200)")
        XCTAssertEqual(info.材質, "BSP")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "0.5")
        XCTAssertEqual(info.サイズ, "小板")
        XCTAssertEqual(info.高さ, 365)
        XCTAssertEqual(info.横幅, 1200)
        XCTAssertEqual(info.備考, "SPV")

        info = 資材板情報型(製品名称: "BSP板　SPV", 規格: "5.0t　1×1(2枚1組)")
        XCTAssertEqual(info.材質, "BSP")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "5.0")
        XCTAssertEqual(info.サイズ, "1×1")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 1000)
        XCTAssertEqual(info.備考, "SPV")

        info = 資材板情報型(製品名称: "BSP板　SPV", 規格: "3.0t　1×2(1000×2000)")
        XCTAssertEqual(info.材質, "BSP")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "3.0")
        XCTAssertEqual(info.サイズ, "1×2")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 2000)
        XCTAssertEqual(info.備考, "SPV")
        
        info = 資材板情報型(製品名称: "BSP板　SPV", 規格: "2.3t　小板(365×1200)")
        XCTAssertEqual(info.材質, "BSP")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "2.3")
        XCTAssertEqual(info.サイズ, "小板")
        XCTAssertEqual(info.高さ, 365)
        XCTAssertEqual(info.横幅, 1200)
        XCTAssertEqual(info.備考, "SPV")
    }
    
    // MARK: - アルミ
    func testアルミ() {
        info = 資材板情報型(製品名称: "アルミ板 アルマイト　SPV", 規格: "3.0t　1×2(1000×2000)")
        XCTAssertEqual(info.材質, "アルミ")
        XCTAssertEqual(info.種類, "アルマイト")
        XCTAssertEqual(info.板厚, "3.0")
        XCTAssertEqual(info.サイズ, "1×2")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 2000)
        XCTAssertEqual(info.備考, "SPV")

        info = 資材板情報型(製品名称: "アルミ板 生(A1100)　SPV", 規格: "0.8t　4×8(1250×2500)")
        XCTAssertEqual(info.材質, "アルミ")
        XCTAssertEqual(info.種類, "生(A1100)")
        XCTAssertEqual(info.板厚, "0.8")
        XCTAssertEqual(info.サイズ, "4×8")
        XCTAssertEqual(info.高さ, 1250)
        XCTAssertEqual(info.横幅, 2500)
        XCTAssertEqual(info.備考, "SPV")

        info = 資材板情報型(製品名称: "アルミ板 52S(A5052)　SPV", 規格: "8.0t　1×1(1000×1000)")
        XCTAssertEqual(info.材質, "アルミ")
        XCTAssertEqual(info.種類, "52S(A5052)")
        XCTAssertEqual(info.板厚, "8.0")
        XCTAssertEqual(info.サイズ, "1×1")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 1000)
        XCTAssertEqual(info.備考, "SPV")
    }

    // MARK: - 銅
    func test銅() {
        info = 資材板情報型(製品名称: "CUP板　SPV", 規格: "5.0t　1×1(2枚1組)")
        XCTAssertEqual(info.材質, "CUP")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "5.0")
        XCTAssertEqual(info.サイズ, "1×1")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 1000)
        XCTAssertEqual(info.備考, "SPV")
    }

    // MARK: - アクリル
    func testアクリル() {
        info = 資材板情報型(製品名称: "アクリルミラーシルバー(デラグラスミラー)", 規格: "5.0t　3×6(915×1830)")
        XCTAssertEqual(info.材質, "アクリル")
        XCTAssertEqual(info.種類, "ミラーシルバー(デラグラスミラー)")
        XCTAssertEqual(info.板厚, "5.0")
        XCTAssertEqual(info.サイズ, "3×6")
        XCTAssertEqual(info.高さ, 915)
        XCTAssertEqual(info.横幅, 1830)
        XCTAssertEqual(info.備考, "")

        info = 資材板情報型(製品名称: "カナセライト　ガラス色(1329)", 規格: "10.0t　1×2(1000×2030)")
        XCTAssertEqual(info.材質, "カナセライト")
        XCTAssertEqual(info.種類, "ガラス色(1329)")
        XCTAssertEqual(info.板厚, "10.0")
        XCTAssertEqual(info.サイズ, "1×2")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 2030)
        XCTAssertEqual(info.備考, "")
        
        info = 資材板情報型(製品名称: "カナセライト　黒(1410)", 規格: "8.0t　定尺(1360×1110)")
        XCTAssertEqual(info.材質, "カナセライト")
        XCTAssertEqual(info.種類, "黒(1410)")
        XCTAssertEqual(info.板厚, "8.0")
        XCTAssertEqual(info.サイズ, "定尺")
        XCTAssertEqual(info.高さ, 1360)
        XCTAssertEqual(info.横幅, 1110)
        XCTAssertEqual(info.備考, "")

        info = 資材板情報型(製品名称: "スミペックス　乳半(032 ｵﾊﾟｰﾙ)", 規格: "5.0t　1×2(1000×2000)")
        XCTAssertEqual(info.材質, "スミペックス")
        XCTAssertEqual(info.種類, "乳半(032 オパール)")
        XCTAssertEqual(info.板厚, "5.0")
        XCTAssertEqual(info.サイズ, "1×2")
        XCTAssertEqual(info.高さ, 1040)
        XCTAssertEqual(info.横幅, 2040)
        XCTAssertEqual(info.備考, "")
    }
    
    // MARK: - アクリル
    func testチタン() {
        info = 資材板情報型(製品名称: "TP340Hチタン", 規格: "10.0t300×300")
        XCTAssertEqual(info.材質, "チタン")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "10.0")
        XCTAssertEqual(info.サイズ, "300×300")
        XCTAssertEqual(info.高さ, 300)
        XCTAssertEqual(info.横幅, 300)
        XCTAssertEqual(info.備考, "")
        
        info = 資材板情報型(製品名称: "チタンTP340H", 規格: "1.5t　500×500")
        XCTAssertEqual(info.材質, "チタン")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "1.5")
        XCTAssertEqual(info.サイズ, "500×500")
        XCTAssertEqual(info.高さ, 500)
        XCTAssertEqual(info.横幅, 500)
        XCTAssertEqual(info.備考, "")
        
        info = 資材板情報型(製品名称: "チタン　TP-340", 規格: "5.0t　500×500")
        XCTAssertEqual(info.材質, "チタン")
        XCTAssertEqual(info.種類, "")
        XCTAssertEqual(info.板厚, "5.0")
        XCTAssertEqual(info.サイズ, "500×500")
        XCTAssertEqual(info.高さ, 500)
        XCTAssertEqual(info.横幅, 500)
        XCTAssertEqual(info.備考, "")

        info = 資材板情報型(製品名称: "チタン材 TP340C　HL", 規格: "3.0t　1x1(1000x1000)")
        XCTAssertEqual(info.材質, "チタン")
        XCTAssertEqual(info.種類, "HL")
        XCTAssertEqual(info.板厚, "3.0")
        XCTAssertEqual(info.サイズ, "1x1")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 1000)
        XCTAssertEqual(info.備考, "")
        
        info = 資材板情報型(製品名称: "ﾁﾀﾝTP340板 パイブレーション　SPV", 規格: "5.0t　1x1(1000x1000)")
        XCTAssertEqual(info.材質, "チタン")
        XCTAssertEqual(info.種類, "パイブレーション")
        XCTAssertEqual(info.板厚, "5.0")
        XCTAssertEqual(info.サイズ, "1x1")
        XCTAssertEqual(info.高さ, 1000)
        XCTAssertEqual(info.横幅, 1000)
        XCTAssertEqual(info.備考, "SPV")
    }
    
    func testFormingList() {
        let list = フォーミング板リスト
        let dic = Dictionary(grouping: list) { $0.図番 }
        for list in dic {
            XCTAssertEqual(list.value.count, 1)
        }
    }
}
