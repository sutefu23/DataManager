//
//  PaperRect.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/02/06.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

func convert(mm: Double) -> CGFloat {
    return CGFloat(mm * 72.0 / 25.4)
}

public class PaperRect {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    
    let rect: CGRect

    public init(x: Double, y:Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        let px = convert(mm: x)
        let py = convert(mm: y)
        let pw = convert(mm: width)
        let ph = convert(mm: height)
        self.rect = CGRect(x: px, y: py, width: pw, height: ph)
    }
}

public class PaperPath {
    private var points: [CGPoint] = []
    private let lineWidth: CGFloat
    
    public init(lineWidth: CGFloat = 1.0) {
        self.lineWidth = lineWidth
    }
    
    public func append(x: Double, y: Double) {
        let x = convert(mm: x)
        let y = convert(mm: y)
        
        points.append(CGPoint(x: x, y: y))
    }
    
    func stroke() {
        let path = DMBezierPath(polyline: &points)
        path.lineWidth = lineWidth
        path.stroke()
    }
}

public class PaperText {
    let storage: NSTextStorage
    let container: NSTextContainer
    let manager: NSLayoutManager
    
    let x: Double
    let y: Double
    
    public init(x: Double, y: Double, text: String, fontSize: CGFloat, color: DMColor) {
        self.x = x
        self.y = y
        let font = DMFont.systemFont(ofSize: fontSize)
        let attributes  = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
        let storage = NSTextStorage(string: text, attributes: attributes)
        let container = NSTextContainer()
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        self.storage = storage
        self.container = container
        self.manager = manager
    }

    var bounds: CGRect {
        let range = manager.glyphRange(for: container)
        let bounds = manager.boundingRect(forGlyphRange: range, in: container)
        return bounds
    }
    func draw(rect: CGRect) {
        var origin = rect.origin
        origin.x -= (rect.height/2 - 2)
        origin.y -= (rect.height/2 + 1)
        guard let layoutManager = storage.layoutManagers.first else { return }
        guard let textContainer = layoutManager.textContainers.first else { return }
        let range = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawGlyphs(forGlyphRange: range, at: origin)
    }
}
