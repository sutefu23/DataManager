//
//  作業種別.swift
//  DataManager
//
//  Created by manager on 2019/12/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

private let nameMap: [String: 作業種別型] = {
    var map = [String: 作業種別型]()
    for type in 作業種別型.allCases {
        map[type.code] = type
        map[type.name] = type
    }
    return map
}()

public enum 作業種別型: Int, RawRepresentable, Codable, CaseIterable, Comparable {
    case 先行 = 100
    case 通常 = 200
    case 在庫 = 300
    case 手直 = 400
    case 作直 = 500
    case その他 = 900
    
    public init(_ codeOrName: String) {
        self = nameMap[codeOrName.uppercased()] ?? .通常
    }
    
    public var code: String {
        switch self {
        case .先行: return "C100"
        case .通常: return "C200"
        case .在庫: return "C300"
        case .手直: return "C400"
        case .作直: return "C500"
        case .その他:return "C900"
        }
    }
    
    public var name: String {
        switch self {
        case .先行: return "先行"
        case .通常: return "通常"
        case .在庫: return "在庫"
        case .手直: return "手直"
        case .作直: return "作直"
    case .その他:return "その他"
        }
    }
    
    public static func < (left: 作業種別型, right: 作業種別型) -> Bool {
        return left.rawValue < right.rawValue
    }
}
