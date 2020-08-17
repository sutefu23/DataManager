//
//  NCtoDM.swift
//  DataManager
//
//  Created by 平川知秀 on R 2/08/17.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//
import Foundation

public typealias NCColor = DMColor
public typealias NCView = DMView
public typealias NCTextField = DMTextField

public typealias NCFont = DMFont
public typealias NCBezierPath = DMBezierPath
public typealias NCScreen = DMScreen

public typealias NCEvent = DMEvent

public typealias NCApplication = DMApplication

public func NCGraphicsPushContext(_ context: CGContext) {
    DMGraphicsPushContext(context)
}
public func NCGraphicsPopContext() {
    DMGraphicsPopContext()
}


public typealias NCTextStorage = DMTextStorage
public typealias NCTextContainer = DMTextContainer
public typealias NCLayoutManager = DMLayoutManager
