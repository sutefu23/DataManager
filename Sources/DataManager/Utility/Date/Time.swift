//
//  Time.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct Time: Hashable, Comparable, CustomStringConvertible, Codable {
    public var hour: Int
    public var minute: Int
    public var second: Int
    
    public init() {
        self = Date().time
    }
    
    public init(hour: Int, minute: Int, second: Int = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    public init(_ hour: Int, _ minute: Int, _ second: Int = 0) {
        self.init(hour:hour, minute:minute, second:second)
    }

    public init?<S: StringProtocol>(fmTime: S) {
        self.init(fmJSONTime:fmTime)
    }
    
    init?<T>(fmJSONTime: T?) where T: StringProtocol {
        guard let parts = fmJSONTime?.split(separator: ":") else { return nil }
        if parts.count == 3 {
            guard let hour = Int(parts[0]), (0...23).contains(hour) else { return nil }
            guard let minute = Int(parts[1]), (0...59).contains(minute) else { return nil }
            guard let second = Int(parts[2]), (0...60).contains(second) else { return nil }
            self.init(hour:hour, minute:minute, second:second)
        } else if parts.count == 2 {
            guard let hour = Int(parts[0]), (0...23).contains(hour) else { return nil }
            guard let minute = Int(parts[1]), (0...59).contains(minute) else { return nil }
            self.init(hour:hour, minute:minute, second:0)
        } else {
            return nil
        }
    }
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case hour = "Hour"
        case minute = "Minute"
        case second = "Second"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.hour = try values.decodeIfPresent(Int.self, forKey: .hour) ?? 0
        self.minute = try values.decodeIfPresent(Int.self, forKey: .minute) ?? 0
        self.second = try values.decodeIfPresent(Int.self, forKey: .second) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if self.hour != 0 { try container.encode(self.hour, forKey: .hour) }
        if self.minute != 0 { try container.encode(self.minute, forKey: .minute) }
        if self.second != 0 { try container.encode(self.second, forKey: .second) }
    }


    // MARK: -
    public static func <(left: Time, right: Time) -> Bool {
        if left.hour != right.hour { return left.hour < right.hour }
        if left.minute != right.minute { return left.minute < right.minute }
        return left.second < right.second
    }
    
    public var fmImportString: String {
        return "\(make2dig(self.hour)):\(make2dig(self.minute)):\(make2dig(self.second))"
    }
    
    public var hourMinuteString: String {
        return "\(make2dig(self.hour)):\(make2dig(self.minute))"
    }

    public var hourMinuteSecondString: String {
        return "\(make2dig(self.hour)):\(make2dig(self.minute)):\(make2dig(self.second))"
    }

    public var description: String {
        return hourMinuteSecondString
    }
    
    var allSeconds: Int {
        return hour * 60 * 60 + minute * 60 + second
    }
    
    public func appendMinutes(_ minutes: Int) -> Time {
        var hour = self.hour
        var minute = self.minute + minutes
        while minute >= 60 {
            minute -= 60
            hour += 1
            if hour >= 24 { hour -= 24 }
        }
        let second = self.second
        return Time(hour, minute, second)
    }
}
public func -(left: Time, right: Time) -> TimeInterval {
    return TimeInterval(left.allSeconds - right.allSeconds)
}

extension Date {
    // MARK: 時間計算
    public var time: Time {
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
