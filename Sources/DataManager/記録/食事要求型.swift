//
//  食事要求型.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/09/26.
//

import Foundation

private let serialQueue: OperationQueue = {
   let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .utility
    return queue
}()

