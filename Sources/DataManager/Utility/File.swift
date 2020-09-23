//
//  File.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/05/05.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

/// DataManager汎用エラー
public enum DataManagerError: LocalizedError, Equatable {
    /// 内部ロジックエラー
    case internalError(reason: String)
    /// データが数値でない
    case needsNumberString
    /// データを指定したエンコードで文字列かできない
    case invalidStringCoding
    /// bundleから読み込みできない
    case invalidBundle
    /// 保存先の指定が不正
    case invalidWriteURL
    
    public var errorDescription: String? {
        switch self {
        case .internalError(let reason):return "内部ロジックエラー(\(reason))"
        case .needsNumberString:        return "データが数値でない"
        case .invalidStringCoding:      return "データを指定したエンコードで文字列化できない"
        case .invalidBundle:            return "bundleから読み込みできない"
        case .invalidWriteURL:          return "保存先の指定が不正"
        }
    }
}

#if os(iOS)
import UIKit

class PikerDelegate: NSObject, UIDocumentPickerDelegate {
    var files: [FileWrapper] = []
    var handler: ([FileWrapper]) -> Void
    init(_ handler: @escaping ([FileWrapper]) -> Void) {
        self.handler = handler
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let files = urls.compactMap { try? FileWrapper(url: $0)}
        handler(files)
    }
}

private var pickerDelegate: PikerDelegate?
public extension UIViewController {
    func selectExportFile(filename: String, data: Data) {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        do {
            try data.write(to: url)
            let documentPicker = UIDocumentPickerViewController(url: url, in: .exportToService)
            self.present(documentPicker, animated: true)
        } catch {
            error.showAlert()
        }
    }
    
    func selectImportFile(_ handler: @escaping ([FileWrapper]) -> Void) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String("public.content")], in: .import)
        let delegate = PikerDelegate(handler)
        pickerDelegate = delegate
        documentPicker.delegate = delegate
        present(documentPicker, animated: true)
    }
}
#endif
