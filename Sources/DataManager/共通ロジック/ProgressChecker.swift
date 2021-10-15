//
//  ProgressChecker.swift
//  DataManager
//
//  Created by manager on R 3/05/25.
//

import Foundation

/// ProgressCheckerの詳細モード
public enum ProgressCheckerDetailMode {
    /// 表示
    case view
    /// 編集
    case edit
}

/// ProgressCheckerの表示モード
public enum ProgressChecker表示モード型 {
    case 箱文字前工程モード
    case 通常モード
}
//
let matrixLine = 8

let buddyProcess: [工程型: 工程型] = [
    工程型.立ち上がり: 工程型.半田,
    工程型.立ち上がり_溶接: 工程型.溶接
]
let 必要略号リスト: [工程型: 略号型] = [
    .半田: .半田,
    .裏加工: .半田,
    .溶接: .溶接,
    .裏加工_溶接: .溶接
]

public let ProgressChecker待ち工程リスト: [工程型: 工程型] = [
    工程型.立ち上がり: 工程型.照合検査,
    工程型.立ち上がり_溶接: 工程型.照合検査,
]


class CountCell {
    let 種類: 伝票種類型
    let 工程: 工程型
    
    let totalOrders: [指示書型]
    let completeOrders: [指示書型]
    let holdingOrders: [指示書型]
    let waitingOrders: [指示書型]
    let todayOrders: [指示書型]
    
    let totalOrders1: [指示書型]
    let completeOrders1: [指示書型]
    let holdingOrders1: [指示書型]
    let waitingOrders1: [指示書型]
    let todayOrders1: [指示書型]
    
    let totalOrders2: [指示書型]
    let completeOrders2: [指示書型]
    let holdingOrders2: [指示書型]
    let waitingOrders2: [指示書型]
    let todayOrders2: [指示書型]
    
