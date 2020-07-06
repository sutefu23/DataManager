//
//  Bundle.swift
//  NCEngine
//
//  Created by 四熊泰之 on 8/18/1 R.
//  Copyright © 1 Reiwa 四熊 泰之. All rights reserved.
//

import Foundation

public let mainBundleName: String = {
    if let name = Bundle.main.infoDictionary?["CFBundleName"] as? String {
        return name
    } else {
        return "NCEngine"
    }
}()

// MARK: - バージョン管理
public extension Bundle {
    var bundleVersion: Version? {
        guard let dic = self.infoDictionary else { return nil }
        guard let string = dic["CFBundleShortVersionString"] as? String, !string.isEmpty else { return nil }
        guard let string2 = dic["CFBundleVersion"] as? String, !string.isEmpty else { return nil }
        return Version(string, string2)
    }
    
    var bundleIdentifier: String? {
        guard let dic = self.infoDictionary else { return nil }
        return dic["CFBundleIdentifier"] as? String
    }
}

extension DMApplication {
    public var currentVersion: Version {
        let bundle = Bundle.main
        return bundle.bundleVersion!
    }
    
    var newVersionBundle: Bundle? {
        guard let newVersionURL = UserDefaults.standard.newVersionURL else { return nil }
        return Bundle(url: newVersionURL)
    }

    public var bundleIdentifier: String {
        let bundle = Bundle.main
        return bundle.bundleIdentifier!
    }
    
    public var newVersion: Version  {
        return newVersionBundle?.bundleVersion ?? self.currentVersion
    }
    
    public var changeLogToNewVersion: [String] {
        guard let bundle = newVersionBundle, let history = History(bundle) else { return [] }
        return history.changeLog(from: currentVersion)
    }
    
    public var history: [(version: Version, changeList:[String])] {
        guard let bundle = newVersionBundle, let history = History(bundle) else { return [] }
        return history.history.map { ($0.0, $0.1) }
    }
    
    public var historyToNewVersion: [(version:String, changeList:[String])] {
        guard let bundle = newVersionBundle, let history = History(bundle) else { return [] }
        return history.history(greaterFrom: currentVersion)
    }

    public var historyFromCurrentVersion: [(version:String, changeList:[String])] {
        guard let bundle = newVersionBundle, let history = History(bundle) else { return [] }
        return history.history(from: currentVersion)
    }
}
