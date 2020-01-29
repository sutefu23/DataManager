//
//  Utility.swift
//  DataManager
//
//  Created by manager on 2019/12/06.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class DataManagerController {
    public func flushAllCache() {
        clear伝票番号Cache()
        flush工程名称DB()
        出勤日DB型.shared.flushCache()
        flush作業系列Cache()
    }
}

public let dataManager = DataManagerController()

#if os(macOS)
import Cocoa

extension Error {
    public func showModal() {
        let alert = NSAlert(error: self)
        alert.runModal()
    }
}

#elseif os(iOS)
import UIKit

extension Error {
    public func showModal() {
        let alert = UIAlertController(title: self.localizedDescription, message: "", preferredStyle: .alert)
        let vc = UIApplication.shared.windows.first?.rootViewController
        vc?.present(alert, animated: true, completion: nil)
    }
}

extension UITableView {
    public func convertToPDF() -> Data? {
        let priorBounds = self.bounds
        setBoundsForAllItems()
        self.layoutIfNeeded()
        let pdfData = createPDF()
        self.bounds = priorBounds
        return pdfData.copy() as? Data
    }

    private func getContentFrame() -> CGRect {
        return CGRect(x: 0, y: 0, offsetWidth: self.contentSize.offsetWidth, height: self.contentSize.height)
    }

    private func createPDF() -> NSMutableData {
        let pdfPageBounds: CGRect = getContentFrame()
        let pdfData: NSMutableData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pdfPageBounds, nil)
        UIGraphicsBeginPDFPageWithInfo(pdfPageBounds, nil)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        UIGraphicsEndPDFContext()
        return pdfData
    }

    private func setBoundsForAllItems() {
        if self.isEndOfTheScroll() {
            self.bounds = getContentFrame()
        } else {
            self.bounds = getContentFrame()
            self.reloadData()
        }
    }

    private func isEndOfTheScroll() -> Bool  {
        let contentYoffset = contentOffset.y
        let distanceFromBottom = contentSize.height - contentYoffset
        return distanceFromBottom < frame.size.height
    }
}

#endif
