//
//  TextReader.swift
//  NCEngine
//
//  Created by 四熊 泰之 on H26/08/13.
//  Copyright (c) 平成26年 四熊 泰之. All rights reserved.
//

import Foundation

public final class TextReader {
    public enum TextReaderError: LocalizedError {
        /// データを指定したエンコードで文字列かできない
        case invalidStringCoding
        
        public var errorDescription: String? {
            switch self {
            case .invalidStringCoding:
                return "データを指定したエンコードで文字列化できない"
            }
        }
    }
    
// MARK: 初期化
    public init(_ strings: [String] = [String]()) {
        self.lines = strings.isEmpty ? [""] : strings
        self.nextIndex = 0
    }
    
    public convenience init(_ text: String) {
        var lines: [String] = []
        lines.reserveCapacity(87300) // およそ2MB
        text.enumerateLines { (line, _) in
            lines.append(line)
        }
        lines.append("")
        
        self.init(lines)
    }
    
    public convenience init(data: Data, encoding: String.Encoding) throws {
        if let text = String(bytes: data, encoding: encoding) {
            self.init(text)
        } else {
            let lines = data.lossyStrings(encoding: encoding)
            self.init(lines)
        }
    }
    
    public convenience init(url: URL, encoding: String.Encoding) throws {
        let data = try Data(contentsOf: url)

        try self.init(data: data, encoding: encoding)
        self.url = url
    }
    
    // MARK: プロパティ
    public var url: URL? = nil
    
    // MARK: 関数
    public func nextLine() -> String? {
        if let cache = nextLineCache {
            nextLineCache = nil
            return cache
        }
        if nextIndex < lines.count {
            let line = lines[nextIndex]
            nextIndex += 1
            return line
        } else {
            return nil
        }
    }

    public var isEmpty: Bool {
        nextLineCache == nil && !(nextIndex < lines.count)
    }
    
    private var nextLineCache: String? = nil

    public func insertNextLine(_ line: String) {
        guard let nextLine = self.nextLineCache else {
            self.nextLineCache = line
            return
        }
        self.nextLineCache = line
        
        if nextIndex < lines.count {
            if nextIndex > 0 {
                nextIndex -= 1
                lines[nextIndex] = nextLine
            } else {
                lines.insert(nextLine, at: nextIndex)
            }
        } else {
            lines.append(nextLine)
        }
    }
    
    // MARK: 実装
    public private(set) var lines: [String]
    private var nextIndex: Int
}

extension Data {
    private func splitLn() -> [Data] {
        var result: [Data] = []
        var current = Data()
        var hasPrev10 = false
        var hasPrev13 = false
        
        for ch in self {
            if ch == 13 {
                if hasPrev13 {
                    result.append(current)
                    current = Data()
                    hasPrev10 = false
                } else if hasPrev10 {
                    hasPrev13 = false
                } else {
                    result.append(current)
                    current = Data()
                    hasPrev13 = true
                }
            } else if ch == 10 {
                if hasPrev10 {
                    result.append(Data())
                    hasPrev13 = false
                } else if hasPrev13 {
                    hasPrev10 = false
                } else {
                    result.append(current)
                    current = Data()
                    hasPrev10 = true
                }
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty || !result.isEmpty { current.append(current) }
        return result
    }
    
    private func decodeLossy(encoding: String.Encoding) -> String {
        let count = self.count
        if count == 0 { return "" }
        if let str = String(data: self, encoding: encoding) { return str }
        if encoding == .shiftJIS {
            var data = self
            for (key, value) in collectMap {
                if let range = data.searchRange(of: key) {
                    data.replaceSubrange(range, with: value)
                }
            }
            if let str = String(data: data, encoding: encoding) {
                return str
            }
        }
        return self[1..<count].decodeLossy(encoding: encoding)
    }
    
    func lossyStrings(encoding: String.Encoding) -> [String] {
        let datas = self.splitLn()
        return datas.map { $0.decodeLossy(encoding: encoding) }
    }

    private func searchRange(of data: Data) -> Range<Int>? {
        let firstByte = data[0] // nilだとロジックエラー
        let endIndex = self.count - data.count
        if endIndex < 0 { return nil }
        for index in 0...endIndex {
            if self[index] != firstByte { continue }
            let range = index..<index+data.count
            if self[range] == data {
                return range
            }
        }
        return nil
    }
}
/// 壊れたコード->修正後のコード
private let collectMap: [Data: Data] = [
    Data([131, 37, 37, 100, 91, 131]) : Data([131, 125, 129, 91, 131]), // マーク-[78]
    Data([131, 37, 37, 100, 98, 131]) : Data([131, 125, 131, 98, 131]), // マット-[103
    Data([147, 37, 37, 100, 148]) : Data([147, 251, 148]), // 乳半-[188]
]
/*
let errorData2 = Data([131, 65, 131, 78, 131, 138, 131, 139, 32, 141, 149, 131, 37, 37, 100, 98, 131, 103, 32, 51, 46, 48, 116, 32]) // アクリル黒マット 3.0t
let errorData3 = Data([131, 65, 131, 78, 131, 138, 131, 139, 32, 51, 46, 48, 116, 32, 147, 37, 37, 100, 148, 188]) // アクリル xt 乳半
*/
