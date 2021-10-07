//
//  FileMakerRecordCache.swift
//  DataManager
//
//  Created by manager on 2021/10/05.
//

import Foundation

protocol FileMakerRecordCacheData: DMLightWeightObjectProtocol {
    static var cache: FileMakerRecordCache<Self> { get }
    static var empty: Self { get }
    
    var cachedData: [String] { get }
    var isRegistered: DMCacheState { get set }
    
    init(_ record: FileMakerRecord)
}

extension FileMakerRecordCacheData {
    static func find(_ record: FileMakerRecord) -> Self {
        return cache.find(record)
    }
    init() { self.init(FileMakerRecord()) }
    
    public var memoryFootPrint: Int { cachedData.reduce(0) { $0 + $1.memoryFootPrint }}
    public var description: String { cachedData.joined(separator: ",") }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cachedData)
    }
    
    public static func == (left: Self, right: Self) -> Bool {
        return left.cachedData == right.cachedData
    }
    func cleanUp() {
        Self.cache.asyncCleanUp(of: self)
    }
    
    var isAllEmpty: Bool { return cachedData.allSatisfy { $0.isEmpty } }
}

class FileMakerRecordCache<Data: FileMakerRecordCacheData>: LightWeightStorage<Data> {
    func find(_ record: FileMakerRecord) -> Data {
        let data = Data(record)
        return data.isAllEmpty ? Data.empty : self.regist(data)
    }
}
