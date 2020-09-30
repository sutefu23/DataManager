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

struct 食事要求Data型 {
    enum 要求状態型 {
        case 未処理
        case 受取待ち
        case 受け渡し済み
    }
    var 登録日時: Date
    var 社員: 社員型
    var メニュー: 食事メニュー型 // メニューID
    var 状態: 要求状態型
}