    init(工程:工程型, 日付:Day, 種類:伝票種類型, 略号: 略号型?) {
        self.種類 = 種類
        self.工程 = 工程
        
        let source = (try? 指示書型.find(伝票種類: 種類, 製作納期: 日付)) ?? []
        let orders : [指示書型] = source.filter {
            if let ryaku = 略号 {
                return $0.略号情報.contains(ryaku)
            }
            return true
        }
        var completeOrders: [指示書型] = []
        var holdingOrders: [指示書型] = []
        var waitingOrders: [指示書型] = []
        var todayOrders: [指示書型] = []
        
        let toNext = 日付.nextDay
        let now = Date().day
        for order in orders {
            if order.伝票状態 == .キャンセル { continue }
            if let state = order.作業進捗一覧.作業内容(工程: 工程, 日時: toNext) {
                switch state {
                case .完了:
                    completeOrders.append(order)
                case .受取, .開始, .仕掛:
                    holdingOrders.append(order)
                }
            } else {
                let prevProcess : 工程型?
                switch 工程 {
                case .原稿:
                    prevProcess = .管理
                case .照合検査:
                    prevProcess = .レーザー
                case .立ち上がり:
                    prevProcess = .照合検査
                default:
                    prevProcess = nil
                }
                if let process = prevProcess {
                    if order.作業進捗一覧.作業内容(工程: process, 日時: toNext) == .完了 {
                        holdingOrders.append(order)
                    } else {
                        waitingOrders.append(order)
                    }
                } else {
                    if !holdingOrders.contains(where: { $0 === order } ) {
                        waitingOrders.append(order)
                    }
                }
            }
            if order.受注日 == now {
                todayOrders.append(order)
            }
        }
        if let buddy = buddyProcess[工程] {
            var newWaitingOrder: [指示書型] = []
            for order in waitingOrders {
                if !order.進捗一覧.contains(where: { $0.工程 == buddy }) {
                    newWaitingOrder.append(order)
                } else {
                    completeOrders.append(order)
                }
            }
            waitingOrders = newWaitingOrder
        }
        if let num = 必要略号リスト[工程] {
            waitingOrders = waitingOrders.filter { $0.略号情報.contains(num) }
        }
        if 工程 == .立ち上がり {
            var newCompleteOrders: [指示書型] = []
            for order in completeOrders {
                switch order.立ち上がりランク {
                case .立ち上がり先行受取待ち_赤:
                    waitingOrders.append(order)
                case .通常_黒, .立ち上がり先行受取済み_青:
                    newCompleteOrders.append(order)
                }
            }
            completeOrders = newCompleteOrders
            var newHolding: [指示書型] = []
            for order in holdingOrders {
                switch order.立ち上がりランク {
                case .立ち上がり先行受取待ち_赤:
                    waitingOrders.append(order)
                case .通常_黒, .立ち上がり先行受取済み_青:
                    newHolding.append(order)
                }
                holdingOrders = newHolding
            }
        }
        self.totalOrders = orders
        self.completeOrders = completeOrders
        self.holdingOrders = holdingOrders
        self.waitingOrders = waitingOrders
        self.todayOrders = todayOrders
        
        func divideOrders(_ source: [指示書型]) -> (main: [指示書型], sub: [指示書型]) {
            var main: [指示書型] = []
            var sub: [指示書型] = []
            for order in source {
                switch 工程 {
                case .レーザー:
                    switch order.伝票種類 {
                    case .加工, .エッチング:
                        if order.isフォーミングのみ {
                            sub.append(order)
                        } else {
                            main.append(order)
                        }
                    case .切文字, .外注, .校正, .箱文字, .赤伝:
                        main.append(order)
                    }
                case .照合検査:
                    switch order.伝票種類 {
                    case .加工:
                        if order.isフォーミングのみ || order.isオブジェ {
                            sub.append(order)
                        } else {
                            main.append(order)
                        }
                    case .エッチング:
                        if order.isフォーミングのみ {
                            sub.append(order)
                        } else {
                            main.append(order)
                        }
                    case .切文字, .外注, .校正, .箱文字, .赤伝:
                        main.append(order)
                    }
                case .フォーミング:
                    switch order.伝票種類 {
                    case .加工, .エッチング:
                        if order.isレーザーのみ || (order.isオブジェ && !order.略号情報.contains(.フォーミング)) {
                            sub.append(order)
                        } else {
                            main.append(order)
                        }
                    case .切文字, .外注, .校正, .赤伝, .箱文字:
                        main.append(order)
                    }
                default:
                    switch order.伝票種類 {
                    case .加工:
                        if order.isオブジェ {
                            sub.append(order)
                        } else {
                            main.append(order)
                        }
                    case .切文字, .外注, .校正, .赤伝, .箱文字, .エッチング:
                        main.append(order)
                    }
                }
            }
            return (main, sub)
        }
        
        (self.totalOrders1, self.totalOrders2) = divideOrders(orders)
        (self.completeOrders1, self.completeOrders2) = divideOrders(completeOrders)
        (self.holdingOrders1, self.holdingOrders2) = divideOrders(holdingOrders)
        (self.waitingOrders1, self.waitingOrders2) = divideOrders(waitingOrders)
        (self.todayOrders1, self.todayOrders2) = divideOrders(todayOrders)
    }
    
    func makeOutline(index: Int) -> NSAttributedString {
        func makeString(_ header:String, number:Int) -> String {
            if number == 0 && UserDefaults.standard.isShow0Cell == false { return "" }
            return " \(header):\(number)"
        }
        func makeString2(_ header:String, number:Int, color: DMColor) -> NSAttributedString {
            let str = makeString(header, number: number)
            return NSAttributedString(string: str, color: color)
        }
        func makeString2x(_ header: String, number: Int, number2: Int, color: DMColor) -> NSAttributedString {
            if number2 == 0 { return makeString2(header, number: number, color: color) }
            let str = " \(header):\(number)+\(number2)"
            return NSAttributedString(string: str, color: color)
        }
        switch index {
        case 0:
            return NSAttributedString(string: "*\(種類)")
        case 1:
            return makeString2x("総数", number: totalOrders1.count, number2: totalOrders2.count, color: .black)
        case 2:
            return makeString2x("完了", number: completeOrders1.count, number2: completeOrders2.count, color: .blue)
        case 3:
            return makeString2x("手持", number: holdingOrders1.count, number2: holdingOrders2.count, color: .magenta)
        case 4:
            return makeString2x("待ち", number: waitingOrders1.count, number2: waitingOrders2.count, color: .red)
        case 5:
            return makeString2x("新規", number: todayOrders1.count, number2: todayOrders2.count, color: .black)
        default:
            return NSAttributedString(string: "")
        }
    }
    
