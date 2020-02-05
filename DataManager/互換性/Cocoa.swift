//
//  Cocoa.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/02/06.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

#if os(iOS)
#elseif os(macOS)
import Cocoa

public typealias DMColor = NSColor
public typealias DMView = NSView
public typealias DMTextField = NSTextField

public typealias DMFont = NSFont
public typealias DMBezierPath = NSBezierPath
public typealias DMScreen = NSScreen

public typealias DMEvent = NSEvent

public typealias DMApplication = NSApplication

extension NSBezierPath {
    convenience init(polyline: inout [CGPoint]) {
        self.init()
        self.appendPoints(&polyline, count: polyline.count)
    }
}

#endif
