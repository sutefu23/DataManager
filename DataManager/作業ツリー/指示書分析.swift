//
//  指示書分析.swift
//  DataManager
//
//  Created by manager on 2019/09/02.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 分析エラー型 : Error {
    case 処理不能(進捗型)
}

public class 指示書工程分析器型 {
    public let order : 指示書型
    var lines : [工程ライン型]
    
    var errors : [分析エラー型] = []

    init(_ order:指示書型) throws {
        self.order = order
        self.lines = [工程ライン型(.メイン, 管理分析器型())]
        try prepareLines()
    }
    
    func prepareLines() throws {
        for progress in self.order.進捗一覧 {
            var targetLine : (line:工程ライン型, state:工程ライン型.State)? = nil
            for line in lines {
                if let state = line.processor.accept(progress: progress, line: line, context: self) {
                    if let target = targetLine {
                        if state.priority >= target.state.priority {
                            targetLine = (line, state)
                        }
                    } else {
                        targetLine = (line, state)
                    }
                }
            }
            if let (line, _) = targetLine {
                do {
                    if let (next, target) = try line.processor.process(progress: progress, line: line, context: self) {
                        prepareLine(target: target, analyzer: next)
                    }
                } catch let error as 分析エラー型 {
                    self.errors.append(error)
                } catch {
                    self.errors.append(.処理不能(progress))
                }
            } else {
                self.errors.append(.処理不能(progress))
            }
        }
    }
    
    func prepareLine(target:工程ライン型.Target, analyzer:工程分析器型) {
        for line in lines {
            if line.target == target {
                line.processor = analyzer
                return
            }
        }
        let line = 工程ライン型(target, analyzer)
        lines.append(line)
    }
}

public class 工程ライン型 {
    enum State {
        case 通常
        case 差し戻し(from:工程型)
        
        var priority : Int {
            switch self {
            case .通常:
                return 2
            case .差し戻し:
                return 1
            }
        }
    }
    enum Target {
        case メイン
        case 原稿
        case タレパン
        case 外注
        case 塗装
        case 研磨
        case エッチング
    }
    public var lines : [工程図工程型] = []
    var state : State = .通常
    var target : Target
    var processor : 工程分析器型
    
    init(_ target:Target, _ processor:工程分析器型) {
        self.target = target
        self.processor = processor
    }
}

protocol 工程分析器型 {
    func process(progress:進捗型, line:工程ライン型, context:指示書工程分析器型) throws -> (next:工程分析器型, target:工程ライン型.Target)?
    func accept(progress:進捗型, line:工程ライン型, context:指示書工程分析器型) -> 工程ライン型.State?
}

// MARK: - 管理
class 管理分析器型 : 工程分析器型 {
    func process(progress:進捗型, line:工程ライン型, context:指示書工程分析器型) throws -> (next:工程分析器型, target:工程ライン型.Target)? {
        return nil
    }
    func accept(progress:進捗型, line:工程ライン型, context:指示書工程分析器型) -> 工程ライン型.State? {
        return nil
    }
}
