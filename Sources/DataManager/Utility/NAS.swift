//
//  NAS.swift
//  NCEngine
//
//  Created by 四熊泰之 on 2019/04/20.
//  Copyright © 2019 四熊 泰之. All rights reserved.
//

import Foundation

#if os(macOS)
import NetFS
import Cocoa

/// ネットワーク接続の種類
public enum NFSType: String {
    /// SMB接続
    case smb = "smb"
    /// APF接続
    case afp = "afp"
    /// CIFS接続
    case cifs = "cifs"
}

public struct NASServer: Hashable {
    public static let nas1 = NASServer(name: "NAS", ip: "192.168.1.206")
    public static let backup1 = NASServer(name: "Backup", ip: "192.168.1.207")
    public static let nas4 = NASServer(name: "NAS4", ip: "192.168.1.208")
    
    var name: String
    var ip: String
}

public enum NAS4User: Int, RawRepresentable, Hashable, Identifiable {
    public var id: Int { return self.rawValue }
    
    case 管理者 = 1
    case 営業 = 2
    case 営繕 = 3
    case フォーミング = 4
    case 外注 = 5
    case 原稿 = 6
    case 半田 = 7
    case 発送 = 8
    case 品質管理 = 9
    case 腐蝕 = 10
    case 付属品準備 = 11
    case 表面仕上 = 12
    case 加工 = 13
    case 管理 = 14
    case 経理 = 15
    case 研磨 = 16
    case 組立検品 = 17
    case 切文字 = 18
    case レーザー = 19
    case 水処理 = 20
    case 入力 = 21
    case オブジェ = 22
    case ルーター = 23
    case 照合 = 24
    case 資材 = 25
    case 塗装 = 26
    case 溶接 = 27
    case 複合機 = 28
    
    public var account: NASUser {
        switch self {
        case .管理者: return NASUser(account: "admin", password: "7FWLT4Qk")
        case .営業: return NASUser(account: "eigyo", password: "vMD2d4wH")
        case .営繕: return NASUser(account: "eizen", password: "enu3YqJg")
        case .フォーミング: return NASUser(account: "fomingu", password: "NSd3xc6Y")
        case .外注: return NASUser(account: "gaityuu", password: "pp6wZd5A")
        case .原稿: return NASUser(account: "genko", password: "g2pTnHdp")
        case .半田: return NASUser(account: "handa", password: "FUP6MxGU")
        case .発送: return NASUser(account: "hassou", password: "98gSdgc3")
        case .品質管理: return NASUser(account: "hinsitu", password: "2xG8EbeS")
        case .腐蝕: return NASUser(account: "husyoku", password: "V6mqXAVn")
        case .付属品準備: return NASUser(account: "huzokuhin", password: "Ad8WdEqt")
        case .表面仕上: return NASUser(account: "hyoumen", password: "mQjcdDy2")
        case .加工: return NASUser(account: "kakou", password: "B8bXrhxg")
        case .管理: return NASUser(account: "kanri", password: "Q2ycbVML")
        case .経理: return NASUser(account: "keiri", password: "py4H2UY6")
        case .研磨: return NASUser(account: "kenma", password: "tAVAT94y")
        case .組立検品: return NASUser(account: "kenpin", password: "Yh8cDyaK")
        case .切文字: return NASUser(account: "kirimoji", password: "bc8Gr5D2")
        case .レーザー: return NASUser(account: "laser", password: "mDxGSzr9")
        case .水処理: return NASUser(account: "mizusyori", password: "nQr6Q8ga")
        case .入力: return NASUser(account: "nyuryoku", password: "T57kBrVg")
        case .オブジェ: return NASUser(account: "obuje", password: "Ze7wQbQM")
        case .ルーター: return NASUser(account: "ruta", password: "45NuxdZT")
        case .照合: return NASUser(account: "shougou", password: "H8ADKDdh")
        case .資材: return NASUser(account: "sizai", password: "T3jWwkvx")
        case .塗装 : return NASUser(account: "tosou", password: "CwUJJ33D")
        case .溶接: return NASUser(account: "yosetu", password: "S3YE23kQ")
        case .複合機: return NASUser(account: "scan", password: "scan")
        }
    }
}


public struct NASUser: Hashable {
    var account: String
    var password: String
    
    init(account: String, password: String) {
        self.account = account
        self.password = password
    }
}

final class NASConnection : Equatable {
    private(set) var server: String
    private let server2: String?
    let type: NFSType
    let volume: String
    let account: String
    let password: String
    
    var mountPoint: URL? = nil
    var showError = true
    public private(set) var disconnected: Bool = false
    
    private var keepWorker: DispatchWorkItem? = nil
    
    static func == (left: NASConnection, right: NASConnection) -> Bool {
        return
            left.server == right.server &&
            left.server2 == right.server2 &&
            left.type == right.type &&
            left.volume == right.volume &&
            left.account == right.account &&
            left.password == right.password
    }
    
    init?(server: NASServer, type: NFSType, volume: String, user: NASUser) {
        self.server = server.name
        self.type = type
        self.volume = volume
        self.account = user.account
        self.password = user.password
        self.server2 = server.ip
    }
    
