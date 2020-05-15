//
//  Writer.swift
//  NCEngine
//
//  Created by 四熊 泰之 on H26/08/13.
//  Copyright (c) 平成26年 四熊 泰之. All rights reserved.
//

import Foundation

open class TextWriter: TextOutputStream {
    private var strings: [String] = [""]

    public init() {}
    
    public var isLineHead: Bool {
        let lastLine = strings.last!
        return lastLine.isEmpty
    }
    
    // MARK: - 出力結果
    public var lines: [String] {
        let lastIndex = self.strings.count-1
        assert(lastIndex >= 0)
        let lastLine = self.strings[lastIndex]
        if lastLine.isEmpty == false {
            return self.strings
        } else {
            return Array(self.strings[0..<lastIndex])
        }
    }
    
    // MARK: 関数
    public func write(_ string: String) { appendText(string) }
    
    public func appendText(_ text: String) {
        var line = strings.last!
        strings.removeLast()
        
        for ch in text {
            if ch == Character("\n") || ch == Character("\r\n") || ch == Character("\r") {
                strings.append(line)
                line = ""
            } else {
                line.append(ch)
            }
        }
        strings.append(line)
    }
    
    public func appendLines(_ lines: String...) {
        for line in lines {
            appendLine(line)
        }
    }

    public func appendLines(_ lines: [String]) {
        for line in lines {
            appendLine(line)
        }
    }

    @inlinable public func appendCharacter(_ character: Character, count: Int = 1) {
        assert(count >= 0)
        if count <= 0 { return }
        let string = String(repeating: character, count: count)
        appendString(string)
    }
    
    @inlinable public func appendLine(_ line: String) {
        appendString(line)
        appendLineEnd()
    }
    
    public func dataWithEncoding(encoding: String.Encoding = String.Encoding.ascii, lineEndType: LineEndType = .crlf) -> Data {
        let crlf: Data = lineEndType.data
        var data = Data()
        let lastIndex = lines.count - 1
        for (index, line) in lines.enumerated() {
            guard let lineData = line.data(using: encoding, allowLossyConversion: true) else { continue }
            data.append(lineData)
            if index != lastIndex { data.append(crlf) }
        }
        return data
    }

    public var text: String {
        return lines.joined(separator: "\n")
    }
    // 以下サブクラスで実装
    public func appendLineEnd() {
        strings.append("")
    }
    
    public func appendString(_ string: String) {
        let index = strings.count - 1
        assert(index >= 0)
        strings[index] = strings[index] + string
    }
    
    public func removeAtIndex(_ index: Int) {
        strings.remove(at: index)
    }
}

public enum LineEndType: Int, Codable {
    case cr = 1
    case lf = 2
    case crlf = 4
    
    var data: Data {
        switch self {
        case .cr:
            return Data([13])
        case .lf:
            return Data([10])
        case .crlf:
            return Data([13, 10])
        }
    }

}
