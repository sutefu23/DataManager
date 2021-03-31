//
//  SerialNumber.swift
//  NCEngineから移行
//
//  Created by manager on 2020/05/11.
//  Copyright © 2020 四熊 泰之. All rights reserved.
//

import Foundation

public typealias ObjectID = UInt32

public let serialGenerator = SerialGenerator()

private let warningSpan: ObjectID = 10_0000 // 10万件ごとに警告
private let warningCount: ObjectID = 10 // 溢れるまでに10回ほど警告する

public final class SerialGenerator {
    private let lock = NSLock()
    private var limit: ObjectID = ObjectID.max - warningSpan * warningCount - warningSpan / 2
    private var serial: ObjectID = 0
    public init() {}
    public func generateID() -> ObjectID {
        lock.lock()
        defer { lock.unlock() }
        serial += 1 // 使い切ると落ちる
        #if os(macOS)
        if serial == limit { // 残り少なくなってくると警告
            DispatchQueue.main.async {
                let _ = showModalDialog(message: "オブジェクトIDが残り少なくなっています。アプリケーションを再起動して下さい", buttons: "Ok")
            }
            limit = limit &+ warningSpan
        }
        #endif
        return serial
    }

    /// 現在までに発行したIDの数
    public var count: ObjectID {
        lock.lock()
        defer { lock.unlock() }
        return serial
    }
}
