//
//  Int.swift
//  DataManager
//
//  Created by manager on 2020/04/03.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation

extension Int {
    public init?(_ text: String?) {
        guard let text = text, let number = Int(text) else { return nil }
        self = number
    }
}
