//
//  Future.swift
//  DataManager
//
//  Created by manager on 2020/02/01.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

private let queue = OperationQueue()

public class Future<T> {
    
    var operation: Operation!
    var resultValue: T!
    private let lock = NSLock()

    public init(_ exec:@escaping ()->T) {
        let operation = BlockOperation {
            let val = exec()
            self.lock.lock()
            self.resultValue = val
            self.lock.unlock()
        }
        self.operation = operation
        queue.addOperation(operation)
    }
    
    public var result: T {
        operation.waitUntilFinished()
        return resultValue
    }
}

extension Array {
    enum ConcurrentError: Error {
        case emptyData
    }

    public func concurrentForEach(_ operation: (Element)->Void) {
        DispatchQueue.concurrentPerform(iterations: self.count) {
            let object = self[$0]
            operation(object)
        }
    }

    public func concurrentCompactMap<T>(converter: (_ item: Element) throws ->T?) rethrows -> [T] {
        if self.count <= 1 {
            if let result = try converter(self[0]) { return [result] } else { return [] }
        }
        var results = [Result<T?, Error>](repeating: .failure(ConcurrentError.emptyData), count: self.count)
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: self.count) {
            let index = self.index(self.startIndex, offsetBy: $0)
            let target = self[index]
            do {
                let result = try converter(target)
                lock.lock()
                results[$0] = .success(result)
                lock.unlock()
            } catch {
                lock.lock()
                results[$0] = .failure(error)
                lock.unlock()
            }
        }
        return try results.compactMap { try $0.get() }
    }

    public func concurrentMap<T>(converter: (_ item: Element) throws ->T) rethrows -> [T] {
        if self.count <= 1 {
            return try self.map { try converter($0) }
        }
        var results = [Result<T, Error>](repeating: .failure(ConcurrentError.emptyData), count: self.count)
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: self.count) {
            let index = self.index(self.startIndex, offsetBy: $0)
            let target = self[index]
            do {
                let result = try converter(target)
                lock.lock()
                results[$0] = .success(result)
                lock.unlock()
            } catch {
                lock.lock()
                results[$0] = .failure(error)
                lock.unlock()
            }
        }
        return try results.map { try $0.get() }
    }
}
