//
//  BarCode.swift
//  NCEngine
//
//  Created by manager on 2019/11/15.
//  Copyright © 2019 四熊 泰之. All rights reserved.
//

import Foundation
import CoreGraphics

/// 二次元バーコード
public struct DMBarCode {
    let text: String
    let characters: [BarCodeCharacter]
    
    public init?(code39 text: String) {
        var characters: [BarCodeCharacter] = [Code39.start]
        for ch in text.uppercased() {
            guard var character = Code39.codeMap[ch] else { return nil }
            character.character = ch
            characters.append(character)
        }
        characters.append(Code39.stop)
        self.characters = characters
        self.text = text
    }
    
    public init?(code128B text: String) {
        var characters: [BarCodeCharacter] = [Code128.startB]
        var checkNumber = Code128.startB.code
        for (index, ch) in text.enumerated() {
            guard var character = Code128.codeMap[ch] else { return nil }
            character.character = ch
            characters.append(character)
            checkNumber += (index+1) * character.code
        }
        var checkDigit = Code128.codeTable[checkNumber % 103].character
        checkDigit.character = nil
        characters.append(checkDigit)
        characters.append(Code128.stop)
        self.characters = characters
        self.text = text
    }
}

// MARK: -
struct BarCodeCharacter {
    enum StripeColor {
        case white
        case black
        
        var nextColor: StripeColor {
            switch self {
            case .white: return .black
            case .black: return .white
            }
        }
    }
    
    let code: Int
    let pattern: [CGFloat]
    let digits: CGFloat
    var character: Character? = nil

    init(code: Int, patternArray: [CGFloat]) {
        self.code = code
        self.pattern = patternArray
        self.digits = pattern.reduce(0) { $0 + $1 }
    }

    init(code: Int, pattern: CGFloat...) {
        self.init(code: code, patternArray: pattern)
    }
}

// MARK: - CODE128
struct Code128 {
    var character: BarCodeCharacter
    var codeA: Code128Character
    var codeB: Code128Character
    var codeC: Code128Character
    
    init(code: Int, pattern: CGFloat... , codeA: Code128Character, codeB: Code128Character?, codeC: Code128Character?) {
        self.character = BarCodeCharacter(code: code, patternArray: pattern)
        self.codeA = codeA
        self.codeB = codeB ?? codeA
        self.codeC = codeC ?? ((code >= 0 && code < 100) ? .number(code) : codeA)
    }
    
    static var startA: BarCodeCharacter { codeTable[103].character }
    static var startB: BarCodeCharacter { codeTable[104].character }
    static var startC: BarCodeCharacter { codeTable[105].character }
    static var stop: BarCodeCharacter { codeTable[106].character }
    static var codeMap: [Character : BarCodeCharacter] = {
       var map = [Character : BarCodeCharacter]()
        for data in codeTable {
            switch data.codeB {
            case .character(let ch):
                map[ch] = data.character
            default:
                break
            }
        }
        return map
    }()

