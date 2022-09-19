//
//  String-Extensions.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/15/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import Blockcerts

class String_Extensions: XCTestCase {

    func testValidHexStrings() {
        XCTAssertNotNil("1".asHexData())
        XCTAssertNotNil("123".asHexData())
        XCTAssertNotNil("deadbeef".asHexData())
    }
    
    func testCorrectValuesForHexStrings() {
        XCTAssertEqual("1".asHexData(), Data(bytes: [1]))
        XCTAssertEqual("123".asHexData(), Data(bytes: [1, 35]))
        XCTAssertEqual("deadbeef".asHexData(), Data(bytes: [222, 173, 190, 239]))
    }
    
    func testInvalidHexStrings() {
        XCTAssertNil("q".asHexData())
        XCTAssertNil("1234x".asHexData())
        XCTAssertNil("0x001".asHexData())
    }
    
    func testValidDid() {
        XCTAssertTrue("did:ion:abcdefgh".isDid())
    }
    
    func testInvalidDid() {
        XCTAssertFalse("did:ionabcdefgh".isDid())
        XCTAssertFalse("didionabcdefgh".isDid())
        XCTAssertFalse("https://blockcerts.org".isDid())
    }
}
