//
//  Globals.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/15/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

enum NotificationNames {
    static let allDataReset = Notification.Name(rawValue: "AllDataReset")
}

enum Paths {
    static var certificateDirectory : String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        let appGroup = "group.org.blockcerts.cert-wallet"
        guard let groupPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            return documentDirectory
        }
        
        let certsDirectory = groupPath
            .appendingPathComponent("File Provider Storage")
            .appendingPathComponent("Certificates")
        if !FileManager.default.fileExists(atPath: certsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: certsDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return documentDirectory
            }
        }
        
        return certsDirectory.path
    }
    
    static var issuerDirectory : String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }
    
    static var all : [String] {
        return [certificateDirectory, issuerDirectory]
    }
}
