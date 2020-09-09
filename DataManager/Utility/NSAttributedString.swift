//
//  NSAttributedString.swift
//  DataManager
//
//  Created by manager on 2020/02/01.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
import CoreGraphics

#if os(tvOS)
import UIKit
public typealias FMColor = UIColor
public typealias FMFont = UIFont

#elseif os(macOS)
import AppKit
public typealias FMColor = NSColor
public typealias FMFont = NSFont

#elseif os(iOS)
import UIKit
public typealias FMColor = UIColor
public typealias FMFont = UIFont
#else

#endif

extension String {
    public func makeAttributedString(color: FMColor = FMColor.black, size: CGFloat = 12, fontName: String?) -> NSAttributedString {
        let font: FMFont
        if let fontName = fontName, let myFont = FMFont(name: fontName, size: 40) {
            font = myFont
        } else {
            font = FMFont.systemFont(ofSize: size)
        }
        return self.makeAttributedString(color: color, font: font)
    }

    public func makeAttributedString(color: FMColor = FMColor.black, font: DMFont) -> NSAttributedString {
        let attributes  = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
        return NSAttributedString(string: self, attributes: attributes)
    }
}

extension NSAttributedString {
    public convenience init(string: String, size: CGFloat, color: DMColor) {
        let font = DMFont.systemFont(ofSize: size)
        let attributes  = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
        self.init(string: string, attributes: attributes)
    }
    
    public static func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
        let str = NSMutableAttributedString(attributedString: left)
        str.append(right)
        return str
    }
    public static func += (left: inout NSAttributedString, right: NSAttributedString) {
        left = left + right
    }
}
