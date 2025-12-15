//
//  RecipientTests.swift
//  cert-wallet
//
//  Created by Kim Duffy on 4/11/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import BlockchainCertificates

class RecipientTests: XCTestCase {
    
    
    func testV2Constructor() {
        let recipient = Recipient(name: "Vlad The Impaler", identity: "vlad@hotmail", identityType: "email", isHashed: false, publicAddress: "mrTP6uXcp4V5rMdG69jtYWVqXTMybHQo4F", revocationAddress: nil)
        XCTAssertEqual(recipient.name, "Vlad The Impaler")
        XCTAssertEqual(recipient.givenName, "Vlad")
        XCTAssertEqual(recipient.familyName, "The Impaler")
    }
    
    func testV2ConstructorNoSpace() {
        let recipient = Recipient(name: "Vlad", identity: "vlad@hotmail", identityType: "email", isHashed: false, publicAddress: "mrTP6uXcp4V5rMdG69jtYWVqXTMybHQo4F", revocationAddress: nil)
        XCTAssertEqual(recipient.name, "Vlad")
        XCTAssertEqual(recipient.givenName, "Vlad")
        XCTAssertEqual(recipient.familyName, "")
    }
    
    
    func testPreV2Constructor() {
        let recipient = Recipient(givenName: "Vlad", familyName: "Impaler", identity: "vlad@hotmail", identityType: "email", isHashed: false, publicAddress: "mrTP6uXcp4V5rMdG69jtYWVqXTMybHQo4F", revocationAddress: nil)
        XCTAssertEqual(recipient.givenName, "Vlad")
        XCTAssertEqual(recipient.familyName, "Impaler")
        XCTAssertEqual(recipient.name, "Vlad Impaler")
    }
}
