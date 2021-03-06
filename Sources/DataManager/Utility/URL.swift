//
//  URL.swift
//  DataManager
//
//  Created by manager on 2019/03/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

/// よく使うディレクトリ
public enum CommonDirectory {
    case pm_statistics
    case desktopLog
    case desktop
    case applicationSupport
    case download
    
    public var url: URL {
        get throws {
            switch self {
            case .pm_statistics: return try 生産管理集計URL
            case .desktopLog: return try 動作履歴URL
            case .desktop: return try デスクトップURL
            case .download: return try ダウンロードURL
            case .applicationSupport: return try applicationSupportURL
            }
        }
    }
}

public var ダウンロードURL: URL {
    get throws {
        let fm = FileManager.default
        let desktopURL = try! fm.url(for: FileManager.SearchPathDirectory.downloadsDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        return desktopURL
    }
}

public var デスクトップURL: URL {
    get throws {
        let fm = FileManager.default
        let desktopURL = try fm.url(for: FileManager.SearchPathDirectory.desktopDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        return desktopURL
    }
}

public var applicationSupportURL: URL {
    get throws {
        let fm = FileManager.default
        let url = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(defaults.programName)
        try url.prepareDirectory()
        return url
    }
}

public var 生産管理集計URL: URL {
    get throws {
        let url = try デスクトップURL.appendingPathComponent("生産管理集計", isDirectory: true)
        try url.prepareDirectory()
        return url
    }
}

public var 動作履歴URL: URL {
    get throws {
        let url = try デスクトップURL.appendingPathComponent("動作履歴", isDirectory: true)
        try? url.prepareDirectory()
        return url
    }
}

let tmpSerial = SerialGenerator()

extension URL {
    /// 指定された拡張子の一時ファイルを作成する
    /// - Parameters:
    ///   - ext: 拡張子
    ///   - maxCount: この回数試して一時ファイルが作れないと失敗とする
    @available(OSX 10.12, *)
    public init?(temporaryFileWithExtension ext: String, maxCount: Int = 1000) {
        let dir = FileManager.default.temporaryDirectory
        var url: URL
        repeat {
            let serial = Int(tmpSerial.generateID())
            var name = UUID().uuidString + String(serial)
            if serial == maxCount { return nil }
            if !ext.isEmpty { name += "." + ext }
            url = dir.appendingPathComponent(name)
        } while url.isExists
        self = url
    }
    
    /// 存在するならtrueを返す
    public var isExists: Bool {
        let url = self.standardizedFileURL
        let path = url.path
        
        let fm = FileManager.default
        return fm.fileExists(atPath: path)
    }
    
    /// ディレクトリならtrueを返す
    public var isDirectory: Bool? {
        let resource = try? self.resourceValues(forKeys: [.isDirectoryKey])
        return resource?.isDirectory
    }
    
    /// ファイルを削除する
    public func remove() throws {
        let fm = FileManager.default
        try fm.removeItem(at: self)
    }

    /// このURLの示すディレクトリ下にchildが示すファイルを含むならtrue
    public func contains(child: URL) -> Bool {
        let base = self.standardizedFileURL.pathComponents
        let sub = child.standardizedFileURL.pathComponents
        if base.count > sub.count { return false }
        return sub.prefix(base.count).elementsEqual(base)
    }

    /// fromの示すディレクトリ下にこのURLが在る場合、from以下の要素を取り出す
    public func childComponents(from: URL) -> [String]? {
        let base = from.standardizedFileURL.pathComponents
        let sub = self.standardizedFileURL.pathComponents
        guard sub.prefix(base.count).elementsEqual(base) else { return nil }
        return [String](sub.suffix(sub.count - base.count))
    }
    
    public var contentModificationDate: Date? {
        get {
            do {
                var url = self
                url.removeCachedResourceValue(forKey: .contentModificationDateKey)
                let res = try url.resourceValues(forKeys: [.contentModificationDateKey])
                let date = res.contentModificationDate
                return date
            } catch {
                return nil
            }
        }
        set {
            var url = self
            url.removeCachedResourceValue(forKey: .contentModificationDateKey)
            guard var values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey]) else { return }
            values.contentModificationDate = newValue
            try? url.setResourceValues(values)
        }
    }
    
    public var contentCreationDate: Date? {
        var url = self
        url.removeCachedResourceValue(forKey: .creationDateKey)
        let res = try? url.resourceValues(forKeys: [.creationDateKey])
        let date = res?.creationDate
        return date
    }

    public var filename: String {
        return self.deletingPathExtension().lastPathComponent
    }
    
    public func replaceFilename(with newFilename: String) -> URL {
        let ext = pathExtension
        var url = self.deletingLastPathComponent()
        url.appendPathComponent(newFilename + "." + ext)
        return url
    }
    
    public func appendingPathComponents(_ components: [String]) -> URL {
        var url = self
        components.forEach { url.appendPathComponent($0) }
        return url
    }
    
    /// URLの一つ上のディレクトリを準備する
    public func prepareBaseDirectory() throws {
        let dir = self.deletingLastPathComponent()
        try dir.prepareDirectory()
    }

    /// URLのディレクトリを準備する
    public func prepareDirectory() throws {
        let fm = FileManager.default
        if self.isExists == false {
            try fm.createDirectory(at: self, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

#if os(macOS)
import Cocoa

extension URL {
    public func open() {
        let ws = NSWorkspace.shared
        ws.open(self)
    }
}

#endif
