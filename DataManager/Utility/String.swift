//
//  String.swift
//  DataManager
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

private let controlSet = CharacterSet.controlCharacters

extension String {
    var tabStripped : [Substring] {
        return self.split(separator: "\t", omittingEmptySubsequences: false).map { $0.controlStripped }
    }
    
    var commaStripped : [Substring] {
        return self.split(separator: ",", omittingEmptySubsequences: false).map { $0.controlStripped }
    }
}

extension Substring {
    var controlStripped : Substring {
        if let tail = self.last?.unicodeScalars.first {
            if controlSet.contains(tail) {
                return self.dropLast().controlStripped
            }
        }
        return self
    }
}

private var numberSet : CharacterSet = {
    var set = CharacterSet()
    set.insert(charactersIn: "0123456789")
    return set
}()

extension StringProtocol {
    var headNumber : String {
        var string : String = ""
        for ch in self {
            guard let sc = ch.unicodeScalars.first else { break }
            guard numberSet.contains(sc) else { break }
            string.append(ch)
        }
        return string
    }
}

extension String {
    func containsOne(of strings:String...) -> Bool {
        for str in strings {
            if self.contains(str) { return true }
        }
        return false
    }
}

private let numberRange = (Character("0")...Character("9"))

extension StringProtocol {
    func makeNumbers() -> [Int] {
        return self.split { numberRange.contains($0) == false }.compactMap { Int($0) }
    }
}

func make2dig(_ value:Int) -> String {
    let str = String(value)
    switch str.count {
    case 0:
        return "00"
    case 1:
        return "0" + str
    default:
        return str
    }
}

func make4dig(_ value:Int) -> String {
    let str = String(value)
    switch str.count {
    case 0:
        return "0000"
    case 1:
        return "000" + str
    case 2:
        return "00" + str
    case 3:
        return "0" + str
    default:
        return str
    }
}

