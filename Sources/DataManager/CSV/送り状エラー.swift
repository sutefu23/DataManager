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
    
    public init?(_ order: 送状型, senders: [福山ご依頼主型]?) {
        func standardError() -> 送状CheckError? {
            guard let source = order.指示書 else { return nil }
            if !source.isActive { return .指示書が不正 }
            if let 着指定日 = order.着指定日, 着指定日 <= min(Day(), source.出荷納期) { return .着指定日が不正 } // 着指定日が早すぎる
            return nil
        }
        if let error = standardError() {
            self.init(送り状: order, エラー: error)
            return
        }
        switch order.運送会社 {
        case .ヤマト:
            self.init(ヤマト送状: order)
        case .福山:
            guard let senders = senders else { return nil }
            self.init(福山送り状: order, 福山ご依頼主一覧: senders)
        default:
            return nil
        }
    }
    
    init?(ヤマト送状 order: 送状型) {
        let error: 送状CheckError
        if order.依頼主郵便番号.isEmpty { error = .送り主郵便番号が空欄 } else
        if order.依頼主電話番号.isEmpty { error = .送り主電話番号が空欄 } else
        if order.依頼主住所1.isEmpty { error = .送り主住所1が空欄 } else
        if order.届け先郵便番号.isEmpty { error = .届け先郵便番号が空欄 } else
        if order.届け先電話番号.isEmpty { error = .届け先電話番号が空欄 } else
        if order.届け先住所1.isEmpty { error = .届け先住所1が空欄 } else
        if order.着指定日 == nil { error = .着指定日が未入力 } else
        if order.依頼主住所1.shiftJISBytes > 32 { error = .送り主住所1の文字数が多い } else
        if order.依頼主住所2.shiftJISBytes > 32 { error = .送り主住所2の文字数が多い } else
        if order.依頼主受取者名.shiftJISBytes > 32 { error = .送り主名称の文字数が多い } else
        if order.届け先住所1.shiftJISBytes > 32 { error = .届け先住所1の文字数が多い } else
        if order.届け先住所2.shiftJISBytes > 32 { error = .届け先住所2の文字数が多い } else
        if order.届け先住所3.shiftJISBytes > 32 { error = .届け先住所3の文字数が多い } else
        if order.届け先受取者名.shiftJISBytes > 32 { error = .届け先名称の文字数が多い } else
        if order.品名.shiftJISBytes > 98 { error = .品名の文字数が多い } else
        if order.記事.shiftJISBytes > 20 { error = .記事の文字数が多い } else { return nil }
        self.init(送り状: order, エラー: error)
    }
    
    init?(福山送り状 order: 送状型, 福山ご依頼主一覧: [福山ご依頼主型]) {
        let error: 送状CheckError
        if order.福山依頼主コード.isEmpty { error = 送状CheckError.福山依頼主コードが空欄 } else
        if 福山ご依頼主一覧.findOld依頼主(住所: order.依頼主住所) != nil { error = 送状CheckError.古い住所で出力 } else { return nil }
        self.init(送り状: order, エラー: error)
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

extension Sequence where Element == 送状型 {
    public func check送り状(senders: [福山ご依頼主型]?) -> (ok: [送状型], ng: [送り状エラー型]) {
        var ok: [送状型] = []
        var ng: [送り状エラー型] = []
        for order in self {
            if let error = 送り状エラー型(order, senders: senders) {
                ng.append(error)
            } else {
                ok.append(order)
            }
        }
        return (ok, ng)
    }
}
