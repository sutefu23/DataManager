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

// NCEngineから移植
extension Sequence {
    /// 値が１種類なら取り出す。２種類以上ならnilを返す
    public func reduceUnique<T : Equatable>(_ getter : (Element) -> T?) -> T? {
        var itr = self.makeIterator()
        while let object = itr.next() {
            guard let uniqueValue = getter(object) else { continue }
            while let object2 = itr.next() {
                guard let value = getter(object2) else { continue }
                if uniqueValue != value {
                    return nil
                }
            }
            return uniqueValue
        }
        return nil
    }

    // MARK: - 値の取り出し
    /// 最大値を取り出す
    public func maxValue<T : Comparable>(_ getter: (Element) -> T?) -> T? {
        var itr = self.makeIterator()
        while let object = itr.next() {
            guard var maxValue = getter(object) else { continue }
            while let object2 = itr.next() {
                guard let value = getter(object2) else { continue }
                if maxValue < value {
                    maxValue = value
                }
            }
            return maxValue
        }
        return nil
    }
    
    /// 最小値を取り出す
    public func minValue<T : Comparable>(_ getter: (Element) -> T?) -> T? {
        var itr = self.makeIterator()
        while let object = itr.next() {
            guard var minValue = getter(object) else { continue }
            while let object2 = itr.next() {
                guard let value = getter(object2) else { continue }
                if value < minValue {
                    minValue = value
                }
            }
            return minValue
        }
        return nil
    }
}