    static let codeTable: [Code128] = [
        Code128(code:  0, pattern: 2,1,2,2,2,2, codeA: .character(" "), codeB: nil, codeC: nil),
        Code128(code:  1, pattern: 2,2,2,1,2,2, codeA: .character("!"), codeB: nil, codeC: nil),
        Code128(code:  2, pattern: 2,2,2,2,2,1, codeA: .character("\""), codeB: nil, codeC: nil),
        Code128(code:  3, pattern: 1,2,1,2,2,3, codeA: .character("#"), codeB: nil, codeC: nil),
        Code128(code:  4, pattern: 1,2,1,3,2,2, codeA: .character("$"), codeB: nil, codeC: nil),
        Code128(code:  5, pattern: 1,3,1,2,2,2, codeA: .character("%"), codeB: nil, codeC: nil),
        Code128(code:  6, pattern: 1,2,2,2,1,3, codeA: .character("&"), codeB: nil, codeC: nil),
        Code128(code:  7, pattern: 1,2,2,3,1,2, codeA: .character("'"), codeB: nil, codeC: nil),
        Code128(code:  8, pattern: 1,3,2,2,1,2, codeA: .character("("), codeB: nil, codeC: nil),
        Code128(code:  9, pattern: 2,2,1,2,1,3, codeA: .character(")"), codeB: nil, codeC: nil),
        Code128(code: 10, pattern: 2,2,1,3,1,2, codeA: .character("*"), codeB: nil, codeC: nil),
        Code128(code: 11, pattern: 2,3,1,2,1,2, codeA: .character("+"), codeB: nil, codeC: nil),
        Code128(code: 12, pattern: 1,1,2,2,3,2, codeA: .character(","), codeB: nil, codeC: nil),
        Code128(code: 13, pattern: 1,2,2,1,3,2, codeA: .character("-"), codeB: nil, codeC: nil),
        Code128(code: 14, pattern: 1,2,2,2,3,1, codeA: .character("."), codeB: nil, codeC: nil),
        Code128(code: 15, pattern: 1,1,3,2,2,2, codeA: .character("/"), codeB: nil, codeC: nil),
        Code128(code: 16, pattern: 1,2,3,1,2,2, codeA: .character("0"), codeB: nil, codeC: nil),
        Code128(code: 17, pattern: 1,2,3,2,2,1, codeA: .character("1"), codeB: nil, codeC: nil),
        Code128(code: 18, pattern: 2,2,3,2,1,1, codeA: .character("2"), codeB: nil, codeC: nil),
        Code128(code: 19, pattern: 2,2,1,1,3,2, codeA: .character("3"), codeB: nil, codeC: nil),
        Code128(code: 20, pattern: 2,2,1,2,3,1, codeA: .character("4"), codeB: nil, codeC: nil),
        Code128(code: 21, pattern: 2,1,3,2,1,2, codeA: .character("5"), codeB: nil, codeC: nil),
        Code128(code: 22, pattern: 2,2,3,1,1,2, codeA: .character("6"), codeB: nil, codeC: nil),
        Code128(code: 23, pattern: 3,1,2,1,3,1, codeA: .character("7"), codeB: nil, codeC: nil),
        Code128(code: 24, pattern: 3,1,1,2,2,2, codeA: .character("8"), codeB: nil, codeC: nil),
        Code128(code: 25, pattern: 3,2,1,1,2,2, codeA: .character("9"), codeB: nil, codeC: nil),
        Code128(code: 26, pattern: 3,2,1,2,2,1, codeA: .character(":"), codeB: nil, codeC: nil),
        Code128(code: 27, pattern: 3,1,2,2,1,2, codeA: .character(";"), codeB: nil, codeC: nil),
        Code128(code: 28, pattern: 3,2,2,1,1,2, codeA: .character("<"), codeB: nil, codeC: nil),
        Code128(code: 29, pattern: 3,2,2,2,1,1, codeA: .character("="), codeB: nil, codeC: nil),
        Code128(code: 30, pattern: 2,1,2,1,2,3, codeA: .character(">"), codeB: nil, codeC: nil),
        Code128(code: 31, pattern: 2,1,2,3,2,1, codeA: .character("?"), codeB: nil, codeC: nil),
        Code128(code: 32, pattern: 2,3,2,1,2,1, codeA: .character("@"), codeB: nil, codeC: nil),
        Code128(code: 33, pattern: 1,1,1,3,2,3, codeA: .character("A"), codeB: nil, codeC: nil),
        Code128(code: 34, pattern: 1,3,1,1,2,3, codeA: .character("B"), codeB: nil, codeC: nil),
        Code128(code: 35, pattern: 1,3,1,3,2,1, codeA: .character("C"), codeB: nil, codeC: nil),
        Code128(code: 36, pattern: 1,1,2,3,1,3, codeA: .character("D"), codeB: nil, codeC: nil),
        Code128(code: 37, pattern: 1,3,2,1,1,3, codeA: .character("E"), codeB: nil, codeC: nil),
        Code128(code: 38, pattern: 1,3,2,3,1,1, codeA: .character("F"), codeB: nil, codeC: nil),
        Code128(code: 39, pattern: 2,1,1,3,1,3, codeA: .character("G"), codeB: nil, codeC: nil),
        Code128(code: 40, pattern: 2,3,1,1,1,3, codeA: .character("H"), codeB: nil, codeC: nil),
        Code128(code: 41, pattern: 2,3,1,3,1,1, codeA: .character("I"), codeB: nil, codeC: nil),
        Code128(code: 42, pattern: 1,1,2,1,3,3, codeA: .character("J"), codeB: nil, codeC: nil),
        Code128(code: 43, pattern: 1,1,2,3,3,1, codeA: .character("K"), codeB: nil, codeC: nil),
        Code128(code: 44, pattern: 1,3,2,1,3,1, codeA: .character("L"), codeB: nil, codeC: nil),
        Code128(code: 45, pattern: 1,1,3,1,2,3, codeA: .character("M"), codeB: nil, codeC: nil),
        Code128(code: 46, pattern: 1,1,3,3,2,1, codeA: .character("N"), codeB: nil, codeC: nil),
        Code128(code: 47, pattern: 1,3,3,1,2,1, codeA: .character("O"), codeB: nil, codeC: nil),
        Code128(code: 48, pattern: 3,1,3,1,2,1, codeA: .character("P"), codeB: nil, codeC: nil),
        Code128(code: 49, pattern: 2,1,1,3,3,1, codeA: .character("Q"), codeB: nil, codeC: nil),
        Code128(code: 50, pattern: 2,3,1,1,3,1, codeA: .character("R"), codeB: nil, codeC: nil),
        Code128(code: 51, pattern: 2,1,3,1,1,3, codeA: .character("S"), codeB: nil, codeC: nil),
        Code128(code: 52, pattern: 2,1,3,3,1,1, codeA: .character("T"), codeB: nil, codeC: nil),
        Code128(code: 53, pattern: 2,1,3,1,3,1, codeA: .character("U"), codeB: nil, codeC: nil),
        Code128(code: 54, pattern: 3,1,1,1,2,3, codeA: .character("V"), codeB: nil, codeC: nil),
        Code128(code: 55, pattern: 3,1,1,3,2,1, codeA: .character("W"), codeB: nil, codeC: nil),
        Code128(code: 56, pattern: 3,3,1,1,2,1, codeA: .character("X"), codeB: nil, codeC: nil),
        Code128(code: 57, pattern: 3,1,2,1,1,3, codeA: .character("Y"), codeB: nil, codeC: nil),
        Code128(code: 58, pattern: 3,1,2,3,1,1, codeA: .character("Z"), codeB: nil, codeC: nil),
        Code128(code: 59, pattern: 3,3,2,1,1,1, codeA: .character("["), codeB: nil, codeC: nil),
        Code128(code: 60, pattern: 3,1,4,1,1,1, codeA: .character("\\"), codeB: nil, codeC: nil),
        Code128(code: 61, pattern: 2,2,1,4,1,1, codeA: .character("]"), codeB: nil, codeC: nil),
        Code128(code: 62, pattern: 4,3,1,1,1,1, codeA: .character("^"), codeB: nil, codeC: nil),
        Code128(code: 63, pattern: 1,1,1,2,2,4, codeA: .character("_"), codeB: nil, codeC: nil),
        Code128(code: 64, pattern: 1,1,1,4,2,2, codeA: .nul, codeB: .character("`"), codeC: nil),
        Code128(code: 65, pattern: 1,2,1,1,2,4, codeA: .soh, codeB: .character("a"), codeC: nil),
        Code128(code: 66, pattern: 1,2,1,4,2,1, codeA: .stx, codeB: .character("b"), codeC: nil),
        Code128(code: 67, pattern: 1,4,1,1,2,2, codeA: .etx, codeB: .character("c"), codeC: nil),
        Code128(code: 68, pattern: 1,4,1,2,2,1, codeA: .eot, codeB: .character("d"), codeC: nil),
        Code128(code: 69, pattern: 1,1,2,2,1,4, codeA: .enq, codeB: .character("e"), codeC: nil),
        Code128(code: 70, pattern: 1,1,2,4,1,2, codeA: .ack, codeB: .character("f"), codeC: nil),
        Code128(code: 71, pattern: 1,2,2,1,1,4, codeA: .bel, codeB: .character("g"), codeC: nil),
        Code128(code: 72, pattern: 1,2,2,4,1,1, codeA: .bs, codeB: .character("h"), codeC: nil),
        Code128(code: 73, pattern: 1,4,2,1,1,2, codeA: .ht, codeB: .character("i"), codeC: nil),
        Code128(code: 74, pattern: 1,4,2,2,1,1, codeA: .lf, codeB: .character("j"), codeC: nil),
        Code128(code: 75, pattern: 2,4,1,2,1,1, codeA: .vt, codeB: .character("k"), codeC: nil),
        Code128(code: 76, pattern: 2,2,1,1,1,4, codeA: .ff, codeB: .character("l"), codeC: nil),
        Code128(code: 77, pattern: 4,1,3,1,1,1, codeA: .cr, codeB: .character("m"), codeC: nil),
        Code128(code: 78, pattern: 2,4,1,1,1,2, codeA: .so, codeB: .character("n"), codeC: nil),
        Code128(code: 79, pattern: 1,3,4,1,1,1, codeA: .si, codeB: .character("o"), codeC: nil),
        Code128(code: 80, pattern: 1,1,1,2,4,2, codeA: .dle, codeB: .character("p"), codeC: nil),
        Code128(code: 81, pattern: 1,2,1,1,4,2, codeA: .dc1, codeB: .character("q"), codeC: nil),
        Code128(code: 82, pattern: 1,2,1,2,4,1, codeA: .dc2, codeB: .character("r"), codeC: nil),
        Code128(code: 83, pattern: 1,1,4,2,1,2, codeA: .dc3, codeB: .character("s"), codeC: nil),
        Code128(code: 84, pattern: 1,2,4,1,1,2, codeA: .dc4, codeB: .character("t"), codeC: nil),
        Code128(code: 85, pattern: 1,2,4,2,1,1, codeA: .nak, codeB: .character("u"), codeC: nil),
        Code128(code: 86, pattern: 4,1,1,2,1,2, codeA: .syn, codeB: .character("v"), codeC: nil),
        Code128(code: 87, pattern: 4,2,1,1,1,2, codeA: .etb, codeB: .character("w"), codeC: nil),
        Code128(code: 88, pattern: 4,2,1,2,1,1, codeA: .can, codeB: .character("x"), codeC: nil),
        Code128(code: 89, pattern: 2,1,2,1,4,1, codeA: .em, codeB: .character("y"), codeC: nil),
        Code128(code: 90, pattern: 2,1,4,1,2,1, codeA: .sub, codeB: .character("z"), codeC: nil),
        Code128(code: 91, pattern: 4,1,2,1,2,1, codeA: .esc, codeB: .character("{"), codeC: nil),
        Code128(code: 92, pattern: 1,1,1,1,4,3, codeA: .fs, codeB: .character("|"), codeC: nil),
        Code128(code: 93, pattern: 1,1,1,3,4,1, codeA: .gs, codeB: .character("}"), codeC: nil),
        Code128(code: 94, pattern: 1,3,1,1,4,1, codeA: .rs, codeB: .character("~"), codeC: nil),
        Code128(code: 95, pattern: 1,1,4,1,1,3, codeA: .us, codeB: .del, codeC: nil),
        Code128(code: 96, pattern: 1,1,4,3,1,1, codeA: .fnc3, codeB: nil, codeC: nil),
        Code128(code: 97, pattern: 4,1,1,1,1,3, codeA: .fnc2, codeB: nil, codeC: nil),
        Code128(code: 98, pattern: 4,1,1,3,1,1, codeA: .shift, codeB: nil, codeC: nil),
        Code128(code: 99, pattern: 1,1,3,1,4,1, codeA: .codeC, codeB: nil, codeC: nil),
        Code128(code:100, pattern: 1,1,4,1,3,1, codeA: .codeB, codeB: .fnc4, codeC: .codeB),
        Code128(code:101, pattern: 3,1,1,1,4,1, codeA: .fnc4, codeB: .codeA, codeC: .codeA),
        Code128(code:102, pattern: 4,1,1,1,3,1, codeA: .fnc1, codeB: nil, codeC: nil),
        Code128(code:103, pattern: 2,1,1,4,1,2, codeA: .startCodeA, codeB: nil, codeC: nil), // StartA
        Code128(code:104, pattern: 2,1,1,2,1,4, codeA: .startCodeB, codeB: nil, codeC: nil), // StartB
        Code128(code:105, pattern: 2,1,1,2,3,2, codeA: .startCodeC, codeB: nil, codeC: nil), // StartC
        Code128(code:-1, pattern: 2,3,3,1,1,1,2, codeA: .stop, codeB: nil, codeC: nil) // Stop
    ]

