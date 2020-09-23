//
//  Set.swift
//  DataManager
//
//  Created by manager on 2020/01/29.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

extension Set where Element == Int {
    public func makeRange() -> [ClosedRange<Int>] {
        var result: [ClosedRange<Int>] = []
        var working: ClosedRange<Int>? = nil
        for number in self.sorted() {
            if let current = working {
                if current.upperBound+1 == number {
                    working = current.lowerBound...number
                } else {
                    result.append(current)
                    working = number...number
                }
            } else {
                working = number...number
            }
        }
        if let rest = working { result.append(rest) }
        return result
    }
    
}
