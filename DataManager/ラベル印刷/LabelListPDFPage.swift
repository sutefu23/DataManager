//
//  LabelListPDFPage.swift
//  DataManager
//
//  Created by manager on 2020/02/06.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
#if os(tvOS)
#else
import PDFKit

public class LabelListPDFPage: PaperPDFPage {
    var top: CGFloat { self.contents(for: .mediaBox).minY }
    var bottom: CGFloat { self.contents(for: .mediaBox).maxY }
    
    var frontLine: CGFloat { self.rects.map(\.pmaxY).max() ?? self.top }
    public internal(set) var count: Int = 0
    
    @discardableResult
    public func append(margin: CGFloat, rect: PaperRect) -> Bool {
        let front  = self.frontLine
        let bottom = self.bottom
        let height = margin + rect.pheight
        if (bottom - front) < height { return false }
        rect.py = front
        super.append(rect)
        self.count += 1
        return true
    }
    
    public override func append(_ rect: PaperRect) {
        self.append(margin: 0, rect: rect)
    }
}
#endif
