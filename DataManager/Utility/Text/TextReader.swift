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
            for (key, value) in collectMap {
                guard key.count <= count && key == self[..<key.count] else { continue }
                let data = value + self[key.count...]
                return data.decodeLossy(encoding: encoding)
            }
        }
        return self[1..<count].decodeLossy(encoding: encoding)
    }
    
    func lossyStrings(encoding: String.Encoding) -> [String] {
        let datas = self.splitLn()
        return datas.map { $0.decodeLossy(encoding: encoding) }
    }
    
    func hasNoPatchError() -> Bool {
        let count = self.count
        if count == 0 { return true }
        if String(data: self, encoding: .shiftJIS) != nil { return true }
        for (key, value) in collectMap {
            guard key.count <= count && key == self[..<key.count] else { continue }
            let data = value + self[key.count...]
            return String(data: data, encoding: .shiftJIS) != nil
        }
        return false
    }

    /// 手当出来ないShiftJISのエラーがある
    public var hasUnknownShiftJIS: Bool {
        if String(data: self, encoding: .shiftJIS) != nil { return true }
        let datas = self.splitLn()
        return datas.contains { $0.hasNoPatchError() }
    }

}
/// 壊れたコード->修正後のコード
private let collectMap: [Data: Data] = [
    Data([131, 37, 37, 100, 91]) : Data([131, 125, 129, 91])
]
