//
//  TextReader.swift
//  NCEngine
//
//  Created by 四熊 泰之 on H26/08/13.
//  Copyright (c) 平成26年 四熊 泰之. All rights reserved.
//

import Foundation

public class TextReader {
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
        guard let text = String(bytes: data, encoding: encoding) else {
            throw TextReaderError.invalidStringCoding
        }
        self.init(text)
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
