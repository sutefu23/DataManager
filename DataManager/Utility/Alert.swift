//
//  Alert.swift
//  DataManager
//
//  Created by manager on 2020/04/07.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

public func showMessage(message: String, ok: String = "Ok") {
    #if os(macOS)
    let alert = NSAlert()
    alert.messageText = message
    alert.addButton(withTitle: ok)
    alert.runModal()
    #elseif os(iOS) || os(tvOS)
    let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
    let actionOk = UIAlertAction(title: ok, style: .default) { _ in  }
    alert.addAction(actionOk)
    let vc = UIApplication.shared.windows.first?.rootViewController
    vc?.present(alert, animated: true, completion: nil)
    #endif
}

public func showDialog(message: String, ok: (title: String, action: ()->()), ng: (title: String, action: ()->())) {
    #if os(macOS)
    let alert = NSAlert()
    alert.messageText = message
    alert.addButton(withTitle: ok.title)
    alert.addButton(withTitle: ng.title)
    if alert.runModal() == .alertFirstButtonReturn {
        ok.action()
    } else {
        ng.action()
    }
    #elseif os(iOS) || os(tvOS)
    let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
    let actionOk = UIAlertAction(title: ok.title, style: .default) { _ in ok.action() }
    let actionNG = UIAlertAction(title: ng.title, style: .cancel) { _ in ng.action() }
    alert.addAction(actionOk)
    alert.addAction(actionNG)
    let vc = UIApplication.shared.windows.first?.rootViewController
    vc?.present(alert, animated: true, completion: nil)
    #endif
}