    func detailOrders(index:Int) -> DetailInfo? {
        let work : String
        let orders : [指示書型]
        switch index {
        case 1:
            work = "総計"
            orders = totalOrders
        case 2:
            work = "完了"
            orders = completeOrders
        case 3:
            work = "手持"
            orders = holdingOrders
        case 4:
            work = "待ち"
            orders = waitingOrders
        case 5:
            work = "新規"
            orders = todayOrders
        default:
            return nil
        }
        var info = DetailInfo()
        info.work = work
        info.orders = orders
        info.伝票種類 = self.種類
        return info
    }
}

class CountColumn {
    let 日付 : Day
    var 箱文字 : CountCell? = nil
    var 切文字 : CountCell?
    var エッチング : CountCell?
    var 加工 : CountCell?
    
    init(工程:工程型, 日付:Day, 略号:略号型?, queue:OperationQueue, completionHandler:@escaping ()->()) {
        assert(日付.isWorkday)
        self.日付 = 日付
        queue.addOperation {
            self.箱文字 = CountCell(工程:工程, 日付:日付, 種類:.箱文字, 略号:略号)
            completionHandler()
        }
        queue.addOperation {
            self.切文字 = CountCell(工程:工程, 日付:日付, 種類:.切文字, 略号:略号)
            completionHandler()
        }
        queue.addOperation {
            self.エッチング = CountCell(工程:工程, 日付:日付, 種類:.エッチング, 略号:略号)
            completionHandler()
        }
        queue.addOperation {
            self.加工 = CountCell(工程:工程, 日付:日付, 種類:.加工, 略号:略号)
            completionHandler()
        }
    }
    
    private subscript(row:Int) -> CountCell? {
        switch row {
        case 0:
            return 箱文字
        case 1:
            return 切文字
        case 2:
            return エッチング
        case 3:
            return 加工
        default:
            fatalError()
        }
    }
    
    func makeOutline(row:Int, index:Int) -> NSAttributedString {
        let cell = self[row]
        switch index {
        case 1: if !UserDefaults.standard.isShowTotal { return NSAttributedString(string: "") }
        case 2: if !UserDefaults.standard.isShowComplete { return NSAttributedString(string: "") }
        case 3: if !UserDefaults.standard.isShowHolding { return NSAttributedString(string: "") }
        case 4: if !UserDefaults.standard.isShowWaiting { return NSAttributedString(string: "") }
        case 5: if !UserDefaults.standard.isShowNew { return NSAttributedString(string: "") }
        default: break
        }
        return cell?.makeOutline(index: index) ?? NSAttributedString(string: "")
    }
    
    func detailOrder(row:Int, index:Int) -> DetailInfo? {
        let cell = self[row]
        guard var info = cell?.detailOrders(index: index) else { return nil }
        let type : String
        switch row {
        case 0: type = "箱文字伝票"
        case 1: type = "切文字伝票"
        case 2: type = "エッチング"
        case 3: type = "加工伝票"
        default:
            return nil
        }
        info.type = type
        info.limit = self.日付
        return info
    }
}

public class CountMatrix {
    let labelCount = 6
    public var numberOfRows: Int { return 4*labelCount+1 }
    
    var columns: [CountColumn]
    
    public init(工程: 工程型, 略号:略号型?, queue: OperationQueue, completionHandler: @escaping ()->()) {
        var day = Day().prevDay
        
        var rows = [CountColumn]()
        for _ in 1...matrixLine {
            day = day.翌出勤日()
            let row = CountColumn(工程: 工程, 日付: day, 略号:略号, queue:queue, completionHandler:completionHandler)
            rows.append(row)
        }
        self.columns = rows
    }
    
    private subscript(index: Int) -> CountColumn {
        return columns[index]
    }
    
    public func makeOutline(row: Int, col: Int) -> NSAttributedString {
        if row == 0 {
            return NSAttributedString(string: self[col].日付.dayWeekString)
        }
        let subIndex = (row-1) % labelCount
        let type = (row-1)/labelCount
        return self[col].makeOutline(row: type, index: subIndex)
    }
    
