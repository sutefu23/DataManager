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
    
    public static let dataManagerDefaultValues: [String: Any] = [
        "programName": mainBundleName
    ]
}

let defaults: UserDefaults = {
    let defaults = UserDefaults.standard
    defaults.register(defaults: UserDefaults.dataManagerDefaultValues)
    return defaults
}()
