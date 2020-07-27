//
//  PaperPDFPage.swift
//  DataManager
//
//  Created by manager on 2020/02/06.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

#if os(tvOS)
#else
import PDFKit

public enum PaperType {
    case A4
    case 長形3号
}

public class PaperPDFPage: PDFPage {
    let title: String

    var rects: [PaperRect] = []
    // 180°回転して印刷する場合true
    public var rotationPrint: Bool = false
    public let paperType: PaperType
    
    public let orientaion: DMPaperOrientation
    public var margin: CGFloat

    public init(paperType: PaperType = .A4, orientaion: DMPaperOrientation = .portrait, margin: CGFloat = 36, title: String = "") {
        self.paperType = paperType
        self.orientaion = orientaion
        self.margin = margin
        self.title = title
        super.init()
    }
 
    public override func bounds(for box: PDFDisplayBox) -> CGRect {
        let w, h: CGFloat
        switch paperType {
        case .A4:
            w = 595
            h = 842
        case .長形3号:
            w = 340
            h = 666
        }
        if orientaion == .landscape {
            return CGRect(x: 0, y: 0, width: h, height: w)
        } else if orientaion == .portrait {
            return CGRect(x: 0, y: 0, width: w, height: h)
        } else {
            fatalError()
        }
    }

    public func contents(for box: PDFDisplayBox) -> CGRect {
        let bounds = self.bounds(for: box)
        return bounds.insetBy(dx: margin, dy: margin)
    }

    public var isEmpty: Bool { return rects.isEmpty }
    
    public override func draw(with box: PDFDisplayBox, to context: CGContext) {
        DMGraphicsPushContext(context)
        let rect = self.bounds(for: box)
        let pos: CGPoint
        let isFlipped: Bool
        #if targetEnvironment(macCatalyst)
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: rect.height)
        context.concatenate(flipVertical)
        if rotationPrint {
            let rotation = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: rect.width, ty: rect.height)
            context.concatenate(rotation)
        }
        pos = CGPoint.zero
        isFlipped = false

        #elseif os(iOS)
        let flipVertical = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.width, ty: 0)
        context.concatenate(flipVertical)
        if rotationPrint {
            let rotation = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: rect.width, ty: rect.height)
            context.concatenate(rotation)
        }
        pos = CGPoint.zero
        isFlipped = false

        #elseif os(macOS)
        if rotationPrint {
            let rotation = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: rect.width, ty: rect.height)
            context.concatenate(rotation)
        }
        pos = CGPoint(x: 0, y: rect.height)
        isFlipped = true

        #endif
        if !title.isEmpty {
            let header = PaperRect(px: 0, py: 3, pwidth: rect.width, pheight: 5)
            let text = PaperText(mmx: 10, mmy: 10, inset: 0, text: title, fontSize: 10, bold: true, color: .black)
            header.append(text)
            header.draw(at: pos, isFlipped: isFlipped)
        }
        rects.forEach { $0.draw(at: pos, isFlipped: isFlipped) }

        DMGraphicsPopContext()
    }
    
    public func append(_ rect: PaperRect) {
        rects.append(rect)
    }
}
#endif
