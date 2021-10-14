//
//  Enum.swift
//  DataManager
//
//  Created by manager on 2021/10/12.
//

import Foundation

public protocol DMStringEnum: CaseIterable, CustomStringConvertible {
    static var stringMap: [String: Self] { get }
    
    init?(_ text: String?)
}

extension DMStringEnum {
    public static func makeStringMap() -> [String: Self] {
        var map: [String: Self] = [:]
        for data in allCases {
            map[data.description] = data
        }
        return map
    }
    
    public init?(_ text: String?) {
        guard let text = text, let data = Self.stringMap[text] else { return nil }
        self = data
    }
}
