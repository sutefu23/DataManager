//
//  Utility.swift
//  DataManager
//
//  Created by manager on 2019/12/06.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public final class DataManagerController {
    public static let shared: DataManagerController = DataManagerController()

    public let serialQueue: OperationQueue

    private init() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        self.serialQueue = queue
    }
    
    public func flushAllCache() {
        flush工程名称DB()
        出勤日DB型.shared.flushCache()
        DMCacheSystem.shared.removeAllCache()
    }
    
    public func prepareSleep() {
        serialQueue.waitUntilAllOperationsAreFinished()
    }
}

/// objectの型を文字列として意味のある部分を返す（名前に使う）
func classNameBody(of object: Any) -> String {
    var name = String(describing: type(of: object))
    if name.hasSuffix(".Type") { name.removeLast(5) } // メタタイプはタイプ扱いとする
    if name.hasSuffix("型") { name.removeLast() } // ~型の末尾は不要
    return name
}

#if os(iOS) || os(tvOS)
import UIKit

extension Error {
    public func showAlert() {
        currentLogSystem.errorDump()
        let message = self.localizedDescription
        showMessage(message: message)
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
        currentLogSystem.errorDump()
        let alert = NSAlert(error: self)
        alert.runModal()
    }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS)
extension Error {
    public func asyncShowAlert() {
        DispatchQueue.main.async {
            currentLogSystem.errorDump()
            self.showAlert()
        }
    }
}
#endif
