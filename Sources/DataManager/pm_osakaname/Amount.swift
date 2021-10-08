//
//  分量.swift
//  DataManager
//
//  Created by manager on 2020/05/28.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

public enum 分量型 {
    case 面積(Double)
    case 長さ(Double)

    public init?(_ text: String) {
        if text.hasSuffix("㎟") {
            guard let area = Double(text.dropLast()), area > 0 else { return nil }
            self = .面積(area)
        } else if text.hasSuffix("㎜") {
            guard let length = Double(text.dropLast()), length > 0 else { return nil }
            self = .長さ(length)
        } else {
            return nil
        }
    }
    
    public var text: String {
        switch self {
        case .面積(let area): return "\(area)㎟"
        case .長さ(let length): return "\(length)㎜"
        }
    }
}
