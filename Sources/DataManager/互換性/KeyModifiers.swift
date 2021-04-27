//
//  KeyModifiers.swift
//  NCEngine
//
//  Created by manager on 2020/02/04.
//  Copyright © 2020 四熊 泰之. All rights reserved.
//

import Foundation

#if os(macOS)
/// 修飾キーの状態
public protocol KeyModifiers: AnyObject {
    var modifierFlags: DMEvent.ModifierFlags { get }
}

public extension KeyModifiers {
    var isShiftDown: Bool {
        return modifierFlags.contains(.shift)
    }
    var isControlDown: Bool {
        return modifierFlags.contains(.control)
    }
    var isOptionDown: Bool {
        return modifierFlags.contains(.option)
    }
    var isCommandDown: Bool {
        return modifierFlags.contains(.command)
    }
}

extension DMEvent: KeyModifiers {}

#endif
