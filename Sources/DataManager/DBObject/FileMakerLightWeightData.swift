//
//  FileMakerLightWeightData.swift
//  DataManager
//
//  Created by manager on 2021/10/05.
//

import Foundation

protocol FileMakerLightWeightData: DMLightWeightObjectProtocol, DMCacheElement {
    /// キャッシュされているデータ
    var cachedData: [String] { get }
}

extension FileMakerLightWeightData {
    public var memoryFootPrint: Int { cachedData.reduce(0) { $0 + $1.memoryFootPrint }}
    var description: String { cachedData.joined(separator: ",") }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cachedData)
    }
    
    public static func == (left: Self, right: Self) -> Bool {
        return left.cachedData == right.cachedData
    }
}
