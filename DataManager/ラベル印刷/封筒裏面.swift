//
//  封筒裏面.swift
//  DataManager
//
//  Created by manager on 2020/08/11.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
import PDFKit

public func make封筒裏面() -> PDFDocument {
    let lx = 24.0
    let dy = 14.5
    let y1 = 5.0 + dy
    let y2 = 31.0 + dy
    let y3 = 66.5 + dy
    
    let bigdx = -1.5
    let bigHeight = 5.0
    let bigFont: CGFloat = 13.0
    let normalFont: CGFloat = 11
    let lineSpace: CGFloat = 3.0
    
    let pdf = PDFDocument()
    let page = PaperPDFPage(paperType: .長形3号, orientaion: .landscape, margin: 0, title: "")
    page.rotationPrint = true
    let rect = PaperRect(px: 10, py: 10, pwidth: 646, pheight: 320)
    let text1 = PaperText(mmx: lx+bigdx, mmy: y1, text: "【注意事項】", fontSize: bigFont, bold: false, color: .black, nooffset: true)
    let text1b = PaperText(mmx: lx, mmy: y1+bigHeight, text: """
■研磨剤・タワシ・ペーパー等、表面に傷を付ける恐れのあるものは、絶対に使用しないでください。
■溶解性(アルカリ性・酸性の洗剤など)・揮発性(シンナー・アルコールなど)の薬品は絶対に使用しないで下さい。
■塗装面(真鍮・銅・メッキ製品への透明クリアも含む)に、テープ類は貼らないで下さい。
""", fontSize: normalFont, bold: false, color: .black, nooffset: true, lineSpace: lineSpace)

    let text2 = PaperText(mmx: lx+bigdx, mmy: y2, text: "【お手入れ方法】", fontSize: bigFont, bold: false, color: .black, nooffset: true)
    let text2b = PaperText(mmx: lx, mmy: y2+bigHeight, text: """
■まずは、製品に付着したチリや埃をやわらかい布で落とした後、水を含ませた布で、
　やさしくなでる様に表面の目に沿って拭いて下さい。
　その後は、必ず柔らかい布などを使用し、同じ要領で乾拭きを行って下さい。
■浮かして取り付けてある商品は、強い力を加えないように作業を行ってください。
■製品によっては鋭利な部分があるので、お手入れの際は十分にお気をつけください。
""", fontSize: normalFont, bold: false, color: .black, nooffset: true, lineSpace: lineSpace)

    let text3 = PaperText(mmx: lx+bigdx, mmy: y3, text: "【錆や変色の主な原因】", fontSize: bigFont, bold: false, color: .black, nooffset: true)
    let text3b = PaperText(mmx: lx, mmy: y3+bigHeight, text: """
■ステンレス製品は錆びにくい素材であり、決して錆びない素材ではありません。
　工場現場や線路のそばなど、飛んできた鉄粉や粉塵の付着によって、もらい錆を受けます。
■銅・真鍮製品は必ず変色する素材です。弊社では変色を遅らせる為に透明クリア塗装を施しております。
　しかし、特に屋外で使用される場合においては、短期間で変色する場合があります。
""", fontSize: normalFont, bold: false, color: .black, nooffset: true, lineSpace: lineSpace)
    
    rect.append(text1)
    rect.append(text1b)
    rect.append(text2)
    rect.append(text2b)
    rect.append(text3)
    rect.append(text3b)

    page.append(rect)
    pdf.insert(page, at: 0)
    return pdf
}
