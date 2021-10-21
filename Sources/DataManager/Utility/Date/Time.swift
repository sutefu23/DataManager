//
//  Time.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct Time: DMCacheElement, Hashable, Comparable, CustomStringConvertible, Codable {
    public typealias HourType = Int8
    public typealias MinuteType = Int8
    public typealias SecondType = Int8

    public var hour: HourType
    public var minute: MinuteType
    public var second: SecondType
    
    public init() {
        self = Date().time
    }

    public init(hour: Int, minute: Int, second: Int = 0) {
        self.hour = HourType(hour)
        self.minute = MinuteType(minute)
        self.second = SecondType(second)
    }
    
    public init(_ hour: HourType, _ minute: MinuteType, _ second: SecondType = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    public init?<S: StringProtocol>(fmTime: S?) {
        guard let fmTime = fmTime else { return nil }
        self.init(fmJSONTime:fmTime)
    }

    /// 4桁の数字hhmmから初期化
    public init?<S: StringProtocol>(numbers: S?) {
        guard let numbers = numbers, let value = Int(numbers), value > 0 && value < 10000 else { return nil }
        self.hour = HourType(value / 100)
        self.minute = MinuteType(value % 100)
        self.second = 0
        guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else { return nil }
    }

    init?<T>(fmJSONTime: T?) where T: StringProtocol {
        guard let parts = fmJSONTime?.split(separator: ":") else { return nil }
        if parts.count == 3 {
            guard let hour = HourType(parts[0]), (0...23).contains(hour) else { return nil }
            guard let minute = MinuteType(parts[1]), (0...59).contains(minute) else { return nil }
            guard let second = SecondType(parts[2]), (0...60).contains(second) else { return nil }
            self.init(hour, minute, second)
        } else if parts.count == 2 {
            guard let hour = HourType(parts[0]), (0...23).contains(hour) else { return nil }
            guard let minute = MinuteType(parts[1]), (0...59).contains(minute) else { return nil }
            self.init(hour, minute, 0)
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
        self.hour = try values.decodeIfPresent(HourType.self, forKey: .hour) ?? 0
        self.minute = try values.decodeIfPresent(MinuteType.self, forKey: .minute) ?? 0
        self.second = try values.decodeIfPresent(SecondType.self, forKey: .second) ?? 0
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

    public var hourMinuteJString: String {
        return "\(make2dig(self.hour))時\(make2dig(self.minute))分"
    }

    public var hourMinuteSecondString: String {
        return "\(make2dig(self.hour)):\(make2dig(self.minute)):\(make2dig(self.second))"
    }

    public var description: String {
        return hourMinuteSecondString
    }
    
    var allSeconds: Int {
        return Int(hour) * 60 * 60 + Int(minute) * 60 + Int(second)
    }
    
    public func appendMinutes(_ minutes: Int) -> Time {
        assert(minutes >= 0)
        let newMinutes = Int(self.minute) + minutes
        let newHours = Int(self.hour) + newMinutes / 60
        return Time(HourType(newHours % 24), MinuteType(newMinutes % 60), self.second)
    }
    
    public func isSameHourMinutes(to time: Time) -> Bool {
        self.hour == time.hour && self.minute == time.minute
    }
}
public func -(left: Time, right: Time) -> TimeInterval {
    return TimeInterval(left.allSeconds - right.allSeconds)
}

extension Date {
    // MARK: 時間計算
    public var time: Time {
        let comp = cal.dateComponents([.hour, .minute, .second], from: self)
        return Time(Time.HourType(comp.hour!), Time.MinuteType(comp.minute!), Time.SecondType(comp.second!))
    }
}

let time0400 = Time(4, 0)
let time0830 = Time(8, 30)
let time1000 = Time(10, 00)
let time1010 = Time(10, 10)
let time1200 = Time(12, 00)
let time1300 = Time(13, 00)
let time1500 = Time(15, 00)
let time1510 = Time(15, 10)
let time1730 = Time(17, 30)
let time1740 = Time(17, 40)
let time2200 = Time(22, 00)
