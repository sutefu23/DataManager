//
//  Concurrent.swift
//  NCEngine
//
//  Created by 四熊 泰之 on H28/10/10.
//  Copyright © 平成28年 四熊 泰之. All rights reserved.
//

import Foundation

/// メインスレッドだとそのまま実行。そうでない場合、メインスレッドを待って、メインスレッドで実行
public func executeInMainThread<T>( _ exec: ()->T) -> T {
    if Thread.isMainThread {
        return exec()
    } else {
        var result : T?
        DispatchQueue.main.sync {
            result = exec()
        }
        return result!
    }
}



public extension NSLock {
    func exec(_ operation: ()->()) {
        self.lock()
        operation()
        self.unlock()
    }
    
    func getValue<T>(_ getter: ()->T) -> T {
        self.lock()
        defer { self.unlock() }
        return getter()
    }
}

public extension NSRecursiveLock {
    func exec(_ operation: ()->()) {
        self.lock()
        operation()
        self.unlock()
    }
    
    func getValue<T>(_ getter: ()->T) -> T {
        self.lock()
        defer { self.unlock() }
        return getter()
    }
}

public extension OperationQueue {
    func execOperation(_ exec: @escaping () -> Void) {
        let operation = BlockOperation(block: exec)
        self.addOperation(operation)
        operation.waitUntilFinished()
    }

    func execOperation<T>(_ exec: @escaping () -> T) -> T {
        var result: T!
        let operation = BlockOperation {
            result = exec()
        }
        self.addOperation(operation)
        operation.waitUntilFinished()
        return result
    }

    func execOperation<T>(_ exec: @escaping () throws -> T) throws -> T {
        var result: Result<T, Error>!
        let operation = BlockOperation {
            do {
                result = try .success(exec())
            } catch {
                result = .failure(error)
            }
        }
        self.addOperation(operation)
        operation.waitUntilFinished()
        return try result.get()
    }
}
