//
//  資材（オブジェ情報）.swift
//  DataManager
//
//  Created by manager on 2020/10/21.
//

import Foundation

public class オブジェ資材型 {
    init?(図番: 図番型, 面積: Double, 枚数: Int) {
        self.単位数 = Double(枚数)
        self.金額計算タイプ = .平面形状(area: 面積)
        guard let item = try? 資材型.find(図番: 図番) else { return nil }
        self.資材 = item
        let sheet = 資材板情報型(item)
        self.表示名 = "\(sheet.板厚)t \(sheet.材質)"
    }
    
    public let 表示名: String
    public let 資材: 資材型
    public let 金額計算タイプ: 金額計算タイプ型
    public let 単位数: Double
}
public class オブジェ仕様型 {
    public let 商品名: String
    public let 資材一覧: [オブジェ資材型]
    
    init(商品名: String, 資材一覧: [オブジェ資材型]) {
        self.商品名 = 商品名
        self.資材一覧 = 資材一覧
    }
}

public func searchオブジェ資材一覧(商品名: String) -> [オブジェ資材型]? {
    オブジェ仕様map[商品名]?.資材一覧
}

let オブジェ仕様map: [String: オブジェ仕様型] = {
    var map: [String: オブジェ仕様型] = [:]
    for item in オブジェ仕様一覧 {
        map[item.商品名] = item
    }
    return map
}()

// 一覧作成時の名前重複チェック用
private var nameSet = Set<String>()

public let オブジェ仕様一覧: [オブジェ仕様型] = {
    var ngname = Set<String>()
    let bundle = Bundle.dataManagerBundle
    let url = bundle.url(forResource: "オブジェ資材一覧", withExtension: "csv")!
    let text = try! TextReader(url: url, encoding: .utf8)
    var prevName: String = ""
    var source: [(name: String, item: オブジェ資材型)] = []
    loop:
    for line in text.lines {
        if line.isEmpty { continue }
        let line2 = line.toJapaneseNormal
        let base: Int
        let name: String
        let cols = line2.split(separator: ",")
        switch cols.count {
        case 4:
            base = 1
            name = String(cols[0])
            assert(nameSet.insert(name).inserted == true)
            prevName = name
        case 3:
            base = 0
            name = prevName
        default:
            continue loop
        }
        guard let area = Double(cols[base+1]),
              let count = Int(cols[base+2]),
              let item = オブジェ資材型(図番: String(cols[base]), 面積: area, 枚数: count)
        else {
            ngname.insert(name)
            continue
        }
        source.append((name, item))
    }
    var list: [オブジェ仕様型] = []
    let map: Dictionary<String, [オブジェ資材型]> = Dictionary(grouping: source) { $0.name }.mapValues { $0.map{ $0.item } }
    for (key, value) in map {
        if ngname.contains(key) { continue }
        let obj = オブジェ仕様型(商品名: key, 資材一覧: value)
        list.append(obj)
    }
    return list
}()
