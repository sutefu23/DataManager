//
//  指定注文番号型.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 指定注文番号型: Codable, Hashable {
    let text: String
    public var テキスト: String { return text }
    public var 注文番号: 注文番号型? {
        guard let code = text.first?.uppercased() else { return nil }
        return 注文番号キャッシュ型.shared[code]
    }
    
    init?(_ string: String) {
        self.text = string
    }
    
    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
    }
    public static func == (left: 指定注文番号型, right: 指定注文番号型) -> Bool {
        return left.text == right.text
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case text
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try values.decode(String.self, forKey: .text)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.text, forKey: .text)
    }
}

extension FileMakerRecord {
    func 指定注文番号(forKey key: String) -> 指定注文番号型? {
        guard let string = self.string(forKey: key) else { return nil }
        return 指定注文番号型(string)
    }
    
}
