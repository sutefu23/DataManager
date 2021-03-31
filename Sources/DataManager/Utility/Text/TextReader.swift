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
    public init(_ strings: [String] = []) {
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
    func lossyStrings(encoding: String.Encoding) -> [String] {
        var rangeList: [Range<Data.Index>] = []
        let baseIndex = self.startIndex
        var fromIndex = baseIndex
        var tailCode: UInt8? = nil
        
        for (offset, ch) in self.enumerated() {
            if ch == 13 || ch == 10 {
                if let prev = tailCode {
                    if ch != prev { // crlf or lfcr完成
                        tailCode = nil
                    } else { // crcrまたはlflf。間に空行が入る
                        rangeList.append(fromIndex ..< fromIndex)
                    }
                } else {
                    tailCode = ch
                    rangeList.append(fromIndex ..< baseIndex + offset)
                }
                fromIndex = baseIndex + offset + 1
            }
        }
        if fromIndex < self.endIndex {
            rangeList.append(fromIndex ..< self.endIndex)
        }
        var result = [String](repeating: "", count: rangeList.count)
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: rangeList.count) {
            let range = rangeList[$0]
            let data = self[range]
            let string = data.decodeLossy(encoding: encoding)
            lock.lock()
            result[$0] = string
            lock.unlock()
        }
        return result
    }

    private func decodeLossy(encoding: String.Encoding) -> String {
        if self.isEmpty { return "" }
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
        let nextStartIndex = self.index(after: self.startIndex)
        return self[nextStartIndex..<self.endIndex].decodeLossy(encoding: encoding)
    }
    
    private func searchRange(of data: Data) -> Range<Int>? {
        guard let firstByte = data.first else { return nil }
        let dataCount = data.count
        let endIndex = self.endIndex - dataCount
        let startIndex = self.startIndex
        if endIndex < startIndex { return nil }
        for index in startIndex...endIndex {
            if self[index] != firstByte { continue }
            let upperIndex = index + dataCount
            assert(upperIndex <= self.endIndex)
            let range = index..<upperIndex
            if self[range] == data {
                return range
            }
        }
        return nil
    }
}
/// 壊れたコード->修正後のコード
private let collectMap: [Data: Data] = [
    // 5byte
    Data([147, 37, 37, 100, 148]) : Data([147, 251, 148]), // 乳半-[188]
    // 6byte
    Data([144, 230, 149, 37, 37, 100]): Data([144, 230, 0x95, 0xfb]), // 先[方]
    Data([131, 37, 37, 100, 91, 131]) : Data([131, 125, 129, 91, 131]), // マーク-[78]
    Data([131, 37, 37, 100, 98, 131]) : Data([131, 125, 131, 98, 131]), // マット-[103]
]
