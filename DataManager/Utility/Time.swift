//
//  Time.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

struct Time : Hashable, Comparable {
    let hour : Int
    let minute : Int
    let second : Int
    
    init(hour:Int, minute:Int, second:Int) {
        self.hour = hour
        self.minute = minute
        self.second = second
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
    
    static func <(left:Time, right:Time) -> Bool {
        if left.hour != right.hour { return left.hour < right.hour }
        if left.minute != right.minute { return left.minute < right.minute }
        return left.second < right.second
    }
}

extension Date {
    // MARK: 時間計算
    var time : Time {
        let comp = cal.dateComponents([.hour, .minute, .second], from: self)
        return Time(hour: comp.hour!, minute: comp.minute!, second: comp.second!)
    }

}
