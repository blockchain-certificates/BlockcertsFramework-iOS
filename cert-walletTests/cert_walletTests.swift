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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // This will probably make more sense to refactor into different files once these methods actually do useful work
    func testCertificateImport() {
        // TODO: Fill out this test.
        // This should take test files or in-memory JSON, construct a Certificate object, then validate its fields
    }
    
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
        // TODO: Re-enable this assertion once we have seed phrase generation
//        let mnemonic = Keychain.generateSeedPhrase()
//        XCTAssertTrue(mnemonic.characters.count > 0, "Mnemonic phrase should not be empty")
    }
    
    func testKeychainKeyGeneration() {
        let seedPhrase = "constant test seed phrase"
        let keychain = Keychain(seedPhrase: seedPhrase)
        
        let firstKey = keychain.nextPublicKey()
        let secondKey = keychain.nextPublicKey()
        
        // TODO: Replace these tests with actual keys
        XCTAssertEqual(firstKey, "")
        XCTAssertEqual(secondKey, "")
    }

    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
