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

public extension NSAttributedString {
    convenience init() {
        self.init(string: "")
    }
}

// MARK: - ダミーオブジェクト
class DMColor {}
class DMView {}
class DMViewController {}

class DMTextField {}
class DMPrintInfo {}
class DMButton {}

class DMGraphicsContext {}
class DMFont {}
class DMBezierPath {}
class DMScreen {}
class DMImage {}

class DMEvent {}
class DMApplicationtton {}

class DMTextStorage {}
class DMTextContainer {}
class DMLayoutManager {}
#endif
