//
//  ActionLine.swift
//  DataManager
//
//  Created by manager on 2021/05/06.
//

import Foundation

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

// MARK: - 作業
/// 作業
struct WorkData: Equatable {
    static let dbName = "DataAPI_11"

    var title: String
    var 作業日数: Double
    var 開始工程: 工程型?
    var 完了工程: 工程型?

    init(title: String, 作業日数: Double, 開始工程: 工程型?, 完了工程: 工程型?) {
        self.title = title
        self.作業日数 = 作業日数
        self.開始工程 = 開始工程
        self.完了工程 = 完了工程
    }
}

public class アクション作業型 {
    private let initialData: WorkData
    private var data : WorkData
    
    init(_ data: WorkData) {
        self.initialData = data
        self.data = data
    }
    
    public convenience init(title: String, 作業日数: Double, 開始工程: 工程型?, 完了工程: 工程型?) {
        let data = WorkData(title: title, 作業日数: 作業日数, 開始工程: 開始工程, 完了工程: 完了工程)
        self.init(data)
    }
    
    public var title: String {
        get { data.title }
        set { data.title = newValue }
    }
    public var 作業日数: Double {
        get { data.作業日数 }
        set { data.作業日数 = newValue }
    }
    public var 開始工程: 工程型? {
        get { data.開始工程 }
        set { data.開始工程 = newValue }
    }
    public var 完了工程: 工程型? {
        get { data.完了工程 }
        set { data.開始工程 = newValue }
    }

    public var isChanged: Bool { self.initialData != self.data }

}

// MARK: - アクション
/// アクション
struct ActionData {
    static let dbName = "DataAPI_12"

    let title: String
    let 開始工程: 工程型
    let 完了工程: 工程型
    let 開始日時: Date
    let 完了日時: Date
}
