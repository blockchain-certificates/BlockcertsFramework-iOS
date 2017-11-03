//
//  cert_walletTests.swift
//  cert-walletTests
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import XCTest
//@testable import cert_wallet

class KeychainTests: XCTestCase {
    func testKeychainSeedPhraseGeneration() {
        let seedData = Data(count: 32)
        let expectedMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"
        let mnemonic = Keychain.generateSeedPhrase(withRandomData: seedData)
        
        XCTAssertTrue(mnemonic.count > 0, "Mnemonic phrase should not be empty")
        XCTAssertEqual(mnemonic, expectedMnemonic, "0-seed should generate simple mnemonic phrase")
    }
    
    func testKeychainAddressGeneration() {
        let seedPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"

        let keychain = Keychain(seedPhrase: seedPhrase, unusedKeyIndex: 0)
        
        let firstAddress = keychain.nextPublicAddress()
        let secondAddress = keychain.nextPublicAddress()
        
        XCTAssertEqual(firstAddress, "1KBdbBJRVYffWHWWZ1moECfdVBSEnDpLHi")
        XCTAssertEqual(secondAddress, "1EiJMaaahrhpbhgaNzMeUe1ZoiXdbBhWhR")
    }
    
    func testKeychainSearch() {
        let seedPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"
        
        let keychain = Keychain(seedPhrase: seedPhrase)
        
        let firstKey = "03885da437c0c5b76d3afd29852acf78237d2341b8662cb2438e13d91845942764"
        let secondKey = "028b8f132faf5dbd659efdf80a5d18aa6b421f2f1e6d1f58dd57a4d3170688a306"
        
        XCTAssertTrue(keychain.has(publicKey: firstKey))
        XCTAssertTrue(keychain.has(publicKey: secondKey))
    }
    
    func testKeychainValidPhrase() {
        let seedPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"
        
        XCTAssertTrue(Keychain.isValidPassphrase(seedPhrase))
    }
    
    func testKeychainInvalidPhrase() {
        let invalidPhrase = "This phrase is too short and not random enough"
        
        XCTAssertFalse(Keychain.isValidPassphrase(invalidPhrase))
    }
}
