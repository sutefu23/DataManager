//
//  送り状エラー.swift
//  DataManager
//
//  Created by manager on R 3/06/15.
//

import Foundation

public struct 送り状エラー型 {
    public let 送り状: 送状型
    public let エラー: Error
    
    public init(送り状: 送状型, エラー: Error) {
        self.送り状 = 送り状
        self.エラー = エラー
    }
}

public extension Sequence where Element == 送り状エラー型 {
    func export送り状エラーCSV(to url: URL) throws {
        let generator = TableGenerator<送り状エラー型>()
            .day("出荷納期", .monthDayJ) { $0.送り状.出荷納期 }
            .string("伝票番号") { $0.送り状.伝票番号?.整数文字列 }
            .string("管理番号") { $0.送り状.管理番号 }
            .string("エラー") { $0.エラー.localizedDescription }
            .string("営業") { $0.送り状.指示書?.担当者1?.社員名称 }
            .string("社名") { $0.送り状.指示書?.社名 }
            .string("品名") { $0.送り状.品名 }
            .string("届け先") { $0.送り状.届け先受取者名 }
            .day("着指定日", .monthDayJ) { $0.送り状.着指定日 }
        try generator.write(self, format: .excel(header: false), to: url, concurrent: true)
    }
}
