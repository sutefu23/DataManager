//
//  Lock.swift
//  DataManager
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

extension DispatchQueue {
    func getValue<T>(_ getter:()->T) -> T {
        var result : T? = nil
        self.sync { result = getter() }
        return result!
    }
}
