//
//  URL.swift
//  DataManager
//
//  Created by manager on 2019/03/05.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public let デスクトップURL : URL = {
    let fm = FileManager.default
    let desktopURL = try! fm.url(for: FileManager.SearchPathDirectory.desktopDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
    return desktopURL
}()

extension URL {
    var isExists : Bool {
        let url = self.standardizedFileURL
        let path = url.path
        
        let fm = FileManager.default
        return fm.fileExists(atPath: path)
    }
    
    var isDirectory : Bool? {
        let resource = try? self.resourceValues(forKeys: [.isDirectoryKey])
        return resource?.isDirectory
    }
}
