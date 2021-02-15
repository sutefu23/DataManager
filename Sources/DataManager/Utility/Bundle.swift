//
//  Bundle.swift
//  NCEngine
//
//  Created by 四熊泰之 on 8/18/1 R.
//  Copyright © 1 Reiwa 四熊 泰之. All rights reserved.
//

import Foundation

public let mainBundleName: String = {
    if case let name as String = Bundle.main.infoDictionary?["CFBundleName"] {
        return name
    } else {
        return "NCEngine"
    }
}()

// MARK: - バージョン管理
public extension Bundle {
    static var dataManagerBundle: Bundle {
        #if os(Linux) || os(Windows)
        return Bundle.module
        #else
        return Bundle(for: TextReader.self)
        #endif
    }
    
    var bundleVersion: Version? { Version(self) }
//        guard let dic = self.infoDictionary else { return nil }
//        guard case let string as String = dic["CFBundleShortVersionString"], !string.isEmpty else { return nil }
//        guard case let string2 as String = dic["CFBundleVersion"], !string.isEmpty else { return nil }
//        return Version(string, string2)
}

#if os(Linux) || os(Windows)
#else
private let currentVersionCache: Version = {
    let bundle = Bundle.main
    return bundle.bundleVersion!
}()

extension DMApplication {
    public var currentVersion: Version { currentVersionCache }
    
    var newVersionBundle: Bundle? {
        guard var newVersionURL = UserDefaults.standard.newVersionURL, let isDirectory = newVersionURL.isDirectory else { return nil }
        if isDirectory {
            newVersionURL.appendPathComponent("\(defaults.programName).app")
        }
        let bundle = Bundle(url: newVersionURL)
        return bundle
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
#endif
