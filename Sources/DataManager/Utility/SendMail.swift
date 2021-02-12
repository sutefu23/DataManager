//
//  SendMail.swift
//  DataManager
//
//  Created by KANRI-6 on 2020/12/25.
//

import Foundation

enum MailError: LocalizedError {
    case notSupport
    case spaceNotAllowInSpace
    case notValidMailFormat
    case pythonRaiseError

    var errorDescription: String{
        switch self {
        case .notSupport:
            return "OSがサポートされていません"
        case .spaceNotAllowInSpace:
            return "タイトルにスペースを入れることはできません"
        case .notValidMailFormat:
            return "メールの形式が異なります"
        default:
            return "メール送信でエラーが起きました"
        }
    }
}

@available(OSX 10.13, *)
public func sendMail(mail_from: String ,mail_to: String, title: String, body: String) throws {
    #if os(macOS) || os(Linux)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    let bundle = Bundle.dataManagerBundle

    guard let app = bundle.url(forResource: "sendMail", withExtension: "py") else {
        NSLog("sendMail.pyが見つかりません")
        return
    }

    

    //コマンドライン引数＝[送信元、受信先、タイトル、本文]
    process.arguments = [app.path, mail_from, mail_to, title, body]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    let handle = pipe.fileHandleForReading
    let data = handle.readDataToEndOfFile()
    
    guard let returnValue = String(data: data, encoding: .utf8) else{ return }
    
    if returnValue.hasPrefix("!") {

        
    }

    #else
    throw MailError.notsupport
    #endif
    
}
func isValidEmail(_ string: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: string)
        return result
 }
