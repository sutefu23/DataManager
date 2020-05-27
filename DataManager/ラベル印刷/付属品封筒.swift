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
        let page = PaperPDFPage(paperType: .envelope, margin: 0)
        page.rotationPrint = true
        let inset = 1.0
        // 伝票番~
        let rect1 = PaperRect(x: offsetX + 5, y: offsetY + 5, width: 110, height: 25)
        rect1.append(PaperText(mmx: 0, mmy: 15, text: "伝票No \(order.伝票番号.表示用文字列)", fontSize: 14, bold: false, color: .black))
        rect1.append(PaperText(mmx: 75, mmy: 15, text: "出荷：\(order.出荷納期.monthDayJString)", fontSize: 14, bold: false, color: .black))
        rect1.append(PaperText(mmx: 0, mmy: 25, text: "社名：\(order.社名)", fontSize: 14, bold: false, color: .black))
        rect1.append(PaperText(mmx: 75, mmy: 25, text: "\(order.セット数) セット", fontSize: 14, bold: false, color: .black))
        
        page.append(rect1)
        // 図
//        if let image = order.図 {
//            let rect2 = PaperRect(x: offsetX + 5, y: offsetY + 35, width: 110, height: 25)
//            rect2.append(PaperImage(mx: 0, my: 0, mwidth: 110, mheight: 55, image: image))
//            rect2.append(PaperPath.makeBox(origin: (x: 0, y: 0), size: (width: 110, height: 55)))
//            page.append(rect2)
//        }
        // 社名
        let rect2 = PaperRect(x: offsetX + 5, y: offsetY + 35, width: 110, height: 25)
        rect2.append(PaperText(mmx: 0, mmy: 15, inset: inset, text: "品名 \(order.品名)", fontSize: 16, bold: false, color: .black))
        page.append(rect2)
            // ボルト
        let rect3 = PaperRect(x: offsetX + 5, y: offsetY + 95, width: 110, height: 80)
        rect3.append(PaperText(mmx: 0, mmy: 0, text: "付属品", fontSize: 14, bold: false, color: .black))
        for index in 0...16 {
            let x: Double = index < 8 ? 0 : 55
            let y: Double = 10 + Double(index % 8) * 10
            rect3.append(PaperPath.makeBox(origin: (x: x, y: y-5), size: (width: 10, height: 10)))
            rect3.append(PaperPath.makeBox(origin: (x: x+10, y: y-5), size: (width: 45, height: 10)))
            guard let text = order.ボルト等(index+1), let count = order.ボルト本数(index+1), let info = 資材使用情報型(ボルト欄: text, 数量欄: count) else { continue }
            rect3.append(PaperText(mmx: x+10, mmy: y, inset: inset, text: info.内容表示, fontSize: 14, bold: false, color: .black))
        }
        page.append(rect3)
        
        let rect4 = PaperRect(x: offsetX + 5, y: offsetY + 190, width: 110, height: 40)
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
