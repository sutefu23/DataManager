//
//  SendMail.swift
//  DataManager
//
//  Created by KANRI-6 on 2020/12/25.
//

import Foundation

public struct MailServer: Codable {
    var host: String
    var username: String
    var password: String
    var port: Int
    var method: MailMethod
    public init(host: String , username: String, password: String, port: Int, method: MailMethod){
        self.host = host
        self.username = username
        self.password = password
        self.port = port
        self.method = method
    }
    
    @available(OSX 10.13, *)
    public func sendMail(mail: MailBody) throws {
        try DataManager.sendMail(mail: mail, server: self)
    }
}

public enum MailMethod: String, Codable{
    public typealias RawValue = String
    case noEncript = "rawvalue"
    case startTLS = "starttls"
    case SSL = "ssl"
}

public struct MailBody {
    var from: String
    var to: String
    var cc: String = ""
    var title: String
    var body: String
    var file: URL?
    public init(from: String, to: String, cc: String, title: String, body:String, file: URL? = nil){
        self.from = from
        self.to = to
        self.cc = cc
        self.title = title
        self.body = body
        self.file = file
    }
}

public enum MailError: LocalizedError {
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
public func sendMail(mail: MailBody, server: MailServer) throws {
    #if os(macOS) || os(Linux)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    let bundle = Bundle.dataManagerBundle

    guard let app = bundle.url(forResource: "sendMail", withExtension: "py") else {
        NSLog("sendMail.pyが見つかりません")
        return
    }

    ///サーバー設定のjson保存(sendMail.pyから参照)
    let jsonEncoder = JSONEncoder()
    do {
        let jsonData = try jsonEncoder.encode(server)
        guard let json = String(data: jsonData, encoding: .utf8) else {
            return
        }
        guard let confFile = bundle.url(forResource: "mailConfig", withExtension: "json") else {
            NSLog("mailConfig.jsonが見つかりません")
            return
        }
        
        try json.write(to: confFile, atomically: false, encoding: .utf8)

    } catch let error {
        error.showAlert()
    }

    /// コマンドライン引数＝[送信元、受信先、タイトル、本文、（添付ファイル）]
    var attach = ""
    if let file = mail.file {
        /// 一時ファイルとしてコピー
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(file.filename + "." + file.pathExtension )
        try? FileManager.default.removeItem(at: tmp)
        try FileManager.default.copyItem(at: file, to: tmp)
        attach = tmp.path
    }

    process.arguments = [app.path, mail.from, mail.to, mail.cc, attach, mail.title, mail.body ]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    let handle = pipe.fileHandleForReading
    let data = handle.readDataToEndOfFile()
    
    guard let returnValue = String(data: data, encoding: .utf8) else{ return }
    
    if returnValue.hasPrefix("!") {
        showMessage(message: "メール送信に失敗しました。\n" + returnValue)
    }

    #else
    throw MailError.notSupport
    #endif
    
}
public func isValidEmail(_ string: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: string)
        return result
 }
