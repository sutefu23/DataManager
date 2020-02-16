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

// MARK: - JSON
extension Decodable {
    static func decodeJson(_ data: Data) -> Self? {
        let decoder = JSONDecoder()
        return try? decoder.decode(Self.self, from: data)
    }
}

extension Encodable {
    func makeJsonData() -> Data? {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        return data
    }
}

extension UserDefaults {
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
    func set(_ value: CGFloat, forKey key: String) {
        self.set(Double(value), forKey: key)
    }
    
    func cgfloat(forKey key: String) -> CGFloat {
        return CGFloat(self.double(forKey: key))
    }
}

