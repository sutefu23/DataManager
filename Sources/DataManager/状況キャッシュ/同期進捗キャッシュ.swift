//
//  同期進捗キャッシュ.swift
//  DataManager
//
//  Created by manager on 2021/07/20.
//

import Foundation

class 同期進捗キャッシュ型 {
    static let shared = 同期進捗キャッシュ型()
    struct Key: Hashable {
        let 工程: 工程型
        let 作業者: 社員型
        let 基準日: Day
        let 基準時間: Time
        
        init(_ progress: 進捗型) {
            self.工程 = progress.工程
            self.作業者 = progress.作業者
            self.基準日 = progress.登録日
            var time = progress.登録時間
            time.second = 0
            self.基準時間 = time
        }
    }
    
    struct Data {
        let 進捗一覧: [進捗型]
        
        init(_ key: Key) {
            let date = Date(key.基準日, key.基準時間)
            let from = date.addingTimeInterval(-120)
            let to = date.addingTimeInterval(180)
            let fromDay = from.day
            let fromTime = from.time
            let toDay = to.day
            let toTime = to.time
            if fromDay == toDay {
                do {
                    self.進捗一覧 = try 進捗型.find(工程: key.工程, 作業者: key.作業者, 登録日: fromDay, 登録期間: fromTime..<toTime).sorted { $0.登録日時 < $1.登録日時 }
                } catch {
                    self.進捗一覧 = []
                }
            } else {
                self.進捗一覧 = []
            }
        }
    }
    
    private let lock = NSLock()
    private var map: [Key: Data] = [:]
    
    func 関連進捗(for progress: 進捗型) -> [進捗型] {
        let key = Key(progress)
        lock.lock()
        defer { lock.unlock() }
        if let cache = map[key] { return cache.進捗一覧 }
        let data = Data(key)
        map[key] = data
        return data.進捗一覧
    }
}
