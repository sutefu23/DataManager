//
//  伝票番号.swift
//  DataManager
//
//  Created by 四熊泰之 on 9/29/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct 伝票番号型 : Hashable, Comparable {
    public let number : Int
    
    public init(validNumber:Int) {
        self.number = validNumber
    }

    public init?(invalidString:String) {
        guard let number = Int(invalidString) else { return nil }
        self.init(invalidNumber:number)
    }
    
    public init?(invalidNumber:Int) {
        if !伝票番号型.isValidNumber(invalidNumber) { return nil }
        self.number = invalidNumber
        if testIsValid() == false { return nil }
    }
    
    public func testIsValid() -> Bool {
        let orders = 指示書型.find(伝票番号: self.number)
        return orders?.isEmpty == false
    }
    
    // MARK: -
    public static func isValidNumber(_ number:Int) -> Bool {
        return number >= 10_0000 && number <= 9999_99999
    }
    
    // MARK: - Comparable
    public static func <(left:伝票番号型, right:伝票番号型) -> Bool {
        return left.number < right.number
    }
}
