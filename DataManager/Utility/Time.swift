//
//  Time.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct Time : Hashable, Comparable {
    public let hour : Int
    public let minute : Int
    public let second : Int
    
    public init() {
        self.hour = 0
        self.minute = 0
        self.second = 0
    }
    
    public init(hour:Int, minute:Int, second:Int = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    public init(_ hour:Int, _ minute:Int, _ second:Int = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    public init?<S:StringProtocol>(fmTime:S) {
        self.init(fmJSONTime:fmTime)
    }
    
    init?<T>(fmJSONTime:T?) where T : StringProtocol {
        guard let parts = fmJSONTime?.split(separator: ":") else { return nil }
        if parts.count == 3 {
            guard let hour = Int(parts[0]) else { return nil }
            guard let minute = Int(parts[1]) else { return nil }
            guard let second = Int(parts[2]) else { return nil }
            self.init(hour:hour, minute:minute, second:second)
        } else if parts.count == 2 {
            guard let hour = Int(parts[0]) else { return nil }
            guard let minute = Int(parts[1]) else { return nil }
            self.init(hour:hour, minute:minute, second:0)
        } else {
            return nil
        }
    }
    
    public static func <(left:Time, right:Time) -> Bool {
        if left.hour != right.hour { return left.hour < right.hour }
        if left.minute != right.minute { return left.minute < right.minute }
        return left.second < right.second
    }
    
    var fmImportString : String {
        return "\(make2dig(self.hour)):\(make2dig(self.minute)):\(make2dig(self.second))"
    }
    
    var hourMinuteString : String {
        return "\(make2dig(self.hour)):\(make2dig(self.minute))"
    }
    
    var description : String {
        return "\(make2dig(self.hour)):\(make2dig(self.minute)):\(make2dig(self.second))"
    }
    
    var allSeconds : Int {
        return hour * 60 * 60 + minute * 60 + second
    }
}
public func -(left:Time, right:Time) -> TimeInterval {
    return TimeInterval(left.allSeconds - right.allSeconds)
}

extension Date {
    // MARK: 時間計算
    public var time : Time {
        let comp = cal.dateComponents([.hour, .minute, .second], from: self)
        return Time(hour: comp.hour!, minute: comp.minute!, second: comp.second!)
    }
}

let time0400 = Time(hour: 4, minute: 0)
let time0830 = Time(hour: 8, minute: 30)
let time1000 = Time(hour: 10, minute: 00)
let time1010 = Time(hour: 10, minute: 10)
let time1200 = Time(hour: 12, minute: 00)
let time1300 = Time(hour: 13, minute: 00)
let time1500 = Time(hour: 15, minute: 00)
let time1510 = Time(hour: 15, minute: 10)
let time1730 = Time(hour: 17, minute: 30)
let time1740 = Time(hour: 17, minute: 40)
let time2200 = Time(hour: 22, minute: 00)
