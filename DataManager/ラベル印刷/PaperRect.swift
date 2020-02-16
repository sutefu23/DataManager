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
    public var x: Double
    public var y: Double
    public let width: Double
    public let height: Double
    public var maxY: Double { return y + height }
    
    var rect: CGRect {
        let px = convert(mm: x)
        let py = convert(mm: y)
        let pw = convert(mm: width)
        let ph = convert(mm: height)
        return CGRect(x: px, y: py, width: pw, height: ph)
    }

    public init(x: Double, y:Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    private(set) var objects: [PaperObject] = []
    public func append(_ object: PaperObject) {
        objects.append(object)
    }
    
    public func draw(at: CGPoint) {
        let px = convert(mm: x) + at.x
        let py = convert(mm: y) + at.y
        let origin = CGPoint(x: px, y: py)
        objects.forEach { $0.draw(at: origin) }
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
        origin.x -= (rect.height/2 - 2)
        origin.y -= (rect.height/2 + 1)
        guard let layoutManager = storage.layoutManagers.first else { return }
        guard let textContainer = layoutManager.textContainers.first else { return }
        let range = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawGlyphs(forGlyphRange: range, at: origin)
    }
}
