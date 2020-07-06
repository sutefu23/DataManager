//
//  DMFormula.swift
//  DataManager
//
//  Created by 四熊泰之 on R 2/05/05.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - 数値変換
/// 数式文字列 -> Double
public extension Double {
    init(formula: String) throws {
        var formula = DMFormula(formula)
        self = try formula.calc()
    }
    
    init?(optionalFormula: String?) {
        guard let string = optionalFormula else { return nil }
        var formula = DMFormula(string)
        guard let value = formula.result else { return nil }
        self = value
    }
}

public extension CGFloat {
    init(formula: String) throws {
        let result = try Double(formula: formula)
        self = CGFloat(result)
    }
    
    init?(optionalFormula: String) {
        guard let value = try? CGFloat(formula: optionalFormula) else { return nil }
        self = value
    }
    
}

public extension Int {
    init(formula: String) throws {
        let result = try Double(formula: formula)
        guard let value = Int(exactly: result) else { throw DataManagerError.needsNumberString }
        self = value
    }
    
    init?(optionalFormula: String) {
        guard let value = try? Int(formula: optionalFormula) else { return nil }
        self = value
    }
}

// MARK: -
public struct DMFormula: ExpressibleByStringLiteral {
    public enum NCFormulaError: LocalizedError {
        case noOperator
        case noValue
        case emptyParen
        case internalError
        case dividedBy0
        case invalueResult
        
        public var errorDescription: String? {
            switch self {
            case .noOperator: return "演算子がない"
            case .noValue: return "数値がない"
            case .emptyParen: return "カッコの中が空欄"
            case .internalError: return "内部エラー"
            case .dividedBy0: return "0で割ろうとした"
            case .invalueResult: return "計算不能"
            }
        }
    }
    private enum CalcOperator: Int8, Comparable {
        static let map: [Character: CalcOperator] = [ "+": .plus, "-": .minus, "*": .mul, "/": .div, "%": .mod ]
        case mul = 0
        case div = 1
        case mod = 2
        case plus = 3
        case minus = 4
        
        var priority: Int8 { self.rawValue / 2 }
        var isFirstOp: Bool { self.priority == 0 }
        
        static func < (left: CalcOperator, right: CalcOperator) -> Bool {
            return left.rawValue < right.rawValue
        }
    }
    private enum CalcFunction: String, CaseIterable {
        case func_sin = "SIN"
        case func_cos = "COS"
        case func_tan = "TAN"
        case func_log = "LOG"
        case func_exp = "EXP"
        case func_atan = "ATAN"
        case func_acos = "ACOS"
        case func_asin = "ASIN"
        case func_abs = "ABS"
        case func_sqrt = "SQRT"
        case func_ceil = "CEIL"
        case func_floor = "FLOOR"
        case func_round = "ROUND"
        case func_pow = "POW"
        case func_hypot = "HYPOT"
        case func_atan2 = "ATAN2"
        case func_min = "MIN"
        case func_max = "MAX"
        
        func exec(_ formula: inout DMFormula) throws -> Double {
            func getValue() throws -> Double { return try formula.calc() }
            func get2Values() throws -> (Double, Double) {
                let left = try formula.calc(terminator: ",")
                let right = try formula.calc()
                return (left, right)
            }
            func degree(of radian :Double) -> Double { radian * 180.0 / .pi }
            func radian(of degree: Double) -> Double { degree * .pi / 180.0 }
            switch self {
            case .func_sin:
                let degree = try formula.calc()
                return sin(radian(of: degree))
            case .func_cos:
                let degree = try formula.calc()
                return cos(radian(of: degree))
            case .func_tan:
                let degree = try formula.calc()
                return tan(radian(of: degree))
            case .func_log:
                return log10(try getValue())
            case .func_exp:
                return exp(try getValue())
            case .func_ceil:
                return ceil(try getValue())
            case .func_floor:
                return floor(try getValue())
            case .func_round:
                return round(try getValue())
            case .func_atan:
                let rad = atan(try getValue())
                return degree(of: rad)
            case .func_acos:
                let rad = acos(try getValue())
                return degree(of: rad)
            case .func_asin:
                let rad = asin(try getValue())
                return degree(of: rad)
            case .func_abs:
                return abs(try getValue())
            case .func_sqrt:
                return sqrt(try getValue())
            case .func_hypot:
                let (left, right) = try get2Values()
                return hypot(left, right)
            case .func_atan2:
                let (left, right) = try get2Values()
                let rad = atan2(left, right)
                return degree(of: rad)
            case .func_min:
                let (left, right) = try get2Values()
                return min(left, right)
            case .func_max:
                let (left, right) = try get2Values()
                return max(left, right)
            case .func_pow:
                let (left, right) = try get2Values()
                return pow(left, right)
            }
        }
    }
    
