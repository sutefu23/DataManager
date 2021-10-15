//
//  Windows.swift
//  DataManager
//
//  Created by manager on 2021/10/15.
//

import Foundation

#if os(Windows)
func autoreleasepool<T>(_ block: () throws -> T) rethrows -> T {
    return try block()
}
#endif
