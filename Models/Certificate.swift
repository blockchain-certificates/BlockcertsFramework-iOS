//
//  Certificate.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Learning Machine. All rights reserved.
//

import Foundation

enum RevokeError : Error {
    case notImplemented
}

struct Certificate {
    let title : String
    let subtitle : String?
    let description: String
    let image : Data
    let language : String
    
    let issuer : Issuer
    let recipient : Recipient
    let assertion : Assertion
    let verifyData : Verify
    
    // Not sure if this is better as a static func or an initialization function. This has the fewest 
    static func from(file: Data) {
        
    }
    
    func toFile() -> Data {
        return Data()
    }
    
    // Is verification binary? How could this fail?
    func verify() -> Bool {
        return false
    }
    
    func revoke() throws {
        throw RevokeError.notImplemented
    }
}

