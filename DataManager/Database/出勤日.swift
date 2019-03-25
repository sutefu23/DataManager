//
//  出勤日.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

extension Date {
//    public var isHoliday : Bool {
//        return self.day.isHoliday
//    }
    
    public var nextDay : Date {
        return cal.date(byAdding: .day, value: 1, to: self)!
    }

    public var prevDay : Date {
        return cal.date(byAdding: .day, value: -1, to: self)!
    }

    public func date(ofHour hour:Int, minute:Int) -> Date {
        var coms = cal.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        coms.hour = hour
        coms.minute = minute
        return cal.date(from: coms)!
    }
    
    var dayNumber : Int {
        return cal.component(.day, from: self)
    }

    var monthNumber : Int {
        return cal.component(.month, from: self)
    }

    public var monthDayWeekString : String {
        return "\(monthNumber)/\(dayNumber) (\(week.description))"
    }
    

    public var dayWeekString : String {
        return "\(dayNumber)(\(week.description))"
    }
    
    public var monthDayHourMinuteString : String {
        return "\(self.day.monthDayString) \(self.time.hourMinuteString)"
    }
    
    public var dayWeekToMinuteString : String {
        return "\(self.dayWeekString) \(self.time.hourMinuteString)"
    }
}


extension Day {
    var isWorkday : Bool {
        return !isHoliday
    }
    var isHoliday : Bool {
        return db.isHoliday(of: self)
    }
    
    var dynamicIsHoliday : Bool {
        return db.dynamicIsHoliday(self)
    }
}
private let db = 出勤日DB型()

class 出勤日DB型 {
    // 2016/10/01 ~ 2019/03/31
    /// 土日以外の休日
    let holidays : Set<Day> = [
        Day(2016,10,10),
        Day(2016,11,03),
        Day(2016,11,23),
        Day(2016,12,23),
        Day(2016,12,29),
        Day(2016,12,30),
        Day(2017,01,02),
        Day(2017,01,03),
        Day(2017,01,04),
        Day(2017,01,09),
        Day(2017,05,03),
        Day(2017,05,04),
        Day(2017,05,05),
        Day(2017,07,17),
        Day(2017,08,11),
        Day(2017,08,14),
        Day(2017,08,15),
        Day(2017,09,18),
        Day(2017,10,09),
        Day(2017,11,03),
        Day(2017,11,23),
        Day(2018,01,01),
        Day(2018,01,02),
        Day(2018,01,03),
        Day(2018,01,04),
        Day(2018,01,05),
        Day(2018,01,08),
        Day(2018,02,12),
        Day(2018,04,30),
        Day(2018,05,03),
        Day(2018,05,04),
        Day(2018,07,16),
        Day(2018,08,13),
        Day(2018,08,14),
        Day(2018,08,15),
        Day(2018,09,17),
        Day(2018,09,24),
        Day(2018,10,08),
        Day(2018,11,23),
        Day(2018,12,24),
        Day(2018,12,31),
        Day(2019,01,01),
        Day(2019,01,02),
        Day(2019,01,03),
        Day(2019,01,04),
        Day(2019,01,14),
        Day(2019,02,11),
        ]
    /// 土曜出勤日
    let workdays : Set<Day> = [
        Day(2016,10,15),
        Day(2016,11,05),
        Day(2016,12,24),
        Day(2017,01,07),
        Day(2017,01,21),
        Day(2017,01,28),
        Day(2017,02,04),
        Day(2017,02,18),
        Day(2017,02,25),
        Day(2017,03,04),
        Day(2017,03,11),
        Day(2017,03,18),
        Day(2017,03,25),
        Day(2017,07,22),
        Day(2017,08,19),
        Day(2017,09,09),
        Day(2017,09,16),
        Day(2017,09,30),
        Day(2017,10,14),
        Day(2017,11,25),
        Day(2017,12,30),
        Day(2018,01,06),
        Day(2018,01,13),
        Day(2018,01,27),
        Day(2018,02,03),
        Day(2018,02,10),
        Day(2018,02,17),
        Day(2018,02,24),
        Day(2018,03,03),
        Day(2018,03,10),
        Day(2018,03,17),
        Day(2018,03,24),
        Day(2018,03,31),
        Day(2018,07,21),
        Day(2018,08,18),
        Day(2018,09,22),
        Day(2018,09,29),
        Day(2018,10,13),
        Day(2018,11,24),
        Day(2018,12,29),
        Day(2019,01,12),
        Day(2019,01,19),
        Day(2019,02,02),
        Day(2019,02,09),
        Day(2019,02,16),
        Day(2019,02,23),
        Day(2019,03,02),
        Day(2019,03,09),
        Day(2019,03,16),
        Day(2019,03,23),
        Day(2019,03,30),
        ]
    
    let oldline : Day
    let baseline : Day
    private var isHolidayCache : [Day : Bool] = [:]
    private let lock = Lock()
    
    private func isHoidayCacheData(of day:Day) -> Bool? {
        lock.lock()
        defer { lock.unlock() }
        return isHolidayCache[day]
    }
    private func setIsHolidayCacheData(day:Day, isHoliday:Bool) {
        lock.lock()
        isHolidayCache[day] = isHoliday
        lock.unlock()
    }
    
    init() {
        self.baseline = max(workdays.max()!, holidays.max()!)
        self.oldline = min(workdays.min()!, holidays.min()!)
    }
    func isHoliday(of day:Day) -> Bool {
        if let isHoliday = isHoidayCacheData(of: day) { return isHoliday }
        let isHoliday : Bool
        if day < oldline {
            fatalError() // 想定していない
        } else if day <= baseline {
            switch day.week {
            case .日:
                isHoliday = true
            case .土:
                isHoliday = (workdays.contains(day) == false)
            default:
                isHoliday = holidays.contains(day)
            }
        } else {
            isHoliday = dynamicIsHoliday(day)
        }
        setIsHolidayCacheData(day: day, isHoliday: isHoliday)
        return isHoliday
    }
    
    func dynamicIsHoliday(_ day:Day) -> Bool {
        let db = FileMakerDB.pm_osakaname
        let isHoliday : Bool
        if day.week == .日 {
            isHoliday = true
        } else {
            let list : [スケジュール型] = db.find(at: day)
            isHoliday = list.contains { $0.種類 == "休日" }
        }
        lock.lock()
        isHolidayCache[day] = isHoliday
        lock.unlock()
        return isHoliday
    }
}

