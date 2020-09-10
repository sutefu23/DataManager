//
//  UIKit.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/02/06.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation

#if os(iOS)
public typealias DMPrintInfo = UIPrintInfo
public extension DMPrintInfo {
    enum PaperOrientation {
        case landscape
        case portrait
    }
}
#endif

#if os(iOS) || os(tvOS)
import UIKit

public typealias DMColor = UIColor
public typealias DMView = UIView
public typealias DMViewController = UIViewController
public typealias DMTextField = UITextField

public typealias DMGraphicsContext = UIGraphicsPDFRendererContext
public func DMGraphicsPushContext(_ context: CGContext) { UIGraphicsPushContext(context) }
public func DMGraphicsPopContext() { UIGraphicsPopContext() }

public typealias DMFont = UIFont

public typealias DMBezierPath = UIBezierPath
public typealias DMScreen = UIScreen
public typealias DMImage = UIImage

public typealias DMEvent = UIEvent

public typealias DMApplication = UIApplication

public extension UIBezierPath {
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
    class func fill(_ rect: CGRect) {
        let path = UIBezierPath(rect: rect)
        path.fill()
    }
    
    func line(to: CGPoint) {
        self.addLine(to: to)
    }
}

public extension UITextField {
    var stringValue: String {
        get { return self.text ?? "" }
        set { self.text = newValue }
    }
    var placeholderString: String {
        get { self.placeholder ?? "" }
        set { self.placeholder = newValue }
    }
    var isEditable: Bool {
        get { self.isEnabled }
        set { self.isEnabled = newValue }
    }
}

public extension UIView {
    func searchView(_ blockName: String) -> UIView? {
        if self.accessibilityIdentifier == blockName { return self }
        for view in subviews {
            if let result = view.searchView(blockName) { return result }
        }
        return nil
    }
    
    func searchLabel(_ blockName: String) -> UILabel? {
        return self.searchView(blockName) as? UILabel
    }
    
    func searchButton(_ blockName: String) -> UIButton? {
        return self.searchView(blockName) as? UIButton
    }

    func searchTextField(_ blockName: String) -> UITextField? {
        return self.searchView(blockName) as? UITextField
    }

    private func searchImage(_ blockName: String) -> UIImageView? {
        return self.searchView(blockName) as? UIImageView
    }
    
    #if os(tvOS)
    #else
    private func searchSwitch(_ blockName: String) -> UISwitch? {
        return self.searchView(blockName) as? UISwitch
    }
    @discardableResult func updateSwitch(_ blockName: String, _ flg: Bool, tag: Int? = nil) -> UISwitch? {
        guard let view = searchSwitch(blockName) else { return nil }
        view.isOn = flg
        if let tag = tag { view.tag = tag }
        return view
    }
    
    #endif
    
    @discardableResult func updateText(_ blockName: String, text: String?, tag: Int? = nil, target: Any? = nil, action: Selector? = nil) -> UITextField? {
        guard let view = searchTextField(blockName) else { return nil }
        if let target = target, let action = action {
            view.addTarget(target, action: action, for: .primaryActionTriggered)
        }
        if let tag = tag { view.tag = tag }
        view.text = text
        return view
    }
    
    @discardableResult func updateLabel(_ blockName: String, text: Any?, tcolor: DMColor? = nil, bgColor: DMColor? = nil, tag: Int? = nil, noEmpty: Bool = false, target: Any? = nil, action: Selector? = nil) -> UILabel? {
        guard let view = searchLabel(blockName) else { return nil }
        if let attr = text as? NSAttributedString {
            view.attributedText = attr
        } else if let text = text as? String {
            if let tcolor = tcolor {
                view.attributedText = text.makeAttributedString(color: tcolor, font: view.font)
            } else {
                view.text = text.isEmpty == false ? text : " "
            }
        } else {
            view.text = nil
        }
        view.backgroundColor = bgColor
        if let target = target, let action = action {
            let myTap: UITapGestureRecognizer = UITapGestureRecognizer(target: target, action: action)
            self.isUserInteractionEnabled = true
            self.addGestureRecognizer(myTap)
        }
        if let tag = tag { view.tag = tag }
        return view
    }
    
//    @discardableResult func updateLabel(_ blockName: String, text: NSAttributedString, tag: Int? = nil, noEmpty: Bool = false, target: Any? = nil, action: Selector? = nil) -> UILabel? {
//        guard let view = searchLabel(blockName) else { return nil }
//        view.attributedText = text
//        if let target = target, let action = action {
//            let myTap: UITapGestureRecognizer = UITapGestureRecognizer(target: target, action: action)
//            self.isUserInteractionEnabled = true
//            self.addGestureRecognizer(myTap)
//        }
//        if let tag = tag { view.tag = tag }
//        return view
//    }

    @discardableResult func updateImage(_ blockName: String, image: UIImage) -> UIImageView? {
        guard let view = searchImage(blockName) else { return nil }
        view.image = image
        return view
    }
    
}

#endif

public extension DMColor {
    func dark(brightnessRatio: CGFloat = 0.8) -> DMColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return DMColor(hue: hue, saturation: saturation, brightness: brightness * brightnessRatio, alpha: alpha)
    }
}


#if os(iOS)
extension UIResponder {
    public func makeFirstResponder2() {
        #if targetEnvironment(macCatalyst)
        DispatchQueue.main.async {
            self.becomeFirstResponder()
        }
        #elseif os(iOS)
        self.becomeFirstResponder()
        #endif
    }
}

extension UIButton {
    public var text: String? {
        get { self.title(for: .normal) }
        set { setTitle(newValue, for: .normal) }
    }
}

extension UIViewController {
    public func searchViewController<T: UIViewController>() -> T? {
        if let vc: T = self as? T { return vc }
        for child in self.children {
            if let vc: T = child.searchViewController() { return vc }
        }
        return nil
    }
}
#endif

// NCEngine/Utility/ClossPlatformより移設
#if os(iOS)
import UIKit

public extension UIColor {
    var srgbComponents : (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red : CGFloat = 0
        var green : CGFloat = 0
        var blue : CGFloat = 0
        var alpha : CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        }
        var white : CGFloat = 0
        if self.getWhite(&white, alpha: &alpha) {
            return (white, white, white, alpha)
        }
        fatalError("UIColor.rgbaでrgbaが取得できなかった")
    }
    
    convenience init(srgbRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    var alphaComponent : CGFloat {
        let (_, _, _, alpha) = self.srgbComponents
        return alpha
    }
    
}

public extension UIView {
    func updateAll() { self.setNeedsDisplay() }
    func updateRect(_ frame:CGRect) { self.setNeedsDisplay(frame) }
//    var screen : NCScreen? { return self.window?.screen }
}

public extension UIFont  {
    class func toolTipsFont(ofSize size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }
    class func userFont(ofSize size: CGFloat) -> UIFont? {
        return UIFont.systemFont(ofSize: size)
    }
}


public typealias DMTextStorage = NSTextStorage
public typealias DMTextContainer = NSTextContainer
public typealias DMLayoutManager = NSLayoutManager

#endif

