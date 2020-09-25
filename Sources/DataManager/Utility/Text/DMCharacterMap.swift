//
//  DMCharacterMap.swift
//  DataManager
//
//  Created by manager on 2020/09/25.
//

import Foundation

/// 文字変換の集合
struct DMCharacterMap {
    private var map: [Character: Character]
    
    mutating func apply(transform: DMCharacterTransform) {
        map[transform.source] = transform.result
    }
    
    func transform(_ string: String) -> String {
        var result: String = ""
        string.forEach { result.append(map[$0] ?? $0) }
        return result
    }
}

/// 1文字変換
public struct DMCharacterTransform: Codable {
    /// 変換前の文字
    public let source: Character
    /// 変換後の文字
    public let result: Character
    
    enum CodingKeys: String, CodingKey {
        case source
        case result
    }
    
    public init(source: Character, result: Character) {
        self.source = source
        self.result = result
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.source = try values.decode(String.self, forKey: .source).first!
        self.result = try values.decode(String.self, forKey: .result).first!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(String(self.source), forKey: .source)
        try container.encode(String(self.result), forKey: .result)
    }
}

