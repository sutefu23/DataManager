//
//  Linux.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/09/25.
//

import Foundation

#if os(Linux)
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
public class DMApplication {}

public class DMTextStorage {}
public class DMTextContainer {}
public class DMLayoutManager {}
#endif
