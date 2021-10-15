//
//  進捗集計.swift
//  DataManager
//
//  Created by manager on 2020/11/05.
//

import Foundation

#if os(tvOS)
#elseif os(iOS) || os(macOS)
public func output仕掛かり始め(チェック日 range: ClosedRange<Day>, button: DMButton) {
    do {
        let source: [進捗型]
        source = try 進捗型.find(登録期間: range, 作業種別: .作直)
        let numbers = Set<伝票番号型>(source.map { $0.伝票番号 } )
        let orders = numbers.compactMap { $0.キャッシュ指示書 }.sorted { $0.伝票番号 < $1.伝票番号 }
        let pairs: [(order: 指示書型, progress: 進捗型, source: 工程型?)] = orders.concurrentCompactMap {
            guard let progress = $0.進捗一覧.first(where: { $0.作業種別 == .作直 && $0.作業内容 != .仕掛  } ), range.contains(progress.登録日) else { return nil }
            let source = $0.進捗一覧.search作直し仕掛かり工程(作直開始日時: progress.登録日時)
            return ($0, progress, source)
        }
        let gen = TableGenerator<(order: 指示書型, progress: 進捗型, source: 工程型?)>()
            .integer("伝票番号") { $0.order.伝票番号.整数値 }
            .string("伝票種類") { $0.order.伝票種類.description }
            .string("仕掛工程") { $0.source?.description }
            .string("先頭工程") { $0.progress.工程.description }
            .day("先頭日", .yearMonthDay) { $0.progress.登録日 }
            .time("先頭時間") { $0.progress.登録時間 }
            .string("登録者") { $0.progress.社員名称 }
            .string("仕掛~作直完了(分)") {
                guard let (isOk, interval) = $0.order.作り直しリードタイム else { return nil }
                let str = String(Int(interval/60))
                return isOk ? str : str+"?"
            }
        let filename: String
        if range.lowerBound == range.upperBound {
            filename = "仕掛り始め一覧\(range.lowerBound.monthDayJString).csv"
        } else {
            filename = "仕掛り始め一覧\(range.lowerBound.monthDayJString)~\(range.upperBound.monthDayJString).csv"
        }
        try gen.share(pairs, format: .excel(header: true), title: filename, shareButton: button)
    } catch {
        error.showAlert()
    }
}
#endif
    
