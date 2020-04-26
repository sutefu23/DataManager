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
public func convertPoint(mm: Double) -> CGFloat {
    return CGFloat(mm * 72.0 / 25.4)
}

/// ポイント → mm 変換
public func convertMM(point: CGFloat) -> Double {
    return Double(point * 25.4 / 72.0)
}

// MARK: - rect
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
        self.px = convertPoint(mm: x)
        self.py = convertPoint(mm: y)
        self.pwidth = convertPoint(mm: width)
        self.pheight = convertPoint(mm: height)
    }

    public init(px: CGFloat, py:CGFloat, pwidth: CGFloat, pheight: CGFloat) {
        self.px = px
        self.py = py
        self.pwidth = pwidth
        self.pheight = pheight
    }

    public func moveTo(x: Double, y: Double) {
        self.px = convertPoint(mm: x)
        self.py = convertPoint(mm: y)
    }
    private(set) var objects: [PaperObject] = []
    public func append(_ object: PaperObject) {
        objects.append(object)
    }
    
    public func draw(at: CGPoint, isFlipped: Bool) {
        let px = self.px + at.x
        let py = isFlipped ? (at.y - self.py + pheight) : self.py + at.y
        let origin = CGPoint(x: px, y: py)
        objects.forEach { $0.draw(at: origin, isFlipped: isFlipped) }
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
    func draw(at: CGPoint, isFlipped: Bool)
}

// MARK: - path
public class PaperPath: PaperObject {
    public static func makeLine(from: (x: Double, y: Double), to: (x: Double, y: Double), lineWidth: CGFloat = 1.0) -> PaperPath {
        let path = PaperPath(lineWidth: lineWidth)
        path.append(x: from.x, y: from.y)
        path.append(x: to.x, y: to.y)
        return path
    }
    
    public static func makeBox(origin: (x: Double, y: Double), size: (width: Double, height: Double), lineWidth: CGFloat = 1.0) -> PaperPath {
        let path = PaperPath(lineWidth: lineWidth)
        path.append(x: origin.x, y: origin.y)
        path.append(x: origin.x + size.width, y: origin.y)
        path.append(x: origin.x + size.width, y: origin.y + size.height)
        path.append(x: origin.x, y: origin.y + size.height)
        path.append(x: origin.x, y: origin.y)
        return path
    }
    
    private var points: [CGPoint] = []
    private let lineWidth: CGFloat
    
    public init(lineWidth: CGFloat = 1.0) {
        self.lineWidth = lineWidth
    }
    
    public func append(x: Double, y: Double) {
        let x = convertPoint(mm: x)
        let y = convertPoint(mm: y)
        
        points.append(CGPoint(x: x, y: y))
    }

    public func append(x: CGFloat, y: CGFloat) {
        points.append(CGPoint(x: x, y: y))
    }
    
    public func draw(at: CGPoint, isFlipped: Bool) {
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

// MARK: - barcode
#if os(tvOS)
#else
public class PaperBarCode: PaperObject {
    var barCode: DMBarCode
    var rect: CGRect
    let fontSize: CGFloat?
    
    public init(barCode: DMBarCode, rect: CGRect, fontSize: CGFloat?) {
        self.barCode = barCode
        self.rect = rect
        self.fontSize = fontSize
    }
    
    public func draw(at: CGPoint, isFlipped: Bool) {
        var rect = self.rect
        if isFlipped { rect.origin.y = -rect.origin.y }
        rect.origin.x += at.x
        rect.origin.y += at.y
        barCode.draw(inRect: rect, isFlipped: isFlipped, fontSize: fontSize)
    }
}
#endif

// MARK: - image
public class PaperImage: PaperObject {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let image: DMImage
    
    public init(mx: Double, my: Double, mwidth: Double, mheight: Double, image: DMImage) {
        self.x = convertPoint(mm: mx)
        self.y = convertPoint(mm: my)
        self.width = convertPoint(mm: mwidth)
        self.height = convertPoint(mm: mheight)
        self.image = image
    }

    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, image: DMImage) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.image = image
    }

    public func draw(at: CGPoint, isFlipped: Bool) {
        let x = self.x + at.x
        var y = self.y
        if isFlipped { y = -y }
        y += at.y
        let width = self.width
        let height = self.height
        let rect = CGRect(x: x, y: y, width: width, height: height)
        image.draw(in: rect)
    }
}

// MARK: - text
public class PaperText: PaperObject {
    let storage: NSTextStorage
    let container: NSTextContainer
    let manager: NSLayoutManager
    
    let x: CGFloat
    let y: CGFloat

    public convenience init(mmx: Double, mmy: Double, text: String, fontSize: CGFloat, bold: Bool = false, color: DMColor) {
        let x = convertPoint(mm: mmx)
        let y = convertPoint(mm: mmy)
        self.init(x: x, y: y, text: text, fontSize: fontSize, bold: bold, color: color)
    }
    
    public init(x: CGFloat, y: CGFloat, text: String, fontSize: CGFloat, bold: Bool = false, color: DMColor) {
        self.x = x
        self.y = y
        let font = bold ? DMFont.boldSystemFont(ofSize: fontSize) : DMFont.systemFont(ofSize: fontSize)
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
    
    public func draw(at: CGPoint, isFlipped: Bool) {
        let rect = self.bounds
        let dx = x - rect.origin.x
        let dy = isFlipped ? (-y-rect.height/2) : (y - (rect.height/2))
        var origin = at
        origin.x += dx
        origin.y += dy
        guard let layoutManager = storage.layoutManagers.first else { return }
        guard let textContainer = layoutManager.textContainers.first else { return }
        let range = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawGlyphs(forGlyphRange: range, at: origin)
    }
}

// MARK: - Canvas
public class PaperCanvas: PaperObject {
    let rect: CGRect
    let painter: (CGRect, Bool) -> ()
    
    public init(rect: CGRect, painter: @escaping (CGRect, Bool) -> ()) {
        self.rect = rect
        self.painter = painter
    }
    
    public func draw(at: CGPoint, isFlipped: Bool) {
        var rect = self.rect
        rect.origin.x += at.x
        rect.origin.y = isFlipped ? (at.y - rect.origin.y) : (at.y + rect.origin.y)
        painter(rect, isFlipped)
    }

}

// MARK: -
public typealias MMPoint = SIMD2<Double>
public typealias MMSize = SIMD2<Double>

public struct MMRect {
    public var origin: MMPoint
    public var size: MMSize
    
    public init(origin: MMPoint, size: MMPoint) {
        self.origin = origin
        self.size = size
    }
    
    public var rect: CGRect {
        return CGRect(origin: origin.point, size: size.size)
    }
}

extension MMPoint {
    public var point: CGPoint {
        let x = convertPoint(mm: self.x)
        let y = convertPoint(mm: self.y)
        return CGPoint(x: x, y: y)
    }
}

extension MMSize {
    public var width: Double { self.x }
    public var height: Double { self.y }

    public init(width: Double, height: Double) {
        self = MMSize(x: width, y: height)
    }
    
    public var size: CGSize {
        let width = convertPoint(mm: self.width)
        let height = convertPoint(mm: self.height)
        return CGSize(width: width, height: height)
    }
}
