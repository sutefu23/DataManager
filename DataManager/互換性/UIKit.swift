//
//  UIKit.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/02/06.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit

public typealias DMColor = UIColor
public typealias DMView = UIView
public typealias DMTextField = UITextField

public typealias DMGraphicsContext = UIGraphicsPDFRendererContext
public enum DMPaperOrientation {
    case landscape
    case portrait
}
public func DMGraphicsPushContext(_ context: CGContext) { UIGraphicsPushContext(context) }
public func DMGraphicsPopContext() { UIGraphicsPopContext() }

public typealias DMFont = UIFont
public typealias DMBezierPath = UIBezierPath
public typealias DMScreen = UIScreen
public typealias DMImage = UIImage

public typealias DMEvent = UIEvent

public typealias DMApplication = UIApplication

extension UIBezierPath {
    class func strokeLine(from: CGPoint, to: CGPoint) {
        let single = UIBezierPath()
        single.move(to: from)
        single.addLine(to: to)
        single.stroke()
    }
    
    convenience init(polyline: inout [CGPoint]) {
        self.init()
        var itr = polyline.makeIterator()
        guard let firstPoint = itr.next() else { return }
        self.move(to: firstPoint)
        while let nextPoint = itr.next() {
            self.addLine(to: nextPoint)
        }
    }
}

extension UITextField {
    var stringValue: String {
        get { return self.text ?? "" }
        set { self.text = newValue }
    }
}

#endif
