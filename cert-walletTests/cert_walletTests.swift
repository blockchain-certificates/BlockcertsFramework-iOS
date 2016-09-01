//
//  cert_walletTests.swift
//  cert-walletTests
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import XCTest
@testable import cert_wallet

class cert_walletTests: XCTestCase {
    
    func testCertificateExport() {
        // TODO: Fill out this test
        // This should build a Certificate object, then export it to JSON and validate the expected output.
    }
    
    func testCertificateVerify() {
        // TODO: Fill out this test
        // This should provide a few valid and invalid certificates. Validate each and compare the results with the expected.
    }
    
    func testCertificateRevoke() {
        // TODO: Fill out this test
        // This should take valid & invalid certificates and revoke them. 
        // Open question: how to mock out the HTTP requests that would spend the bitcoin to revoke it.
    }
    
    func testKeychainSeedPhraseGeneration() {
        let seedData = Data(count: 32)
        let expectedMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"
        let mnemonic = Keychain.generateSeedPhrase(withRandomData: seedData)
        print("Got mnemonic: \(mnemonic)")
        
        XCTAssertTrue(mnemonic.characters.count > 0, "Mnemonic phrase should not be empty")
        XCTAssertEqual(mnemonic, expectedMnemonic, "0-seed should generate simple mnemonic phrase")
    }
    
    func testKeychainKeyGeneration() {
        let seedPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"

        let keychain = Keychain(seedPhrase: seedPhrase, unusedKeyIndex: 0)
        
        let firstKey = keychain.nextPublicKey()
        let secondKey = keychain.nextPublicKey()
        
        XCTAssertEqual(firstKey, "03885da437c0c5b76d3afd29852acf78237d2341b8662cb2438e13d91845942764")
        XCTAssertEqual(secondKey, "028b8f132faf5dbd659efdf80a5d18aa6b421f2f1e6d1f58dd57a4d3170688a306")
    }
    
    func testKeychainSearch() {
        let seedPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"
        
        let keychain = Keychain(seedPhrase: seedPhrase)
        
        let firstKey = "03885da437c0c5b76d3afd29852acf78237d2341b8662cb2438e13d91845942764"
        let secondKey = "028b8f132faf5dbd659efdf80a5d18aa6b421f2f1e6d1f58dd57a4d3170688a306"
        
        XCTAssertTrue(keychain.has(publicKey: firstKey))
        XCTAssertTrue(keychain.has(publicKey: secondKey))
    }
}
