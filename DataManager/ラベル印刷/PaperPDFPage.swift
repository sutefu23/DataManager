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

public class PaperPDFPage: PDFPage {
    var rects: [PaperRect] = []
    
    public let orientaion: DMPaperOrientation
    public var margin: CGFloat

    public init(orientaion: DMPaperOrientation = .portrait, margin: CGFloat = 36) {
        self.orientaion = orientaion
        self.margin = margin
        super.init()
    }
 
    public override func bounds(for box: PDFDisplayBox) -> CGRect {
        if orientaion == .landscape {
            return CGRect(x: 0, y: 0, width: 842, height: 595)
        }
        if orientaion == .portrait {
            return CGRect(x: 0, y: 0, width: 592, height: 842)
        }
        fatalError()
    }
    public func contents(for box: PDFDisplayBox) -> CGRect {
        let bounds = self.bounds(for: box)
        return bounds.insetBy(dx: margin, dy: margin)
    }

    public override func draw(with box: PDFDisplayBox, to context: CGContext) {
        DMGraphicsPushContext(context)
        rects.forEach { $0.draw(at: CGPoint.zero) }
        DMGraphicsPopContext()
    }
    
    public func append(_ rect: PaperRect) {
        rects.append(rect)
    }

}
#endif
