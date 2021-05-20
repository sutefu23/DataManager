//
//  DMColor.swift
//  
//
//  Created by manager on 2020/09/24.
//

import Foundation

#if os(iOS) || os(tvOS) || os(macOS)
import CoreGraphics

public extension DMColor {
    /// 輝度を落とす
    func dark(brightnessRatio: CGFloat = 0.8) -> DMColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return DMColor(hue: hue, saturation: saturation, brightness: brightness * brightnessRatio, alpha: alpha)
    }
    
    var isBlack: Bool {
        if self == DMColor.black { return true }
        let (red, green, blue, _) = self.srgbComponents
        return red.isZero && green.isZero && blue.isZero
    }
    
    var isWhite: Bool {
        if self == DMColor.white { return true }
        let (red, green, blue, _) = self.srgbComponents
        return red >= 1.0 && green >= 1.0 && blue >= 1.0
    }
}
#endif
