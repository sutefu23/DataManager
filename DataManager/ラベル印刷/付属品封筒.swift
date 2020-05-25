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

class 付属品封筒型 {
    private let order: 指示書型
    
    init(_ order: 指示書型) {
        self.order = order
    }
    
    func makePDF() -> PDFDocument {
        let doc = PDFDocument()
        let page = PaperPDFPage()
        // 伝票番~
        let rect1 = PaperRect(x: 5, y: 5, width: 110, height: 25)
        rect1.append(PaperText(mmx: 0, mmy: 0, text: "伝票No \(order.伝票番号.表示用文字列)", fontSize: 14, bold: false, color: .black))
        rect1.append(PaperText(mmx: 75, mmy: 15, text: "出荷：\(order.出荷納期.monthDayJString)", fontSize: 14, bold: false, color: .black))
        rect1.append(PaperText(mmx: 0, mmy: 25, text: "社名：\(order.社名)", fontSize: 14, bold: false, color: .black))
        rect1.append(PaperText(mmx: 75, mmy: 25, text: "\(order.セット数) セット", fontSize: 14, bold: false, color: .black))
        
        page.append(rect1)
        // 図
        if let image = order.図 {
            let rect2 = PaperRect(x: 5, y: 35, width: 110, height: 25)
            rect2.append(PaperImage(mx: 0, my: 0, mwidth: 110, mheight: 55, image: image))
            page.append(rect2)
        }
        // ボルト
        func pos(_ index: Int) -> (x: Double, y: Double) {
            let x: Double = index <= 7 ? 5 : 5+55
            let y: Double = 95 + Double(index % 8) * 10
            return (x, y)
        }
        
        let rect3 = PaperRect(x: 5, y: 95, width: 110, height: 25)
        page.append(rect3)
        
        // その他
        let rect4 = PaperRect(x: 5, y: 190, width: 110, height: 40)
        page.append(rect4)
        
        doc.insert(page, at: 0)
        return doc
    }
}
#endif