    enum Code128Character: Equatable {
        case character(Character)
        case number(Int)
        case nul
        case soh
        case stx
        case etx
        case eot
        case enq
        case ack
        case bel
        case bs
        case ht
        case lf
        case vt
        case ff
        case cr
        case so
        case si
        case dle
        case dc1
        case dc2
        case dc3
        case dc4
        case nak
        case syn
        case etb
        case can
        case em
        case sub
        case esc
        case fs
        case gs
        case rs
        case us
        case del
        case fnc1
        case fnc2
        case fnc3
        case fnc4
        case shift
        case codeA
        case codeB
        case codeC
        case startCodeA
        case startCodeB
        case startCodeC
        case stop
        
        var character: Character? {
            switch self {
            case .character(let ch):
                return ch
            default:
                return nil
            }
        }
        
        var number: Int? {
            switch self {
            case .number(let num):
                return num
            default:
                return nil
            }
        }
    }
}


// MARK: - CODE39
struct Code39 {
    let barcode: BarCodeCharacter
    let character: Character
    
    init(_ code: Int, pattern: CGFloat..., character: Character) {
        self.barcode = BarCodeCharacter(code: code, patternArray: pattern)
        self.character = character
    }
    
    static var start: BarCodeCharacter { codeTable[39].barcode }
    static var stop: BarCodeCharacter { codeTable[39].barcode }
    static var codeMap: [Character: BarCodeCharacter] = {
       var map = [Character: BarCodeCharacter]()
        for data in codeTable {
            map[data.character] = data.barcode
        }
        return map
    }()
    static let w: CGFloat = 2.25
    static let codeTable: [Code39] = [
          Code39( 0, pattern: 1,1,1,w,w,1,w,1,1,1, character: "0"),
          Code39( 1, pattern: w,1,1,w,1,1,1,1,w,1, character: "1"),
          Code39( 2, pattern: 1,1,w,w,1,1,1,1,w,1, character: "2"),
          Code39( 3, pattern: w,1,w,w,1,1,1,1,1,1, character: "3"),
          Code39( 4, pattern: 1,1,1,w,w,1,1,1,w,1, character: "4"),
          Code39( 5, pattern: w,1,1,w,w,1,1,1,1,1, character: "5"),
          Code39( 6, pattern: 1,1,w,w,w,1,1,1,1,1, character: "6"),
          Code39( 7, pattern: 1,1,1,w,1,1,w,1,w,1, character: "7"),
          Code39( 8, pattern: w,1,1,w,1,1,w,1,1,1, character: "8"),
          Code39( 9, pattern: 1,1,w,w,1,1,w,1,1,1, character: "9"),
          Code39(10, pattern: w,1,1,1,1,w,1,1,w,1, character: "A"),
          Code39(11, pattern: 1,1,w,1,1,w,1,1,w,1, character: "B"),
          Code39(12, pattern: w,1,w,1,1,w,1,1,1,1, character: "C"),
          Code39(13, pattern: 1,1,1,1,w,w,1,1,w,1, character: "D"),
          Code39(14, pattern: w,1,1,1,w,w,1,1,1,1, character: "E"),
          Code39(15, pattern: 1,1,w,1,w,w,1,1,1,1, character: "F"),
          Code39(16, pattern: 1,1,1,1,1,w,w,1,w,1, character: "G"),
          Code39(17, pattern: w,1,1,1,1,w,w,1,1,1, character: "H"),
          Code39(18, pattern: 1,1,w,1,1,w,w,1,1,1, character: "I"),
          Code39(19, pattern: 1,1,1,1,w,w,w,1,1,1, character: "J"),
          Code39(20, pattern: w,1,1,1,1,1,1,w,w,1, character: "K"),
          Code39(21, pattern: 1,1,w,1,1,1,1,w,w,1, character: "L"),
          Code39(22, pattern: w,1,w,1,1,1,1,w,1,1, character: "M"),
          Code39(23, pattern: 1,1,1,1,w,1,1,w,w,1, character: "N"),
          Code39(24, pattern: w,1,1,1,w,1,1,w,1,1, character: "O"),
          Code39(25, pattern: 1,1,w,1,w,1,1,w,1,1, character: "P"),
          Code39(26, pattern: 1,1,1,1,1,1,w,w,w,1, character: "Q"),
          Code39(27, pattern: w,1,1,1,1,1,w,w,1,1, character: "R"),
          Code39(28, pattern: 1,1,w,1,1,1,w,w,1,1, character: "S"),
          Code39(29, pattern: 1,1,1,1,w,1,w,w,1,1, character: "T"),
          Code39(30, pattern: w,w,1,1,1,1,1,1,w,1, character: "U"),
          Code39(31, pattern: 1,w,w,1,1,1,1,1,w,1, character: "V"),
          Code39(32, pattern: w,w,w,1,1,1,1,1,1,1, character: "W"),
          Code39(33, pattern: 1,w,1,1,w,1,1,1,w,1, character: "X"),
          Code39(34, pattern: w,w,1,1,w,1,1,1,1,1, character: "Y"),
          Code39(35, pattern: 1,w,w,1,w,1,1,1,1,1, character: "Z"),
          Code39(36, pattern: 1,w,1,1,1,1,w,1,w,1, character: "-"),
          Code39(37, pattern: w,w,1,1,1,1,w,1,1,1, character: "."),
          Code39(38, pattern: 1,w,w,1,1,1,w,1,1,1, character: " "),
          Code39(39, pattern: 1,w,1,1,w,1,w,1,1,1, character: "*"),
          Code39(40, pattern: 1,w,1,w,1,w,1,1,1,1, character: "$"),
          Code39(41, pattern: 1,w,1,w,1,1,1,w,1,1, character: "/"),
          Code39(42, pattern: 1,w,1,1,1,w,1,w,1,1, character: "+"),
          Code39(43, pattern: 1,1,1,w,1,w,1,w,1,1, character: "%"),
    ]
}

