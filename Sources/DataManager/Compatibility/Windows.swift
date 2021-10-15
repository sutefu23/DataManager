//
//  Windows.swift
//  DataManager
//
//  Created by manager on 2021/10/15.
//

import Foundation

#if os(Windows)
// MARK: - 不足API補完
/// autoreleasepoolがないので補完する
@inlinable public func autoreleasepool<T>(_ block: () throws -> T) rethrows -> T {
    return try block()
}

// MARK: - ダミーオブジェクト
public class DMColor {
    public static let black = DMColor()
    public static let cyan = DMColor()
    public static let red = DMColor()
    public static let blue = DMColor()
    public static let yellow = DMColor()
    public static let magenta = DMColor()
    public static let white = DMColor()
}
public class DMView {}
public class DMViewController {}

public class DMTextField {}
public class DMPrintInfo {}
public class DMButton {}

public class DMGraphicsContext {}
public class DMFont {}
public class DMBezierPath {}
public class DMScreen {}
public class DMImage {}

public class DMEvent {}
public class DMApplicationtton {}

public class DMTextStorage {}
public class DMTextContainer {}
public class DMLayoutManager {}
#endif
