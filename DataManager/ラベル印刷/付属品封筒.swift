//
//  付属品封筒.swift
//  DataManager
//
//  Created by manager on 2020/05/25.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
#if os(tvOS)
#else
import PDFKit

public class 付属品封筒型 {
    private let order: 指示書型

    public init?(_ number: 伝票番号型) {
        guard let order = (try? 指示書キャッシュ.find(number)) else { return nil }
        self.order = order
    }
    
    public init(_ order: 指示書型) {
        self.order = order
    }
    
    public func makePDFPage(offsetX: Double = 0, offsetY: Double = -7.0) -> PaperPDFPage {
        let page = PaperPDFPage(paperType: .長形3号, margin: 0)
        #if targetEnvironment(macCatalyst)
        page.rotationPrint = true
        #endif
        let inset = 1.0
//        let setCount = order.セット数値
        // 伝票番~
        let rect0 = PaperRect(x: offsetX + 5, y: offsetY + 7, width: 110, height: 15)
//        rect0.append(PaperRoundBox(origin: (x: 10, y: 8), size: (width: 90, height: 15), r: 3))
//        rect0.append(PaperPath.makeLine(from: (x: 87, y: 9), to: (x: 87, y: 22)))
//        rect0.append(PaperPath.makeLine(from: (x: 87, y: 12), to: (x: 100, y: 12), lineWidth: 0.5))
//        rect0.append(PaperText(mmx: 86.5, mmy: 9.5, inset: inset, text: "附属品準備", fontSize: 7, bold: false, color: .black))
        rect0.append(PaperRoundBox(origin: (x: 15, y: 9), size: (width: 80, height: 13), r: 3))
        rect0.append(PaperText(mmx: 26, mmy: 15, inset: inset, text: "取付附属品表", fontSize: 28, bold: false, color: .black))
//        rect0.append(PaperText(mmx: 19, mmy: 15, inset: inset, text: "取付附属品表", fontSize: 30, bold: false, color: .black))
        page.append(rect0)
        let rect1 = PaperRect(x: offsetX + 5, y: offsetY + 20, width: 110, height: 25)
        rect1.append(PaperText(mmx: 0, mmy: 15, text: "伝票No \(order.伝票番号.表示用文字列)", fontSize: 14, bold: false, color: .black))
        rect1.append(PaperText(mmx: 75, mmy: 15, text: "出荷 \(order.出荷納期.monthDayJString)", fontSize: 14, bold: false, color: .black))
        if order.取引先?.is原稿社名不要 != true {
            rect1.append(PaperText(mmx: 0, mmy: 25, text: "社名　\(order.社名)　様", fontSize: 14, bold: false, color: .black))
        }
        
        page.append(rect1)
        let rect2 = PaperRect(x: offsetX + 5, y: offsetY + 50, width: 110, height: 25)
        let title = order.品名
        let titleCount = title.count
        if titleCount <= 16 {
        rect2.append(PaperText(mmx: 0, mmy: 4, inset: inset, text: "品名 \(title)", fontSize: 18, bold: false, color: .black))
        } else if titleCount <= 24 {
            rect2.append(PaperText(mmx: 0, mmy: 4, inset: inset, text: "品名", fontSize: 18, bold: false, color: .black))
            rect2.append(PaperText(mmx: 13, mmy: 4, inset: inset, text: title, fontSize: 13, bold: false, color: .black))
        } else {
            let title1 = String(title.prefix(min(24, titleCount - titleCount/2)))
            let title2 = String(title.suffix(min(23, titleCount/2)))
            rect2.append(PaperText(mmx: 0, mmy: 4, inset: inset, text: "品名", fontSize: 18, bold: false, color: .black))
            rect2.append(PaperText(mmx: 13, mmy: 1, inset: inset, text: title1, fontSize: 14, bold: false, color: .black))
            rect2.append(PaperText(mmx: 13, mmy: 6, inset: inset, text: title2, fontSize: 14, bold: false, color: .black))
        }
        rect2.append(PaperText(mmx: 0, mmy: 14, inset: inset, text: "取付に必要な部品が入っています", fontSize: 14, bold: false, color: .black))
        rect2.append(PaperText(mmx: 0, mmy: 21, inset: inset, text: "開封の上、ご確認ください", fontSize: 14, bold: false, color: .black))
        
        let setinfo = Int(order.セット数値)
        rect2.append(PaperText(mmx: 5, mmy: 30, inset: inset, text: "原稿　　\(setinfo)　セット", fontSize: 14, bold: false, color: .black))
        rect2.append(PaperText(mmx: 5, mmy: 40, inset: inset, text: "補修材 　　　　個", fontSize: 14, bold: false, color: .black))
        rect2.append(PaperPath.makeBox(origin: (x: 0.5, y: 39.15), size: (width: 4, height: 4)))
        // 印鑑欄
        var 印鑑欄: [(text: String, offset: Double)] = []
        if order.側面社内塗装あり { 印鑑欄.append(("塗装", 3.6)) }
        印鑑欄.append(("附属品準備", -0.2))
        if order.外注塗装あり { 印鑑欄.append(("塗装", 3.6)) }
        if order.外注メッキあり { 印鑑欄.append(("メッキ", 2.0)) }
        印鑑欄.append(("品質管理", 0.8))
        let count = Double(印鑑欄.count)
        rect2.append(PaperPath.makeBox(origin: (x: 45+13*(5-count), y: 37), size: (width: 13*count, height: 16))) // 枠線
        rect2.append(PaperPath.makeLine(from: (x: 45+13*(5-count), y: 41), to: (x: 45+13*5, y: 41), lineWidth: 0.5)) // 横線
        for index in stride(from: 4.0, to: 5.0-count, by: -1.0) {
            rect2.append(PaperPath.makeLine(from: (x: 45+13*index, y: 37), to: (x: 45+13*index, y: 53))) // 縦線
        }
        印鑑欄.enumerated().forEach {
            let text = $0.element.text
            if text.isEmpty { return }
            let index = (5-count) + Double($0.offset)
            rect2.append(PaperText(mmx: 45+13*index + $0.element.offset, mmy: 38.15, inset: inset, text: text, fontSize: 7, bold: false, color: .black)) // 欄2
        }
        // バーコード
        if let barcode = DMBarCode(code39: "\(order.伝票番号.整数値)") { // 200,83 or CGPoint(x: convertPoint(mm: 68.5-count*13), y: convertPoint(mm: 53) - 15)
            let bpos = CGPoint(x: 200, y: convertPoint(mm: 138.75))
            let object4 = PaperBarCode(barCode: barcode, rect: CGRect(origin: bpos, size: CGSize(width: 110, height: 15)), fontSize: 0)
            rect2.append(object4)
        }
        
        page.append(rect2)
        // 附属品一覧
        let rect3 = PaperRect(x: offsetX + 5, y: offsetY + 100, width: 110, height: 80)
        rect3.append(PaperText(mmx: 0, mmy: 0, text: "付属品", fontSize: 14, bold: false, color: .black))
        // 印刷対象列挙
        var vlist: [VData] = []
        let source = (try? order.キャッシュ資材使用記録()) ?? []
        if source.contains(where: { $0.印刷対象 != nil }) { // 新モード // 使用資材の内、印刷対象に含まれる物を印刷
            var targets = source.filter { ($0.印刷対象 ?? $0.仮印刷対象).is封筒印刷あり }
            struct VKey: Hashable {
                let 図番: 図番型
                let 表示名: String
            }
            targets = Dictionary(grouping: targets) { VKey(図番: $0.図番, 表示名: $0.表示名) }.map { $0.value.first! } // 同種をまとめる
            vlist = targets.compactMap { 資材要求情報型(printSource: $0) }.map { .info($0) }
        } else { // 旧モード（ボルトのうち、+の入っている物を印刷）
            for index in 0...15 {
                guard var text = order.ボルト等(index+1)?.toJapaneseNormal, !text.isEmpty && !text.hasPrefix("+") else { continue }
                if let info = order.ボルト資材情報[index+1] {
                    if info.分割表示名1 == "スタッド" { continue } // スタッドは枚数に入らない
                    vlist.append(.info(info))
                } else {
                    if text.containsOne(of: "座金", "新規") {
                        if text.hasPrefix("新規") {
                            text = String(text.dropFirst(2))
                        }
                        vlist.append(.text(text))
                    }
                }
            }
        }
        // 附属品一覧印刷
        let vmap = Dictionary(grouping: vlist) { $0.title }
        let vlist2 = vmap.values.sorted { $0.first! < $1.first! }
        for index in 0...16 {
            let x: Double = index < 8 ? 0 : 55
            let y: Double = 10 + Double(index % 8) * 10
            rect3.append(PaperPath.makeBox(origin: (x: x+45, y: y-5), size: (width: 10, height: 10)))
            rect3.append(PaperPath.makeBox(origin: (x: x, y: y-5), size: (width: 45, height: 10)))
            if vlist2.indices.contains(index) {
                let list = vlist2[index]
                let vfirst = list.first!
                switch vfirst {
                case .info(let info):
                    rect3.append(PaperText(mmx: x, mmy: y-2.8, inset: inset, text: String(info.分割表示名1.prefix(14)), fontSize: 12, bold: false, color: .black))
                    rect3.append(PaperText(mmx: x, mmy: y+1.2, inset: inset, text: String(info.分割表示名2.prefix(14)), fontSize: 12, bold: false, color: .black))
                    if let vol = info.現在数量(伝票番号: order.伝票番号), vol > 0 {
                        let str = String(Int(vol))
                        let mx = x + 52.5 - Double(str.count) * 2.5
                        rect3.append(PaperText(mmx: mx, mmy: y+1.2, inset: inset, text: str, fontSize: 12, bold: false, color: .black))
                    }
                case .text(let text):
                    rect3.append(PaperText(mmx: x, mmy: y-2.8, inset: inset, text: text, fontSize: 12, bold: false, color: .black))
                }
            }
        }
        page.append(rect3)
        
        let rect4 = PaperRect(x: offsetX + 5, y: offsetY + 192, width: 110, height: 40)
        rect4.append(PaperText(mmx: 0, mmy: 0, text: "その他", fontSize: 14, bold: false, color: .black))
        // その他
        let list = [
            "ビス塗装",
            "パイプ塗装",
            "L金具塗装",
            "箱１有・箱２有",
        ]
        for index in 0...7 {
            let x: Double = (index < 4 ? 0 : 55) 
            let y: Double = 10 + Double(index % 4) * 10
            rect4.append(PaperPath.makeBox(origin: (x: x+45, y: y-5), size: (width: 10, height: 10)))
            rect4.append(PaperPath.makeBox(origin: (x: x, y: y-5), size: (width: 45, height: 10)))
            if list.indices.contains(index) {
                let text = list[index]
                if !text.isEmpty {
                    rect4.append(PaperText(mmx: x, mmy: y, inset: inset, text: text, fontSize: 14, bold: false, color: .black))
                }
            }
        }
        page.append(rect4)
        
        return page
    }
}
#endif

private enum VData: Comparable {
    case info(資材要求情報型)
    case text(String)
    
    static func==(left: VData, right: VData) -> Bool {
        switch (left, right) {
        case (.info(let linfo), .info(let rinfo)):
            return linfo.分割表示名1 == rinfo.分割表示名1 && linfo.分割表示名2 == rinfo.分割表示名2
        case (.text(let ltext), .text(let rtext)):
            return ltext == rtext
        default:
            return false
        }
        
    }
    static func<(left: VData, right: VData) -> Bool {
        switch (left, right) {
        case (.info(let linfo), .info(let rinfo)):
            return sortCompare(linfo, rinfo)
        case (.text(let ltext), .text(let rtext)):
            return ltext < rtext
        case (.info, .text):
            return true
        case (.text, .info):
            return false
        }
        
    }

    var title: String {
        switch self {
        case .info(let info):
            return info.表示名
        case .text(let title):
            return title
        }
    }
}
