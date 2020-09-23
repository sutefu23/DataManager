//
//  レーザー加工機.swift
//  DataManager
//
//  Created by 四熊泰之 on R 1/10/22.
//  Copyright © Reiwa 1 四熊泰之. All rights reserved.
//

import Foundation

public enum レーザー加工機型: Equatable, Comparable {
    public static func < (lhs: レーザー加工機型, rhs: レーザー加工機型) -> Bool {
        lhs.name < rhs.name
    }
    
    case hv
    case ex
    case hp
    case sws
    case gx
    
    public var name: String {
        switch self {
        case .ex: return "eX"
        case .gx: return "GX"
        case .hp: return "HP"
        case .sws: return "SWS"
        case .hv: return "HV"
        }
    }
}
