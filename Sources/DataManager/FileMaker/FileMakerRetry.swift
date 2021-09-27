//
//  FileMakerRetry.swift
//  DataManager
//
//  Created by 四熊泰之 on R 3/09/25.
//

import Foundation

/// リトライシステム。サーバー停止などの際に出力を記録しておいて後日再出力する（予定）
class FileMakerRetrySystem {
    
    
    
    
}

/// リトライシステムに対応するオブジェクトの要件定義
public protocol FileMakerBackupObject: FileMakerObject {
    associatedtype BackupObject
    
    static func makeTableGenerator() -> TableGenerator<BackupObject>
    static var filaname: String { get }

    init?(_ line: String) throws
}

public extension FileMakerBackupObject {
    static var filename: String { "\(name)-retry.csv" }
}
