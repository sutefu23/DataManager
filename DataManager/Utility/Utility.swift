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
        最終発注単価キャッシュ型.shared.flushCache()
        資材キャッシュ型.shared.flushCache()
        箱文字優先度キャッシュ型.shared.removeAll()
        在庫数キャッシュ型.shared.flushAllCache()
        入出庫キャッシュ型.shared.flushAllCache()
        資材発注キャッシュ型.shared.flushAllCache()
        取引先キャッシュ型.shared.flushAllCache()
        指示書進捗キャッシュ型.shared.flushAllCache()
    }
}

public let dataManager = DataManagerController()

#if os(iOS)
import UIKit

extension Error {
    public func showAlert() {
        let alert = UIAlertController(title: self.localizedDescription, message: "", preferredStyle: .alert)
        let vc = UIApplication.shared.windows.first?.rootViewController
        vc?.present(alert, animated: true, completion: nil)
    }
}

extension UIViewController {
    public func showMessageDialog(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "ok", style: .default, handler: nil)
        alert.addAction(action1)
        self.present(alert, animated: true)
        return
    }
    
    public func showSelectDialog(title: String, message: String, ok: String, cancel: String) -> Bool {
        var isOk: Bool = true
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: ok, style: .default, handler: { _ in isOk = true })
        let action2 = UIAlertAction(title: cancel, style: .default, handler: { _ in isOk = false })
        alert.addAction(action1)
        alert.addAction(action2)
        self.present(alert, animated: true)
        return isOk
    }
}

extension UITableView {
    public func convertToPDF() -> ProgressTVData? {
        let priorBounds = self.bounds
        setBoundsForAllItems()
        self.layoutIfNeeded()
        let pdfData = createPDF()
        self.bounds = priorBounds
        return pdfData.copy() as? ProgressTVData
    }

    private func getContentFrame() -> CGRect {
        return CGRect(x: 0, y: 0, width: self.contentSize.width, height: self.contentSize.height)
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

#elseif os(macOS)
import Cocoa

extension Error {
    public func showAlert() {
        let alert = NSAlert(error: self)
        alert.runModal()
    }
}


#endif
