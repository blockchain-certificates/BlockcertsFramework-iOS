//
//  Keychain.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation
import Security

class Keychain {
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
    
    
    func nextPublicKey() -> String {
        let key = accountKeychain.key(at: unusedKeyIndex)
        unusedKeyIndex += 1
        
        return key?.publicKey.hex() ?? ""
    }
    
    func has(publicKey : String) -> Bool {
        guard let keyData = publicKey.asHexData() else {
            // If the publicKey isn't a valid hex string, then this keychain obviously doesn't have it.
            return false
        }
        
        let key = BTCKey(publicKey: keyData)
        let limit : UInt = 10 // arbitrary. What's a good limit?
        
        return nil == accountKeychain.find(forPublicKey: key, hardened: true, limit: limit) // Also unsure of hardened value.
    }
}

extension Keychain {
    static private var seedPhraseKey = "org.blockcerts.seed-phrase"
    static var shared : Keychain {
        //
        // Check existence of the seed phrase, and pull it out if it's there.
        //
        let query : [String : Any] = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): seedPhraseKey,
            String(kSecReturnData): kCFBooleanTrue,
            String(kSecMatchLimit): kSecMatchLimitOne
        ]
        
        var dataTypeRef : CFTypeRef?
        var result = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        switch result {
        case noErr:
            print("No err")
            if dataTypeRef != nil {
                let data = dataTypeRef! as! Data
                let keyPhrase = String(data: data, encoding: .utf8)
                print(keyPhrase)
            }
            //        case paramErr:
        //            print("Param err")
        case errSecSuccess:
            print("success")
        case errSecUnimplemented:
            print("Unimplemented")
        case errSecParam:
            print("param")
        case errSecAllocate:
            print("Allocate")
        case errSecNotAvailable:
            print("Not available")
        case errSecAuthFailed:
            print("Auth failed")
        case errSecDuplicateItem:
            print("Duplicate item")
        case errSecItemNotFound:
            print("Not found")
        case errSecInteractionNotAllowed:
            print("Interaction not allowed")
        case errSecDecode:
            print("Decode")
        default:
            print("Not sure what to do with this error code \(result)")
        }

        //
        // Generate a seed phrase, save it to the keychain.
        //
        let phrase = Keychain.generateSeedPhrase()
        
        let attributes : [String : Any] = [
            String(kSecClass) : kSecClassGenericPassword,
            String(kSecAttrAccount) : seedPhraseKey,
            String(kSecValueData) : phrase.data(using: .utf8)!
        ]
        var returnValue : CFTypeRef?
        result = SecItemAdd(attributes as CFDictionary, &returnValue)
        
        switch result {
        case noErr:
            print("No err")
//        case paramErr:
//            print("Param err")
        case errSecSuccess:
            print("success")
        case errSecUnimplemented:
            print("Unimplemented")
        case errSecParam:
            print("param")
        case errSecAllocate:
            print("Allocate")
        case errSecNotAvailable:
            print("Not available")
        case errSecAuthFailed:
            print("Auth failed")
        case errSecDuplicateItem:
            print("Duplicate item")
        case errSecItemNotFound:
            print("Not found")
        case errSecInteractionNotAllowed:
            print("Interaction not allowed")
        case errSecDecode:
            print("Decode")
        default:
            print("Not sure what to do with this error code \(result)")
        }
        
        return Keychain(seedPhrase: phrase)
    }
}
