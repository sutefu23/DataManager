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
    func dark(brightnessRatio: CGFloat = 0.8) -> DMColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return DMColor(hue: hue, saturation: saturation, brightness: brightness * brightnessRatio, alpha: alpha)
    }
}
#endif
