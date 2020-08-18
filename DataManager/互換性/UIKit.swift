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
    
    func line(to: CGPoint) {
        self.addLine(to: to)
    }
}

extension UITextField {
    var stringValue: String {
        get { return self.text ?? "" }
        set { self.text = newValue }
    }
}

public extension UIView {
    private func search(_ name: String) -> UIView? {
        if self.accessibilityIdentifier == name { return self }
        for view in subviews {
            if let result = view.search(name) { return result }
        }
        return nil
    }
    
    func searchLabel(_ name: String) -> UILabel? {
        return self.search(name) as? UILabel
    }
    
    func searchButton(_ name: String) -> UIButton? {
        return self.search(name) as? UIButton
    }

    func searchTextField(_ name: String) -> UITextField? {
        return self.search(name) as? UITextField
    }

    private func searchImage(_ name: String) -> UIImageView? {
        return self.search(name) as? UIImageView
    }
    
    #if os(tvOS)
    #else
    private func searchSwitch(_ name: String) -> UISwitch? {
        return self.search(name) as? UISwitch
    }
    @discardableResult func updateSwitch(_ name: String, _ flg: Bool, tag: Int? = nil) -> UISwitch? {
        guard let view = searchSwitch(name) else { return nil }
        view.isOn = flg
        if let tag = tag { view.tag = tag }
        return view
    }
    
    #endif
    
    @discardableResult func updateText(_ name: String, text: String?, tag: Int? = nil, target: Any? = nil, action: Selector? = nil) -> UITextField? {
        guard let view = searchTextField(name) else { return nil }
        if let target = target, let action = action {
            view.addTarget(target, action: action, for: .primaryActionTriggered)
        }
        if let tag = tag { view.tag = tag }
        view.text = text
        return view
    }
    
    @discardableResult func updateLabel(_ name: String, text: String?, tcolor: DMColor? = nil, tag: Int? = nil, noEmpty: Bool = false, target: Any? = nil, action: Selector? = nil) -> UILabel? {
        guard let view = searchLabel(name) else { return nil }
        if let tcolor = tcolor {
            view.attributedText = text?.makeAttributedString(color: tcolor, font: view.font)
        } else {
            view.text = text?.isEmpty == false ? text : " "
        }
        if let target = target, let action = action {
            let myTap: UITapGestureRecognizer = UITapGestureRecognizer(target: target, action: action)
            self.isUserInteractionEnabled = true
            self.addGestureRecognizer(myTap)
        }
        if let tag = tag { view.tag = tag }
        return view
    }
    
    @discardableResult func updateLabel(_ name: String, text: NSAttributedString?, noEmpty: Bool = false) -> UILabel? {
        guard let view = searchLabel(name) else { return nil }
        view.attributedText = text ?? NSAttributedString()
        return view
    }
    
    @discardableResult func updateImage(_ name: String, image: UIImage) -> UIImageView? {
        guard let view = searchImage(name) else { return nil }
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

extension UIColor {
    var rgba : (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
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
        let (_, _, _, alpha) = self.rgba
        return alpha
    }
    
}

extension UIView {
    func updateAll() { self.setNeedsDisplay() }
    func updateRect(_ frame:CGRect) { self.setNeedsDisplay(frame) }
//    var screen : NCScreen? { return self.window?.screen }
}

extension UIFont  {
    class func toolTipsFont(ofSize size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }
    class func userFont(ofSize size: CGFloat) -> UIFont? {
        return UIFont.systemFont(ofSize: size)
    }
}

//public func getDisplayInfo(of screen: UIScreen)-> (screenSize: CGSize, xPixels: Int, yPixels: Int) {
//    let screen = UIScreen.main
//    let res = screen.bounds
//    let testPixels = defaults.testPixels
//    let testPhysicals = defaults.testPhisicals
//    let scaleX : CGFloat
//    let scaleY : CGFloat
//    if testPixels.offsetWidth > 0 && testPixels.height > 0 && testPhysicals.offsetWidth > 0 && testPhysicals.height > 0 {
//        scaleX = testPhysicals.offsetWidth / testPixels.offsetWidth
//        scaleY = testPhysicals.height / testPixels.height
//    } else {
//        scaleX = 132 / 22.4
//        scaleY = 132 / 22.4
//    }
//    let w = res.offsetWidth * scaleX
//    let h = res.height * scaleY
//    return (CGSize(offsetWidth: w, height: h), xPixels: Int(res.offsetWidth), yPixels: Int(res.height))
//}

public typealias DMTextStorage = NSTextStorage
public typealias DMTextContainer = NSTextContainer
public typealias DMLayoutManager = NSLayoutManager

#endif

