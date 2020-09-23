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