    private var scanner: DMScanner
    private var operators: [CalcOperator] = []
    private var currentOp: CalcOperator? = nil
    private var values: [Double] = []
    private var variables: [String: Double] = [:]
    
    private func makeChild(_ formula: String) -> DMFormula {
        var child = DMFormula(formula)
        child.variables = self.variables
        return child
    }
    
    public subscript(_ key: String) -> Double? {
        get { return variables[key.uppercased()] }
        set { variables[key.uppercased()] = newValue }
    }
    
    public init(_ formula: String, variables: [String: Double] = [:]) {
        self.scanner = DMScanner(formula, normalizedFullHalf: false, upperCased: true, skipSpaces: true)
        for (key, value) in variables { self[key] = value }
        scanner.dropTailSpaces()
    }
    
    public init(stringLiteral: String) {
        self.init(stringLiteral)
    }
    
    private mutating func pushValue() throws {
        let value = try scanValue()
        values.append(value)
    }
    
    private mutating func scanValue() throws -> Double {
        if scanner.isFirstLetter() {
            for (key, value) in variables {
                if scanner.scanString(key) {
                    return value
                }
            }
            if scanner.scanString("PI") { return Double.pi }
            for f in CalcFunction.allCases {
                if scanner.scanString(f.rawValue) {
                    guard let string = scanner.scanParen("(", ")")?.contents, !string.isEmpty else { throw NCFormulaError.emptyParen }
                    var formula = makeChild(string)
                    return try f.exec(&formula)
                }
            }
        }
        if scanner.testCharacter("(") {
            guard let string = scanner.scanParen("(", ")")?.contents, !string.isEmpty else { throw NCFormulaError.emptyParen }
            var formula = makeChild(string)
            return try formula.calc()
        } else {
            guard let value = scanner.scanDouble() else { throw NCFormulaError.noValue }
            return value
        }
    }
    
    private mutating func scanOperator() throws -> CalcOperator {
        if let ch = scanner.fetchCharacter(), let op = CalcOperator.map[ch] { return op }
        throw NCFormulaError.noOperator
    }
    
    private mutating func execLastOperator() throws {
        guard let op = operators.popLast(), let value2 = values.popLast(), let value1 = values.popLast() else { throw NCFormulaError.internalError }
        let result: Double
        switch op {
        case .plus:
            result = value1 + value2
        case .minus:
            result = value1 - value2
        case .mul:
            result = value1 * value2
        case .div:
            if value2.isZero { throw NCFormulaError.dividedBy0 }
            result = value1 / value2
        case .mod:
            result = value1.truncatingRemainder(dividingBy: value2)
        }
        values.append(result)
    }
    
    public mutating func calc(terminator: Character? = nil) throws -> Double {
        try pushValue()
        while scanner.isAtEnd == false {
            if let term = terminator, scanner.scanCharacter(term) { break }
            let op = try scanOperator()
            while let last = operators.last, last <= op { try execLastOperator() }
            operators.append(op)
            try pushValue()
        }
        while operators.isEmpty == false { try execLastOperator() }
        guard let result = values.popLast(), values.isEmpty else { throw NCFormulaError.internalError }
        if result.isInfinite || result.isNaN { throw NCFormulaError.invalueResult }
        return result
    }
    
    public var result: Double? {
        mutating get {
            guard let result = (try? self.calc()) else { return nil }
            return Double(result)
        }
    }
}