// MARK: - 描画・印刷
#if os(iOS)
import UIKit

#elseif os(macOS)
import Cocoa

public extension DMBarCode {
    func print(size:CGFloat) {
        let viewWidth: CGFloat = 595
        let viewHeight: CGFloat = 842
        let view = DMBarCodePrintView(frame: NSRect(origin: CGPoint.zero, size: CGSize(width: viewWidth, height: viewHeight)))
        view.barCode = self
        view.size = size
        let op = NSPrintOperation(view: view)
        op.run()
    }
}

public class DMBarCodePrintView: NSView {
    var barCode: DMBarCode? = nil
    var size: CGFloat = 20
    
    public override func draw(_ dirtyRect: NSRect) {
        guard let barcode = self.barCode, barcode.characters.count > 0 else { return }
        if NSGraphicsContext.currentContextDrawingToScreen() == true { // 画面
        } else { // 印刷
            let height = size
            let width = CGFloat(barcode.characters.count) * height * 0.6
            let minX = dirtyRect.midX - width/2
            let minY = dirtyRect.midY - height/2
            let rect = CGRect(origin: CGPoint(x: minX, y: minY), size: CGSize(width: width, height: height))
            barcode.draw(inRect: rect)
        }
    }
    /// 1ページで印刷する
    public override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        range.pointee = NSRange(location: 1, length: 1)
        return true
    }
    
    public override func rectForPage(_ page: Int) -> NSRect {
        guard let printInfo = NSPrintOperation.current?.printInfo else { fatalError("ProjectView.knowsForPage(:)でprintInfoが取得できない") }
        return printInfo.imageablePageBounds
    }
}

