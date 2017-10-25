//
//  KeyTests.swift
//  BlockcertsTests
//
//  Created by Chris Downie on 10/24/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import Blockcerts

class BlockchainAddressTests: XCTestCase {
    
    func testConstructor() {
        let unscope = BlockchainAddress(value: "FAKE_VALUE")
        XCTAssertEqual(unscope.value, "FAKE_VALUE")
        XCTAssertNil(unscope.scope)
        
        let scoped = BlockchainAddress(value: "ALTERNATE_VALUE", scope: "ecdsa-koblitz-pubkey")
        XCTAssertEqual(scoped.value, "ALTERNATE_VALUE")
        XCTAssertEqual(scoped.scope, "ecdsa-koblitz-pubkey")
        XCTAssertEqual(scoped.scopedValue, "ecdsa-koblitz-pubkey:ALTERNATE_VALUE")
    }
    
    func testUnscopedCopy() {
        let unscoped = BlockchainAddress(value: "FAKE_VALUE")
        let scoped = BlockchainAddress(value: "FAKE_VALUE", scope: "ecdsa-koblitz-pubkey")
        XCTAssertEqual(scoped.unscoped, unscoped)
    }
    
    func testEquatable() {
        let scoped = BlockchainAddress(value: "VALUE", scope: "ecdsa-koblitz-pubkey")
        let unscoped = BlockchainAddress(value: "VALUE")
        
        XCTAssertEqual(unscoped, scoped)
        
        let altScoped = BlockchainAddress(value: "VALUE", scope: "alternate-ecdsa-koblitz-pubkey")
        let altValue = BlockchainAddress(value: "ALTERNATE_VALUE", scope: "ecdsa-koblitz-pubkey")
        XCTAssertNotEqual(scoped, altScoped)
        XCTAssertNotEqual(scoped, altValue)
        
        XCTAssertEqual(scoped.unscoped, altScoped.unscoped)
    }
    
    func testStringConstructor() {
        let key = BlockchainAddress(string: "ecdsa-koblitz-pubkey:VALUE")
        
        XCTAssertEqual(key.scope, "ecdsa-koblitz-pubkey")
        XCTAssertEqual(key.value, "VALUE")
        
        let unscopedKey = BlockchainAddress(string: "ALT_VALUE")
        
        XCTAssertNil(unscopedKey.scope)
        XCTAssertEqual(unscopedKey.value, "ALT_VALUE")
    }
    
    func testStringLiteral() {
        let key : BlockchainAddress = "ecdsa-koblitz-pubkey:VALUE"
        
        XCTAssertEqual(key.scope, "ecdsa-koblitz-pubkey")
        XCTAssertEqual(key.value, "VALUE")
        
        let unscopedKey : BlockchainAddress = "ALT_VALUE"
        
        XCTAssertNil(unscopedKey.scope)
        XCTAssertEqual(unscopedKey.value, "ALT_VALUE")
    }
}
