//
//  板加工在庫.swift
//  DataManager
//
//  Created by manager on 2020/06/04.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

struct 板加工在庫型 {
    let 名称: String
    let 資材: 資材型
    let 面積: Double
    let ソート順: Double
    
    init?(_ line: String, order: Double?) {
        let digs = line.toJapaneseNormal.csvColumns
        guard digs.count >= 3 else { return nil }
        let name = digs[0]
        if name.isEmpty { return nil }
        guard let item = try? 資材キャッシュ型.shared.キャッシュ資材(図番: 図番型(digs[1])) else { return nil }
        guard let area = Double(digs[2]), area > 0 else { return nil }
        let order = order ?? 0
        self.名称 = String(name)
        self.資材 = item
        self.面積 = area
        self.ソート順 = (digs.count > 3) ? (Double(digs[3]) ?? order) : order
    }
}

let 板加工在庫一覧: [板加工在庫型] = {
    let bundle = Bundle.dataManagerBundle
    let url = bundle.url(forResource: "ItaKakouZaikoIchiran", withExtension: "csv")!
    let text = try! String(contentsOf: url, encoding: .utf8)
    var list: [板加工在庫型] = []
    let step: Double = 0.0001
    var order: Double = -0.0001
    text.enumerateLines { (line, _) in
        guard let object = 板加工在庫型(line, order: order) else { return }
        list.append(object)
        order -= step
    }
    return list
}()

let 板加工在庫マップ: [String: 板加工在庫型] = {
   var map = [String: 板加工在庫型]()
    for object in 板加工在庫一覧 {
        map[object.名称] = object
    }
    return map
}()
