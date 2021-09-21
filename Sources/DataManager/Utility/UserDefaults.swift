//
//  UserDefaults.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/09/09.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

// MARK: - 標準データ。デフォルトは空
extension UserDefaults {
    public var programName: String { string(forKey: "programName") ?? mainBundleName }
    
    public var newVersionURL: URL? {
        get { url(forKey: "newVersionURL") }
        set { set(newValue, forKey: "newVersionURL") }
    }
    public var newVersionDirectoryURL: URL? {
        guard let url = self.newVersionURL, let isDirectory = url.isDirectory else { return nil }
        return isDirectory ? url : url.deletingLastPathComponent()
    }
    
    public static var dataManagerDefaultValues: [String: Any] {
        dataManagerDefaultValuesRegistered = true
        return [
            "programName": mainBundleName,
            "maxCacheRate": 40,
        ]
    }
    /// キャッシュに使用できるメモリの全メモリに対する割合(%)）
    public var maxCacheRate: Int {
        get {
            let rate = integer(forKey: "maxCacheRate")
            if rate < 0 { return 0 }
            if rate > 100 { return 100 }
            return rate
        }
        set {
            set(newValue, forKey: "maxCacheRate")
            DMCacheSystem.shared.maxBytes = DMCacheSystem.calcMaxCacheBytes(for: newValue)
        }
    }
    /// 起動時にNAS自動接続
    public var launchAutoMountNAS: Bool {
        get { self.bool(forKey: "launchAutoMountNAS") }
        set { self.set(newValue, forKey: "launchAutoMountNAS") }
    }
    
    public var nas4User: NAS4User? {
        get { NAS4User(rawValue: self.nasUserTag) }
        set {
            if let tag = newValue?.rawValue {
                self.nasUserTag = tag
            } else {
                self.removeObject(forKey: "nasUserTag")
            }            
        }
    }
    public var nasUserTag: Int {
        get { return self.integer(forKey: "nasUserTag") }
        set { self.set(newValue, forKey: "nasUserTag") }
    }
    
    public var nasType: NFSType {
        get {
            guard let typestr = self.string(forKey: "nasType") else { return .smb }
            return NFSType(rawValue: typestr) ?? .smb
        }
        set {
            self.set(newValue.rawValue, forKey: "nasType")
        }
    }
    
    public var nasTypeCode: NASTypeCode {
        get { NASTypeCode(self.nasType) }
        set { self.nasType = NFSType(newValue) }
    }
}

let defaults: UserDefaults = {
    let defaults = UserDefaults.standard
    if !dataManagerDefaultValuesRegistered {
        defaults.register(defaults: UserDefaults.dataManagerDefaultValues)
    }
    return defaults
}()

var dataManagerDefaultValuesRegistered: Bool = false
