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
public typealias DMPaperOrientation = NSPrintInfo.PaperOrientation
public func DMGraphicsPushContext(_ context: CGContext) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
}
public func DMGraphicsPopContext() {
    NSGraphicsContext.restoreGraphicsState()
}

public typealias DMFont = NSFont
public typealias DMBezierPath = NSBezierPath
public typealias DMScreen = NSScreen
public typealias DMImage = NSImage

public typealias DMEvent = NSEvent

public typealias DMApplication = NSApplication

public extension NSBezierPath {
    convenience init(polyline: inout [CGPoint]) {
        self.init()
        self.appendPoints(&polyline, count: polyline.count)
    }
}

extension DMBezierPath {
    public convenience init(roundedRect: CGRect, cornerRadius: CGFloat) {
        self.init(roundedRect: roundedRect, xRadius: cornerRadius, yRadius: cornerRadius)
    }
}

#endif

// NCEngine/Utility/ClossPlatformより移設

#if os(iOS)
#elseif os(macOS)

import Cocoa

extension NSColor {
    public var srgbComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        if let rgbColor = self.usingColorSpace(NSColorSpace.sRGB) {
            let red = rgbColor.redComponent
            let green = rgbColor.greenComponent
            let blue = rgbColor.blueComponent
            let alpha = rgbColor.alphaComponent
            return (red, green, blue, alpha)
            
        } else {
            return (0,0,0,0)
        }
    }

}

public extension NSView {
    func updateAll() { self.needsDisplay = true }
    func updateRect(_ rect:CGRect) { self.setNeedsDisplay(rect) }
//    var screen : NCScreen? { return self.window?.screen }
}

public func getDisplayInfo(of screen: NSScreen)-> (screenSize: CGSize, xPixels: Int, yPixels: Int) {
    return executeInMainThread {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        let displayID = (screen.deviceDescription[key] as! NSNumber).uint32Value
        let size = CGDisplayScreenSize(displayID)// ディスプレイサイズ(mm)。
        let xPixels = CGDisplayPixelsWide(displayID)
        let yPixels = CGDisplayPixelsHigh(displayID)
        return (size, xPixels, yPixels)
    }
}

public func showModalDialog(message: String, info: String = "", buttons: String...) -> Int {
    let alert = NSAlert()
    alert.messageText = message
    alert.informativeText = info
    for title in buttons {
        alert.addButton(withTitle: title)
    }
    let ret = alert.runModal()
    switch ret {
    case .alertFirstButtonReturn:
        return 0
    case .alertSecondButtonReturn:
        return 1
    case .alertThirdButtonReturn:
        return 2
    default:
        return -1
    }
}

public extension NSAlert {
    static func showAlert(_ message: String, info: String = "") {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = info
        alert.runModal()
    }
}

public extension NSEvent {
    static var isShiftDown: Bool {
        return modifierFlags.contains(.shift)
    }
    static var isControlDown: Bool {
        return modifierFlags.contains(.control)
    }
    static var isOptionDown: Bool {
        return modifierFlags.contains(.option)
    }
    static var isCommandDown: Bool {
        return modifierFlags.contains(.command)
    }
}

public typealias DMTextStorage = NSTextStorage
public typealias DMTextContainer = NSTextContainer
public typealias DMLayoutManager = NSLayoutManager

#endif
