//
//  ICCard.swift
//  DataManager
//
//  Created by manager on 2020/10/14.
//

import Foundation

enum CardError: LocalizedError {
    case ncInterface
    
    init(_ str: String) {
        self = .ncInterface
    }
    
    var errorDescription: String? {
        return "カードリーダーが接続されていません"
    }
}

public struct DMCardReader {
    /// カードリーダーからカードIDを読み取る
    @available(OSX 10.13, *)
    public func scanCardID() throws -> String? {
        #if os(macOS) || os(Linux) 
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        let bundle = Bundle.dataManagerBundle
        let test = bundle.url(forResource: "scanICCard", withExtension: "py")!
        process.arguments = [test.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        
        guard let idstr = String(data: data, encoding: .utf8), !idstr.isEmpty else { return nil }
        if idstr.hasPrefix("!") {
            throw CardError(idstr)
        }
        return idstr
        #else
        throw CardError.ncInterface
        #endif
    }
}
