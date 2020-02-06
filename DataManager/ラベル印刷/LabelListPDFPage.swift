//
//  LabelListPDFPage.swift
//  DataManager
//
//  Created by manager on 2020/02/06.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
import PDFKit

public class LabelListPDFPage: PaperPDFPage {
    var top: Double { convert(point: self.contents(for: .mediaBox).minY) }
    var bottom: Double { convert(point: self.contents(for: .mediaBox).maxY) }
    
    var frontLine: Double { self.rects.map { $0.maxY }.max() ?? self.top }

    @discardableResult
    public func append(margin: Double, rect: PaperRect) -> Bool {
        var front  = self.frontLine
        let bottom = self.bottom
        if (bottom - front) < (margin + rect.height) { return false }
        front += bottom
        rect.y = front
        super.append(rect)
        return true
    }
    
    public override func append(_ rect: PaperRect) {
        self.append(margin: 0, rect: rect)
    }
}
