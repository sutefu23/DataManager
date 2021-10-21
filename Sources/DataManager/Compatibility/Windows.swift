//
//  Windows.swift
//  DataManager
//
//  Created by manager on 2021/10/15.
//

import Foundation

#if os(Windows)
import SwiftWin32

// MARK: - エイリアス
public typealias DMColor = SwiftWin32.Color
public typealias DMView = SwiftWin32.View
public typealias DMViewController = SwiftWin32.ViewController
public typealias DMApplication = SwiftWin32.Application

public typealias DMTextField = SwiftWin32.TextField
public typealias DMButton = SwiftWin32.Button

public typealias DMFont = SwiftWin32.Font
public typealias DMBezierPath = SwiftWin32.BezierPath // 未実装
public typealias DMScreen = SwiftWin32.Screen
public typealias DMImage = SwiftWin32.Image
public typealias DMLabel = SwiftWin32.Label

public typealias DMEvent = SwiftWin32.Event

// MARK: - ダミーオブジェクト
public class DMPrintInfo {}

public class DMGraphicsContext {}

public class DMTextStorage {}
public class DMTextContainer {}
public class DMLayoutManager {}

// MARK: - 不足API補完
/// autoreleasepoolがないので補完する
@inlinable public func autoreleasepool<T>(_ block: () throws -> T) rethrows -> T {
    return try block()
}

extension DMColor {
    public var srgbComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return (red, green, blue, alpha)
    }
}

#endif
