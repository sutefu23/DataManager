//
//  ChangeLog.swift
//  NCEngine
//
//  Created by 四熊泰之 on R 2/01/28.
//  Copyright © Reiwa 2 四熊 泰之. All rights reserved.
//

import Foundation

/// 更新履歴ファイルのファイル名
let histryFileName = "history"
/// 更新履歴ファイルの拡張子
let histryFileExtension = "txt"

/// 更新履歴を作成する
func makeHistory(text: String) -> [(version: Version, text: [String])] {
    var map = [Version: [String]]()
    var version: Version? = nil
    text.enumerateLines { (line, _) in
        if line.hasPrefix("・") {
            let text = String(line.dropFirst(1))
            guard let version = version else { return }
            if var current = map[version] {
                current.append(text)
                map[version] = current
            } else {
                map[version] = [text]
            }
        } else if !line.isEmpty {
            version = Version(line, "")
        }
    }
    return map.sorted { $0.key > $1.key }.map { (version: $0.key, text:$0.value) }
}

final class History {
    let history: [(version: Version, text: [String])]

    convenience init?() {
        self.init(Bundle.main)
    }
    convenience init?(_ url: URL) {
        guard let bundle = Bundle(url: url) else { return nil }
        self.init(bundle)
    }
    
    init?(_ bundle: Bundle) {
        guard let url = bundle.url(forResource: histryFileName, withExtension: histryFileExtension), let text = (try? String(contentsOf: url, encoding: .utf8)) else { return nil }
        self.history = makeHistory(text: text)
    }
    func changeLog(from fromVersion: Version) -> [String] {
        var changeLog: [String] = []
        for (version, text) in self.history where version > fromVersion {
            for line in text {
                changeLog.append(line)
            }
        }
        return changeLog
    }
    func history(from fromVersion: Version) -> [(version: String, changeList: [String])] {
        var history: [(version: String, changeList: [String])] = []
        for (version, text) in self.history where version >= fromVersion {
            history.append((version.fullText, text))
        }
        return history
    }

    func history(greaterFrom fromVersion: Version) -> [(version: String, changeList: [String])] {
        var history: [(version: String, changeList: [String])] = []
        for (version, text) in self.history where version > fromVersion {
            history.append((version.fullText, text))
        }
        return history
    }
}

#if os(iOS)
#elseif os(macOS)
import Cocoa

/// 標準的な更新履歴コントローラー
public class HistoryViewController: NSViewController {
    @IBOutlet public var textView: NSTextView!
    
    public override func viewDidLoad() {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: histryFileName, withExtension: histryFileExtension), let text = (try? String(contentsOf: url, encoding: .utf8)) else { return }
        textView.string = text
    }
}

#endif
