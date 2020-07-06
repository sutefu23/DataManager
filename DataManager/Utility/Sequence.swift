//
//  Sequence.swift
//  DataManager
//
//  Created by manager on 2020/02/03.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

extension Sequence {
    public func average(_ getter: (Element)->Double?) -> Double? {
        var count = 0
        var sum = 0.0
        for element in self {
            if let value = getter(element) {
                sum += value
                count += 1
            }
        }
        if count > 0 {
            return sum / Double(count)
        } else {
            return nil
        }
    }
}
