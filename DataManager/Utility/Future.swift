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
