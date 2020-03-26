//
//  PaperRect.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/02/06.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation
#if os(tvOS) || os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// mm → ポイント 変換
func convert(mm: Double) -> CGFloat {
    return CGFloat(mm * 72.0 / 25.4)
}

/// ポイント → mm 変換
func convert(point: CGFloat) -> Double {
    return Double(point * 25.4 / 72.0)
}

public class PaperRect: PaperObject {
    public var px: CGFloat
    public var py: CGFloat
    public var pwidth: CGFloat
    public var pheight: CGFloat
    public var pmaxX: CGFloat { return px + pwidth }
    public var pmaxY: CGFloat { return py + pheight }
    
    var rect: CGRect {
        return CGRect(x: px, y: py, width: pwidth, height: pheight)
    }

    public init(x: Double, y:Double, width: Double, height: Double) {
        self.px = convert(mm: x)
        self.py = convert(mm: y)
        self.pwidth = convert(mm: width)
        self.pheight = convert(mm: height)
    }

    public init(px: CGFloat, py:CGFloat, pwidth: CGFloat, pheight: CGFloat) {
        self.px = px
        self.py = py
        self.pwidth = pwidth
        self.pheight = pheight
    }

    public func moveTo(x: Double, y: Double) {
        self.px = convert(mm: x)
        self.py = convert(mm: y)
    }
    private(set) var objects: [PaperObject] = []
    public func append(_ object: PaperObject) {
        objects.append(object)
    }
    
    public func draw(at: CGPoint) {
        let px = self.px + at.x
        let py = self.py + at.y
        let origin = CGPoint(x: px, y: py)
        objects.forEach { $0.draw(at: origin) }
    }
    
    public func append(_ rect: PaperRect) {
        let px = min(self.px, rect.px)
        let py = min(self.py, rect.py)
        let maxx = max(self.pmaxX, rect.pmaxX)
        let maxy = max(self.pmaxY, rect.pmaxY)
        self.px = px
        self.py = py
        self.pwidth = maxx - px
        self.pheight = maxy - py
        self.objects.append(contentsOf: rect.objects)
    }
}

public protocol PaperObject {
    func draw(at: CGPoint)
}

public class PaperPath: PaperObject {
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
    
    public func draw(at: CGPoint) {
        var points: [CGPoint] = self.points.map {
            let x = $0.x + at.x
            let y = $0.y + at.y
            return CGPoint(x: x, y: y)
        }
        let path = DMBezierPath(polyline: &points)
        path.lineWidth = lineWidth
        path.stroke()
    }
}

#if os(tvOS)
#else
public class PaperBarCode: PaperObject {
    var barCode: DMBarCode
    var rect: CGRect
    
    public init(barCode: DMBarCode, rect: CGRect) {
        self.barCode = barCode
        self.rect = rect
    }
    
    public func draw(at: CGPoint) {
        var rect = self.rect
        rect.origin.x += at.x
        rect.origin.y += at.y
        barCode.draw(inRect: rect)
    }
}
#endif

public class PaperImage: PaperObject {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let image: DMImage
    
    public init(x: Double, y: Double, width: Double, height: Double, image: DMImage) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.image = image
    }
    
    public func draw(at: CGPoint) {
        let x = convert(mm: self.x) + at.x
        let y = convert(mm: self.y) + at.y
        let width = convert(mm: self.width)
        let height = convert(mm: self.height)
        let rect = CGRect(x: x, y: y, width: width, height: height)
        image.draw(in: rect)
    }
}

public class PaperText: PaperObject {
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
    
    public func draw(at: CGPoint) {
        let rect = self.bounds
        var origin = at
        #if targetEnvironment(macCatalyst)
        let dy = CGFloat(-y)
        #else
        let dy = CGFloat(y)
        #endif
        origin.x -= (rect.height/2 - 2) + CGFloat(x)
        origin.y -= (rect.height/2 + 1) + dy
        guard let layoutManager = storage.layoutManagers.first else { return }
        guard let textContainer = layoutManager.textContainers.first else { return }
        let range = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawGlyphs(forGlyphRange: range, at: origin)
    }
}
