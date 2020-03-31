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

private class MapObject<E,T> {
    let source: E
    var result: T? = nil
    init(_ source: E) { self.source = source }
}

extension Array {
    public func concurrentForEach(_ operation: (Element)->Void) {
        DispatchQueue.concurrentPerform(iterations: self.count) {
            let object = self[$0]
            operation(object)
        }
    }

    public func concurrentCompactMap<T>(converter: (_ item:Element)->T?) -> [T] {
        if self.count <= 1 {
            if self.isEmpty { return [] }
            if let result = converter(self[0]) { return [result] } else { return [] }
        }
        let source = self.map { MapObject<Element, T>($0) }
        DispatchQueue.concurrentPerform(iterations: self.count) {
            index in
            let object = source[index]
            let result = converter(object.source)
            object.result = result
        }
        return source.compactMap(\.result)
    }
    
    public func concurrentMap<T>(converter: (_ item:Element) throws ->T) rethrows -> [T] {
        if self.count <= 1 {
            return try self.map { try converter($0) }
        }
        let source = self.map { MapObject<Element, Result<T, Error>>($0) }
        DispatchQueue.concurrentPerform(iterations: self.count) {
            index in
            let object = source[index]
            do {
                let result = try converter(object.source)
                object.result = .success(result)
            } catch {
                object.result = .failure(error)
            }
        }
        return try source.map { try $0.result!.get() }
    }
}

