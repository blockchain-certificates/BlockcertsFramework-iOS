//
//  Keychain.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

struct Keychain {
    var seedPhrase : String {
        return mnemonic.words.flatMap({ $0 as? String}).joined(separator: " ")
    }
    private var unusedKeyIndex : UInt32 = 0
    private let mnemonic : BTCMnemonic
    private let keychain : BTCKeychain
    private let accountKeychain : BTCKeychain
    
    init(seedPhrase: String) {
        let words = seedPhrase.components(separatedBy: " ")
        guard let mnemonic = BTCMnemonic(words: words, password: "", wordListType: .english) else {
            fatalError("Can't start a Keychain with invalid phrase:\"\(seedPhrase)\"")
        }
        self.mnemonic = mnemonic
        keychain = BTCKeychain(seed: mnemonic.data)
        accountKeychain = keychain.derivedKeychain(withPath: "m/44'/0'/0'")
    }
    
    static func generateSeedPhrase() -> String {
        let randomData = BTCRandomDataWithLength(32) as Data
        return generateSeedPhrase(withRandomData: randomData)
    }
    
    static func generateSeedPhrase(withRandomData randomData: Data) -> String {
        let mn = BTCMnemonic(entropy: randomData, password: "", wordListType: .english)
        
        return mn?.words.flatMap({ $0 as? String }).joined(separator: " ") ?? ""
    }
    
    
    mutating func nextPublicKey() -> String {
        let key = accountKeychain.key(at: unusedKeyIndex)
        unusedKeyIndex += 1
        
        return key?.publicKey.hex() ?? ""
    }
    
    func has(publicKey : String) -> Bool {
//        let key = BTCKey(publicKey: <#T##Data!#>)
//        accountKeychain.find(forPublicKey: <#T##BTCKey!#>, hardened: <#T##Bool#>, limit: <#T##UInt#>)
        return false
    }
//    func has(keyForRecipient : Recipient) -> Bool {
//        return false
//    }
}
