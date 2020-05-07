//
//  URL.swift
//  DataManager
//
//  Created by manager on 2019/03/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public let ダウンロードURL: URL = {
    let fm = FileManager.default
    let desktopURL = try! fm.url(for: FileManager.SearchPathDirectory.downloadsDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
    return desktopURL
}()


public let デスクトップURL: URL = {
    let fm = FileManager.default
    let desktopURL = try! fm.url(for: FileManager.SearchPathDirectory.desktopDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
    return desktopURL
}()

public let 生産管理集計URL: URL = {
    let fm = FileManager.default
    let url = デスクトップURL.appendingPathComponent("生産管理集計", isDirectory: true)
    try? fm.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
    return url
}()

extension URL {
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
    public func subComponents(from: URL) -> [String]? {
        let base = from.standardizedFileURL.pathComponents
        let sub = self.standardizedFileURL.pathComponents
        if base.count > sub.count { return nil }
        if !sub.prefix(base.count).elementsEqual(base) { return nil }
        return [String](sub.suffix(sub.count - base.count))
    }

    public var contentModificationDate: Date? {
        let res = try? resourceValues(forKeys: [.contentModificationDateKey])
        let date = res?.contentModificationDate
        return date
    }

    public var contentCreationDate: Date? {
        let res = try? resourceValues(forKeys: [.creationDateKey])
        let date = res?.contentModificationDate
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
}
