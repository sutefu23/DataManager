//
//  RunLoop.swift
//  NCEngine
//
//  Created by manager on 2020/07/21.
//  Copyright © 2020 四熊 泰之. All rights reserved.
//
// ECEngineより移行

import Foundation

private let lock = NSLock()
private var targets: Set<ObjectIdentifier> = []
private var execs: [(id: ObjectIdentifier, exec: ()->Void)] = []

public extension RunLoop {
    static func execOnce<T: AnyObject>(_ target: T?, exec: @escaping (T)->Void) {
        guard let target = target else { return }
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                RunLoop.execOnce(target, exec: exec)
            }
            return
        }
        let id = ObjectIdentifier(target)
        if targets.isEmpty {
            DispatchQueue.main.async {
                assert(Thread.isMainThread)
                let execs2 = execs
                execs.removeAll()
                targets.removeAll()
                execs2.forEach { $0.exec() }
            }
        }
        let (inserted, _) = targets.insert(id)
        if inserted {
            let data = (id, { exec(target) })
            execs.append(data)
        }
    }
    
    static func execeOnceNow<T: AnyObject>(_ target: T?) {
        assert(Thread.isMainThread)
        guard Thread.isMainThread, let target = target else { return }
        let id = ObjectIdentifier(target)
        guard targets.remove(id) != nil else { return }
        for (index, data) in execs.enumerated() {
            if data.id == id {
                execs.remove(at: index)
                data.exec()
                return
            }
        }
    }
    
    static func cancelOnce<T: AnyObject>(_ target: T?) {
        assert(Thread.isMainThread)
        guard Thread.isMainThread, let target = target else { return }
        let id = ObjectIdentifier(target)
        guard targets.remove(id) != nil else { return }
        for (index, data) in execs.enumerated() {
            if data.id == id {
                execs.remove(at: index)
                return
            }
        }
    }
}
