//
//  UserDefaults.swift
//  DataManager
//
//  Created by manager on 2020/02/14.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
#if os(tvOS) || os(iOS)
import UIKit
#endif

// MARK: - 標準データ。デフォルトは空

extension UserDefaults {
    public var programName: String { mainBundleName }

    public var newVersionURL: URL? {
        get { url(forKey: "newVersionURL") }
        set { set(newValue, forKey: "newVersionURL") }
    }
}

// MARK: - JSON
public extension Decodable {
    static func decodeJson(_ data: Data) -> Self? {
        let decoder = JSONDecoder()
        return try? decoder.decode(Self.self, from: data)
    }
}

public extension Encodable {
    func makeJsonData() -> Data? {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        return data
    }
}

public extension UserDefaults {
    // MARK: - JSON
    func json<T>(forKey key: String) -> T? where T: Codable {
        guard let data = self.object(forKey: key) as? Data else { return nil }
        return T.decodeJson(data)
    }
    func setJson<T>(object: T?, forKey key: String) where T: Codable {
        if let data = object?.makeJsonData() {
            self.set(data, forKey: key)
        } else {
            self.removeObject(forKey: key)
        }
    }
    // MARK: - CGFloat
    func set(_ value: CGFloat, forKey key: String) {
        self.set(Double(value), forKey: key)
    }
    
    func cgfloat(forKey key: String) -> CGFloat {
        return CGFloat(self.double(forKey: key))
    }
    
    // MARK: - nil拡張
    func nullable<T>(forKey key: String) -> T? {
        return self.object(forKey: key) as? T
    }
    func optionalDouble(forKey key: String) -> Double? {
        if self.object(forKey: key) == nil {
            return nil
        }
        return self.double(forKey: key)
    }
    func optionalInteger(forKey key: String) -> Int? {
        if self.object(forKey: key) == nil {
            return nil
        }
        return self.integer(forKey: key)
    }

    func setOptional(_ value: Double?, forKey key: String) {
        if let value = value {
            self.set(value, forKey: key)
        } else {
            self.set(nil, forKey: key)
        }
    }
    
    func setOptional(_ value: Int?, forKey key: String) {
        if let value = value {
            self.set(value, forKey: key)
        } else {
            self.set(nil, forKey: key)
        }
    }
}