#endif

#if os(tvOS)

#else
public extension DMBarCode {
    func draw(inRect rect: CGRect) {
        let minFontSize: CGFloat = 6
        let barcode = self.characters
        if barcode.isEmpty { return }
        let totalDigits = barcode.reduce(0) { $0 + $1.digits }
        let bold = rect.width / totalDigits
        let codeWidth = rect.width / CGFloat(barcode.count)
        var offset: CGFloat = 0
        let minX = rect.minX
        let minY = rect.minY
        let maxY = rect.maxY
        let fontSize = floor(codeWidth/2)
        let font = DMFont.userFont(ofSize: fontSize) ?? DMFont.systemFont(ofSize: fontSize)
        let attributes  = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: DMColor.black]
        for code in barcode {
            if fontSize >= minFontSize, let ch = code.character {
                let x = minX + bold * offset
                let y = minY - fontSize * 2
                let text = String(ch)
                let origin = CGPoint(x: x, y: y)
                let storage = NSTextStorage(string: text, attributes: attributes)
                let container = NSTextContainer()
                let manager = NSLayoutManager()
                manager.addTextContainer(container)
                storage.addLayoutManager(manager)
                let range = manager.glyphRange(for: container)
                manager.drawGlyphs(forGlyphRange: range, at: origin)
            }
            DMColor.black.set()
            var isOn = true
            for width in code.pattern {
                assert(width > 0)
                if isOn {
                    let lineWidth = bold * width
                    let x = minX + bold * offset + lineWidth/2
                    let path = DMBezierPath()
                    path.lineWidth = lineWidth
                    path.move(to: CGPoint(x: x, y: minY))
                    path.line(to: CGPoint(x: x, y: maxY))
                    path.stroke()
                }
                offset += width
                isOn = !isOn
            }
        }
    }
}
#endif

