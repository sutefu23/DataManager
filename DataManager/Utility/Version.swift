//
//  Version.swift
//  DataManager
//
//  Created by manager on 2019/11/08.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public class BundleVersion : Comparable, Hashable {
    let versions : [Int]
    public let simpleText : String
    public let buildNumber : Int?
    public let fullText : String
    
    public convenience init?(_ bundle:Bundle = Bundle.main) {
        guard let dic = bundle.infoDictionary else { return nil }
        guard let string = dic["CFBundleShortVersionString"] as? String, !string.isEmpty else { return nil }
        guard let string2 = dic["CFBundleVersion"] as? String, !string.isEmpty else { return nil }
        self.init(string, string2)
    }
    
    init(_ versionText:String, _ buildText:String) {
        var versions : [Int] = []
        let digits = versionText.split(separator: ".")
        for digit in digits {
            let value = Int(digit) ?? 0
            versions.append(value)
        }
        self.versions = versions
        self.buildNumber = Int(buildText)
        self.simpleText = versionText
        self.fullText = (buildNumber == nil) ? versionText : "\(versionText) (build \(buildText))"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(versions)
    }
    
    public static func == (left:BundleVersion, right:BundleVersion) -> Bool {
        if let leftBuild = left.buildNumber, let rightBuild = right.buildNumber { return leftBuild == rightBuild }
        return left.versions == right.versions
    }
    
    public static func < (left:BundleVersion, right:BundleVersion) -> Bool {
        if let leftBuild = left.buildNumber, let rightBuild = right.buildNumber { return leftBuild < rightBuild }
        for (leftValue, rightValue) in zip(left.versions, right.versions) {
            if leftValue != rightValue {
                return leftValue < rightValue
            }
        }
        return left.versions.count < right.versions.count
    }
    
    public var simpleVersion : BundleVersion {
        return BundleVersion(self.simpleText, "")
    }
}
