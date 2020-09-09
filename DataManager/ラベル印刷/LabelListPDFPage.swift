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

public protocol LabelMaker {
    func makeLabel() -> PaperRect?
}

public final class LabelPDFDocument {
    let orientaion: DMPrintInfo.PaperOrientation
    var margin: CGFloat
    let title: String

    // 横に並ぶラベルの個数
    let xCount: Int
    // 縦に並ぶラベルの個数
    let yCount: Int
    
    let originX: Double
    let originY: Double
    let labelWidth: Double
    let labelHeight: Double

    public var skipCount: Int
    
    public init(title: String, originX: Double, originY: Double, labelWidth: Double, labelHeight: Double, xCount: Int, yCount: Int, orientaion: DMPrintInfo.PaperOrientation, margin: CGFloat = 36) {
        self.originX = originX
        self.originY = originY
        self.labelWidth = labelWidth
        self.labelHeight = labelHeight
        self.xCount = xCount
        self.yCount = yCount
        self.orientaion = orientaion
        self.margin = margin
        self.skipCount = 0
        self.title = title
    }
    
    @available(iOS 11, *)
    public func makePDF<C: Collection>(labels: C) -> PDFDocument? where C.Element: LabelMaker {
        if labels.isEmpty { return nil }
        let pdf = PDFDocument()
        var page = PaperPDFPage(title: title)
        var count = skipCount
        var index = 0
        for label in labels {
            guard let rect = label.makeLabel() else { continue }
            var row = count/xCount
            let col = count%xCount
            if row >= yCount {
                if !page.isEmpty {
                    pdf.insert(page, at: index)
                    index += 1
                    page = PaperPDFPage()
                }
                count = 0
                row = 0
            }
            rect.moveTo(x: originX + Double(col) * labelWidth, y: originY + Double(row)*labelHeight)
            page.append(rect)
            count += 1
        }
        if !page.isEmpty { pdf.insert(page, at: index) }
        if count == xCount * yCount { count = 0 }
        skipCount = count
        return pdf
    }
}

#endif

#if os(iOS)
import UIKit

@available(iOS 11, *)
extension UIViewController {
    public func print(_ pdf: PDFDocument, updateButton: UIButton, jobName: String, outputType: UIPrintInfo.OutputType, delegate: UIPrintInteractionControllerDelegate? = nil) {
        let picker = UIPrinterPickerController(initiallySelectedPrinter: nil)
        picker.present(from: updateButton.frame, in: self.view, animated: true) { (picker, userDidSelect, error) in
            guard error  == nil && userDidSelect == true else { return }
            guard let printer = picker.selectedPrinter else { return }
            self.print(printer: printer, doc: pdf, jobName: jobName, outputType: outputType, delegate: delegate)
        }
    }
    
    func print(printer: UIPrinter, doc: PDFDocument, jobName: String = "PDF印刷", outputType: UIPrintInfo.OutputType, delegate: UIPrintInteractionControllerDelegate? = nil) {
        guard let pdfData = doc.dataRepresentation() else { return }
        let printIntaractionController = UIPrintInteractionController.shared
        let noCutInfo = UIPrintInfo(dictionary: nil)
        noCutInfo.jobName = jobName
        noCutInfo.orientation = .portrait
        noCutInfo.duplex = .none
        noCutInfo.outputType = outputType
        printIntaractionController.printInfo = noCutInfo
        printIntaractionController.printingItem = pdfData
        printIntaractionController.delegate = delegate
        printIntaractionController.print(to: printer)
    }
}
#endif

#if os(macOS)
extension PDFDocument {
    /// PDFDocumentを印刷する
    public func print(info: NSPrintInfo = NSPrintInfo()) {
        let info = NSPrintInfo()
        let view = PDFView()
        let window = NSWindow()
        window.setContentSize(view.frame.size)
        window.contentView = view
        view.document = self
        view.print(with: info, autoRotate: true, pageScaling: .pageScaleNone)
    }
}
#endif