    init?(server: String, type: NFSType, volume: String, account: String, password: String) {
        self.server = server
        self.type = type
        self.volume = volume
        self.account = account
        self.password = password
        self.server2 = server
    }
    
    func mountNAS() -> Bool {
        if mountNASBasic(server: self.server) == true { return true }
        guard let server2 = self.server2 else { return false }
        return mountNASBasic(server: server2) == true
    }
    
    private func mountNASBasic(server: String) -> Bool? {
        if server.isEmpty  || volume.isEmpty { return nil }
        let mountPoint = URL(fileURLWithPath: "/Volumes/").appendingPathComponent(volume)
        self.mountPoint = mountPoint

        if (try? mountPoint.checkResourceIsReachable()) == true { return true } // 既に接続中
        
        guard let serverURL = URL(string: "\(type.rawValue)://\(server)")?.appendingPathComponent(volume) else { return nil }
        let result: Int32
        if account.isEmpty {
            let openDic = NSMutableDictionary()
            openDic.setObject(true, forKey: kNetFSUseGuestKey as NSString)
            result = NetFSMountURLSync(serverURL as NSURL, nil, nil, nil, openDic, nil, nil)
        } else {
            result = NetFSMountURLSync(serverURL as NSURL, nil, account as NSString, password as NSString, nil, nil, nil)
        }
        self.mountPoint = mountPoint
        return result == 0 || result == 17 // ok or File Exists
    }
    
    func keepAction() -> Bool {
        let fm = FileManager.default
        guard let mountPoint = self.mountPoint else { return false }
        do {
            let _ = try fm.contentsOfDirectory(at: mountPoint, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants, .skipsHiddenFiles])
            return true
        } catch {
            if self.mountNAS() { return true }
            if showError { // ダイアログ表示中はエラーダイアログを発行しない
                showError = false
                OperationQueue.main.addOperation {
                    NSAlert.showAlert("\(self.server)の\(self.volume)との接続が切れています")
                    self.showError = true // 閉じたら次を許可する
                }
            }
            return false
        }
    }
}

public final class MountManager {
    public static var isEnabled = true
    public static let shared = MountManager()

    private let keepQueue = DispatchQueue(label: "KeepQueue.NCEngine.shikuma")
    private var keepWorker: DispatchWorkItem? = nil
    private var keepIndex: Int = 1 // これにより0から開始する
    private var connections: [NASConnection] = []
    
    init() {}
    
    @discardableResult public func mountNAS(server: NASServer, type: NFSType, volume: String, user: NASUser) -> Bool {
        if !MountManager.isEnabled { return false }
        defer { update() }
        guard let connection = NASConnection(server: server, type: type, volume: volume, user: user) else { return false }
        return self.mount(connection)
    }

    @discardableResult public func mountNAS(server: String, type: NFSType, volume: String, account: String, password: String) -> Bool {
        if !MountManager.isEnabled { return false }
        defer { update() }
        guard let connection = NASConnection(server: server, type: type, volume: volume, account: account, password: password) else { return false }
        return self.mount(connection)
    }
    
    func mount(_ connection: NASConnection) -> Bool {
        let result = connection.mountNAS()
        keepQueue.async { self.append(connection) }
        return result
    }
    
    public func mount受け渡し(user: NAS4User = .レーザー) {
        mountNAS(server: .nas4, type: .smb, volume: "受け渡し", user: user.account)
    }

    public func mount部署専用(user: NAS4User = .レーザー) {
        mountNAS(server: .nas4, type: .smb, volume: "部署専用", user: user.account)
    }
    
    public func terminate() {
        keepQueue.sync { self.stopKeep() }
    }

    private func append(_ connection: NASConnection) {
        if !self.connections.contains(connection) {
            connections.append(connection)
        }
    }
    
    func update() {
        keepQueue.async { self.prepareKeep() }
    }
    
    private func prepareKeep() {
        if keepWorker != nil { return }
        func nextIndex(of index: Int) -> Int? {
            let newIndex = index+1
            if self.connections.count <= newIndex {
                return self.connections.isEmpty ? nil : 0
            }
            return newIndex
        }
        var keepInterval = defaults.keepInterval
        guard let index = nextIndex(of: self.keepIndex), keepInterval <= 0 else {
            self.keepWorker?.cancel()
            self.keepWorker = nil
            return
        }
        if keepInterval < 30 { keepInterval = 30 }
        self.keepIndex = index
        let connection = connections[index]
        let item = DispatchWorkItem {
            let _ = connection.keepAction()
            self.keepWorker = nil
            self.update()
        }
        self.keepWorker = item
        keepQueue.asyncAfter(deadline: .now() + keepInterval, execute: item)
    }
    
    private func stopKeep() {
        self.keepWorker?.cancel()
        self.keepWorker = nil
        self.connections.removeAll()
    }
}

public extension UserDefaults {
    /// NAS接続の持続のための定期アクセス間隔
    var keepInterval: TimeInterval {
        get { double(forKey: "keepInterval") }
        set {
            if keepInterval == newValue { return }
            setValue(newValue, forKey: "keepInterval")
            MountManager.shared.update()
        }
    }
}

#endif
