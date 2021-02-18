//
//  Version.swift
//  DataManager
//
//  Created by manager on 2019/11/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public final class Version: Comparable, Hashable, Codable {
    public var simpleText: String { return self.versionText }
    public lazy var buildNumber: Int? = { Int(self.buildText) }()
    public lazy var fullText: String = {
        (self.buildNumber == nil) ? self.versionText : "\(self.versionText) (build \(self.buildText))"
    }()

    private(set) lazy var versions: [Int] = {
        let versions = versionText.split(separator: ".").map { Int($0) ?? 0 }
        return versions
    }()

    // MARK: -
    private var versionText: String
    private var buildText: String

    public convenience init?(_ bundle: Bundle = Bundle.main) {
        guard let dic = bundle.infoDictionary else { return nil }
        guard case let string as String = dic["CFBundleShortVersionString"], !string.isEmpty else { return nil }
        guard case let string2 as String = dic["CFBundleVersion"], !string.isEmpty else { return nil }
        self.init(string, string2)
    }

    public convenience init(_ versionText: String) {
        self.init(versionText, "")
    }
    
    public init(_ versionText: String, _ buildText: String) {
        self.versionText = versionText
        self.buildText = buildText
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(versions)
        hasher.combine(buildNumber)
    }
    
    public static func == (left: Version, right: Version) -> Bool {
        if let leftBuild = left.buildNumber, let rightBuild = right.buildNumber { return leftBuild == rightBuild }
        return left.versions == right.versions
    }
    
    public static func < (left: Version, right: Version) -> Bool {
        if let leftBuild = left.buildNumber, let rightBuild = right.buildNumber { return leftBuild < rightBuild }
        for (leftValue, rightValue) in zip(left.versions, right.versions) {
            if leftValue != rightValue {
                return leftValue < rightValue
            }
        }
        return left.versions.count < right.versions.count
    }
    
    public var simpleVersion: Version {
        return Version(self.simpleText, "")
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case versionText, buildText
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let versionText = try values.decode(String.self, forKey: .versionText)
        let buildText = try values.decode(String.self, forKey: .buildText)
        self.init(versionText, buildText)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.versionText, forKey: .versionText)
        try container.encode(self.buildText, forKey: .buildText)
    }
}

// MARK: - バージョンチェック
#if os(Linux) || os(Windows)
#else
public func makeNewVersionInfo(newVersion: Version, currentVersion: Version) -> String {
    assert(currentVersion >= newVersion || currentVersion.buildNumber != newVersion.buildNumber)
    var info : String
    let isSimpleEqual = (currentVersion.simpleVersion == newVersion.simpleVersion)
    let app = DMApplication.shared
    let history = isSimpleEqual ? app.historyFromCurrentVersion : app.historyToNewVersion
    if history.isEmpty {
        if isSimpleEqual {
            info = "現在のバージョン：\(currentVersion.fullText) 新しいバージョン：\(newVersion.fullText)"
        } else {
            info = "現在のバージョン：\(currentVersion.simpleText) 新しいバージョン：\(newVersion.simpleText)"
        }
    } else {
        let verText = isSimpleEqual ? newVersion.fullText : newVersion.simpleText
        info = "新バージョン(\(verText))までの変更点\n"
        let showVer = history.count >= 2
        for (ver, list) in history {
            for (index, text) in list.enumerated() {
                if index == 0 {
                    if showVer { info += "\nバージョン \(ver)" }
                    info += "\n"
                }
                info += "・\(text)\n"
            }
        }
    }
    return info
}
#endif

#if os(iOS) || os(tvOS)
import UIKit

extension UILabel {
    public func setupFullVersionInfo() {
        if let ver = Version()?.fullText, !ver.isEmpty {
            self.text = "Ver " + ver
        } else {
            self.text = nil
        }
    }
    public func setupVersionInfo() {
        if let ver = Version()?.simpleText, !ver.isEmpty {
            self.text = "Ver " + ver
        } else {
            self.text = nil
        }
    }
}
#endif

// MARK: - バージョン記録
extension UserDefaults {
    /// UserDefaultsを保存したアプリのバージョン
    public var defaultsVersion: Version {
        get { self.json(forKey: "defaultsVersion" ) ?? Version("0.00") } // 記録がない場合バージョン0扱いとする
        set { self.setJson(object: newValue, forKey: "defaultsVersion") }
    }
}
