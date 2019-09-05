//
//  作業.swift
//  DataManager
//
//  Created by manager on 2019/09/03.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public enum 作業種類型 {
    case 通常
    case 保留
    case 校正
}

public class 作業型 {
    public var 作業種類 : 作業種類型
    public var 工程 : 工程型
    public var 開始日時 : Date
    public var 完了日時 : Date
    public var 作業者 : 社員型
    public var 伝票番号 : Int

    init?(_ progress:進捗型? = nil, type:作業種類型 = .通常, state:工程型? = nil, from:Date? = nil, to:Date? = nil, worker: 社員型? = nil, 伝票番号 number:Int? = nil) {
        self.作業種類 = type
        guard let worker = worker ?? progress?.作業者 else { return nil }
        guard let state = state ?? progress?.工程 else { return nil }
        guard let st = from ?? progress?.登録日時 else { return nil }
        guard let ed = to ?? progress?.登録日時 else { return nil }
        guard let number = number ?? progress?.伝票番号 else { return nil }

        self.作業者 = worker
        self.工程 = state
        if st > ed { return nil }
        self.開始日時 = st
        self.完了日時 = ed
        self.伝票番号 = number
    }
    
    var 工程社員 : 工程社員型 {
        return 工程社員型(工程: self.工程, 社員: self.作業者)
    }
    
    func isCross(to work:作業型) -> Bool {
        if work.完了日時 < self.開始日時 || self.完了日時 < work.開始日時 { return false }
        return true
    }
    
    func contains(_ work:作業型) -> Bool {
        return self.開始日時 <= work.開始日時 && work.完了日時 <= self.完了日時
    }
}