    public func detailOrders(row: Int, col: Int) -> DetailInfo? {
        if row == 0 { return nil }
        
        let subIndex = (row-1) % labelCount
        let type = (row-1)/labelCount
        
        guard var info = self[col].detailOrder(row:type, index:subIndex) else { return nil }
        info.after = col
        return info
    }
}

public struct DetailInfo {
    public var type = ""
    public var work = ""
    public var mark = ""
    public var limit: Day = Day()
    public var date: Day = Day()
    public var after: Int = 0
    public var 工程: 工程型?
    public var 伝票種類: 伝票種類型 = .箱文字
    public var orders: [指示書型] = []
    
    public var 表示モード: ProgressChecker表示モード型 {
        switch self.伝票種類 {
        case .エッチング, .切文字, .加工, .外注, .校正, .赤伝:
            return .通常モード
        case .箱文字:
            guard let process = self.工程 else { return .通常モード }
            switch process {
            case .営業, .管理, .原稿, .入力, .出力, .レーザー, .照合検査, .立ち上がり, .立ち上がり_溶接:
                return .箱文字前工程モード
            default:
                return .通常モード
            }
        }
    }
}

// MARK: - UserDEfaults
let isShowTotalKey = "isShowTotal"
let isShowCompleteKey = "isShowComplete"
let isShowHoldingKey = "isShowHolding"
let isShowWaitingKey = "isShowWaiting"
let isShowNewKey = "isShowNew"
let isShow0CellKey = "isShow0Cell"
let processNameKey = "processName"

extension UserDefaults {
    /// ProgressChecker関連のデフォルト値
    public func registerProgressCheckerDefaults() {
        let dic: [String : Any] = [
            isShowTotalKey : true,
            isShowCompleteKey : true,
            isShowHoldingKey : true,
            isShowWaitingKey : true,
            isShowNewKey : true,
            isShow0CellKey : true
        ]
        self.register(defaults: dic)
    }
    
    public var processName: String {
        get { return self.string(forKey: processNameKey) ?? "" }
        set { self.set(newValue, forKey: processNameKey) }
    }
    public var isShowTotal: Bool {
        get { return self.bool(forKey: isShowTotalKey) }
        set { self.set(newValue, forKey: isShowTotalKey) }
    }
    public var isShowComplete: Bool {
        get { return self.bool(forKey: isShowCompleteKey) }
        set { self.set(newValue, forKey: isShowCompleteKey) }
    }
    public var isShowHolding: Bool {
        get { return self.bool(forKey: isShowHoldingKey) }
        set { self.set(newValue, forKey: isShowHoldingKey) }
    }
    public var isShowWaiting: Bool {
        get { return self.bool(forKey: isShowWaitingKey) }
        set { self.set(newValue, forKey: isShowWaitingKey) }
    }
    public var isShowNew: Bool {
        get { return self.bool(forKey: isShowNewKey) }
        set { self.set(newValue, forKey: isShowNewKey) }
    }
    public var isShow0Cell: Bool {
        get { return self.bool(forKey: isShow0CellKey) }
        set { self.set(newValue, forKey: isShow0CellKey) }
    }
    public var noFormingProcess: Bool {
        get { return self.bool(forKey: "noFormingProcess") }
        set { self.set(newValue, forKey: "noFormingProcess") }
    }
    public var noLaserProcess: Bool {
        get { return self.bool(forKey: "noLaserProcess") }
        set { self.set(newValue, forKey: "noLaserProcess") }
    }
    public var noOutputProcess: Bool {
        get { return self.bool(forKey: "noOutputProcess") }
        set { self.set(newValue, forKey: "noOutputProcess") }
    }
    public var noPrepareProcess: Bool {
        get { return self.bool(forKey: "noPrepareProcess") }
        set { self.set(newValue, forKey: "noPrepareProcess") }
    }
    public var noRutaProcess: Bool {
        get { return self.bool(forKey: "noRutaProcess") }
        set { self.set(newValue, forKey: "noRutaProcess") }
    }
    
    public func hasTargetTag() -> Bool {
        return self.object(forKey: "targetTag") != nil
    }
    public var targetTag: Int {
        get { self.integer(forKey: "targetTag") }
        set { self.set(newValue, forKey: "targetTag") }
    }
}
