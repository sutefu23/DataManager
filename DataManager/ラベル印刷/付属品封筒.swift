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
        let setCount = order.セット数値
        // 伝票番~
        let rect0 = PaperRect(x: offsetX + 5, y: offsetY + 7, width: 110, height: 15)
//        rect0.append(PaperPath.makeBox(origin: (x: 15, y: 9), size: (width: 80, height: 13)))
        rect0.append(PaperRoundBox(origin: (x: 15, y: 9), size: (width: 80, height: 13), r: 3))
        rect0.append(PaperText(mmx: 26, mmy: 15, inset: inset, text: "取付附属品表", fontSize: 28, bold: false, color: .black))
        page.append(rect0)
        let rect1 = PaperRect(x: offsetX + 5, y: offsetY + 20, width: 110, height: 25)
        rect1.append(PaperText(mmx: 0, mmy: 15, text: "伝票No \(order.伝票番号.表示用文字列)", fontSize: 14, bold: false, color: .black))
        rect1.append(PaperText(mmx: 75, mmy: 15, text: "出荷 \(order.出荷納期.monthDayJString)", fontSize: 14, bold: false, color: .black))
        if order.取引先?.is原稿社名不要 != true {
            rect1.append(PaperText(mmx: 0, mmy: 25, text: "社名　\(order.社名)　様", fontSize: 14, bold: false, color: .black))
        }
        
        page.append(rect1)
        let rect2 = PaperRect(x: offsetX + 5, y: offsetY + 50, width: 110, height: 25)
        rect2.append(PaperText(mmx: 0, mmy: 4, inset: inset, text: "品名 \(order.品名)", fontSize: 18, bold: false, color: .black))
        rect2.append(PaperText(mmx: 0, mmy: 14, inset: inset, text: "取付に必要な部品が入っています", fontSize: 14, bold: false, color: .black))
        rect2.append(PaperText(mmx: 0, mmy: 21, inset: inset, text: "開封の上、ご確認ください", fontSize: 14, bold: false, color: .black))

        let setinfo = (order.セット数値 > 0) ? String(order.セット数値) : order.セット数
        rect2.append(PaperText(mmx: 5, mmy: 30, inset: inset, text: "原稿　　\(setinfo)　セット", fontSize: 14, bold: false, color: .black))
        rect2.append(PaperText(mmx: 5, mmy: 40, inset: inset, text: "補修材 　　　　個", fontSize: 14, bold: false, color: .black))
//        rect2.append(PaperPath.makeBox(origin: (x: 0.5, y: 29.15), size: (width: 4, height: 4)))
        rect2.append(PaperPath.makeBox(origin: (x: 0.5, y: 39.15), size: (width: 4, height: 4)))

        page.append(rect2)
            // ボルト
        let rect3 = PaperRect(x: offsetX + 5, y: offsetY + 100, width: 110, height: 80)
        rect3.append(PaperText(mmx: 0, mmy: 0, text: "付属品", fontSize: 14, bold: false, color: .black))

        var vlist: [VData] = []
        for index in 0...15 {
            guard let text = order.ボルト等(index+1), let count = order.ボルト本数(index+1), !text.isEmpty && !count.isEmpty else { continue }
            if let info = 資材要求情報型(ボルト欄: text, 数量欄: count, セット数: setCount), info.is附属品 == true {
                vlist.append(.info(info))
            } else {
                vlist.append(.text(text))
            }
        }
        vlist.sort()
        for index in 0...16 {
            let x: Double = index < 8 ? 0 : 55
            let y: Double = 10 + Double(index % 8) * 10
            rect3.append(PaperPath.makeBox(origin: (x: x, y: y-5), size: (width: 10, height: 10)))
            rect3.append(PaperPath.makeBox(origin: (x: x+10, y: y-5), size: (width: 45, height: 10)))
            if vlist.indices.contains(index) {
                switch vlist[index] {
                case .info(let info):
                    rect3.append(PaperText(mmx: x+10, mmy: y-2.8, inset: inset, text: info.分割表示名1, fontSize: 12, bold: false, color: .black))
                    rect3.append(PaperText(mmx: x+10, mmy: y+1.2, inset: inset, text: info.分割表示名2, fontSize: 12, bold: false, color: .black))
                case .text(let text):
                    rect3.append(PaperText(mmx: x+10, mmy: y-2.8, inset: inset, text: text, fontSize: 12, bold: false, color: .black))
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
            let x: Double = index < 4 ? 0 : 55
            let y: Double = 10 + Double(index % 4) * 10
            rect4.append(PaperPath.makeBox(origin: (x: x, y: y-5), size: (width: 10, height: 10)))
            rect4.append(PaperPath.makeBox(origin: (x: x+10, y: y-5), size: (width: 45, height: 10)))
            if list.indices.contains(index) {
                let text = list[index]
                if !text.isEmpty {
                    rect4.append(PaperText(mmx: x+10, mmy: y, inset: inset, text: text, fontSize: 14, bold: false, color: .black))
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

}
