//
//  指定注文番号型.swift
//  DataManager
//
//  Created by manager on 2020/03/24.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public struct 指定注文番号型: Codable, Hashable {
    private let text: String
    public var テキスト: String { return text }
    public var 注文番号: 注文番号型? {
        guard let code = text.first?.uppercased() else { return nil }
        return 注文番号キャッシュ型.shared[code]
    }

    init(text: String) {
        self.text = text
    }
    
    public init?(_ string: String) {
        var scanner = DMScanner(string, normalizedFullHalf: true, upperCased: true)
        let result = scanner.string
        guard let ch1 = scanner.scan1Character(), ch1.isASCIIAlphabet else { return nil }
        guard let ch2 = scanner.scan1Character(), ch2.isASCIINumber else { return nil }
        guard let ch3 = scanner.scan1Character(), ch3.isASCIINumber else { return nil }
        guard scanner.scanCharacter("-") else { return nil }
        let rest = scanner.string
        guard rest.count == 6, let num = Int(rest), num > 0 else { return nil }
        self.text = result
    }
    
    init?(_ string: String, day: Day) {
        let string = string.uppercased()
        let digs = string.split(separator: "-")
        guard digs.count == 2 && !digs[0].isEmpty && digs[1].count == 6 else { return nil }
        var head = String(digs[0])
        if head.count == 1 {
            let mstr = digs[1].prefix(2)
            guard let month = Int(mstr) else { return nil }
            let year = day.year % 100
            head += String(format: "%2d", day.month <= month ? year : year-1)
            self.text = "\(head)-\(digs[1])"
        } else {
            self.text = string
        }
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
