//
//  同期進捗キャッシュ.swift
//  DataManager
//
//  Created by manager on 2021/07/20.
//

import Foundation

class 同期進捗キャッシュ型 {
    static let shared = 同期進捗キャッシュ型()
    
    class Data {
        struct Key: Hashable {
            let 工程: 工程型
            let 作業者: 社員型
            
            init(_ progress: 進捗型) {
                self.工程 = progress.工程
                self.作業者 = progress.作業者
            }
        }
        private let 進捗一覧: [進捗型]
        private let map: [Key: [進捗型]]
        
        init(_ day: Day) {
            do {
                self.進捗一覧 = try 進捗型.find(登録日: day).sorted { $0.登録日時 < $1.登録日時 }
            } catch {
                self.進捗一覧 = []
            }
            self.map = Dictionary(grouping: self.進捗一覧) { Key($0) }
        }
        
        func list(for progress: 進捗型) -> [進捗型] {
            let key = Key(progress)
            guard let list = map[key] else { return [] }
            let date = progress.登録日時
            let from = date.addingTimeInterval(-1 * 60)
            let to = date.addingTimeInterval(1 * 60)
            return list.filter { (from...to).contains($0.登録日時) }
        }
    }
    
    private let lock = NSLock()
    private var map: [Day: Data] = [:]
    private var working: [Day: NSLock] = [:]
    
    func 関連進捗(for progress: 進捗型) -> [進捗型] {
        let day = progress.登録日
        lock.lock()
        if let cache = map[day] {
            lock.unlock()
            return cache.list(for: progress)
        }
        if let workingLock = working[day] {
            lock.unlock()
            workingLock.lock()
            workingLock.unlock()
            lock.lock()
            defer { lock.unlock() }
            return map[day]!.list(for: progress)
        }
        let workingLock = NSLock()
        workingLock.lock()
        working[day] = workingLock
        lock.unlock()
        let data = Data(day)
        lock.lock()
        map[day] = data
        lock.unlock()
        workingLock.unlock()
        return data.list(for: progress)
    }
}
