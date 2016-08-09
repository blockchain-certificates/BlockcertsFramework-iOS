//
//  Keychain.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

struct Keychain {
    let seedPhrase : String
    
    static func generateSeedPhrase() -> String {
        return ""
    }
    
    func nextPublicKey() -> String {
        return ""
    }
    
    func has(publicKey : String) -> Bool {
        return false
    }
//    func has(keyForRecipient : Recipient) -> Bool {
//        return false
//    }
}
