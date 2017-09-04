//
//  CertificateTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/15/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import Blockcerts

class CertificateV1_1Tests: XCTestCase {
    let certificateFilename = "sample_unsigned_cert-1.1.0"
    var file : Data? = nil
    
    override func setUp() {
        super.setUp()

        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: certificateFilename, withExtension: "json") else {
            file = nil
            return
        }
        
        file = try? Data(contentsOf: fileUrl)
    }
    
    override func tearDown() {
        super.tearDown()
        
        file = nil
    }
    
    func testImportProperties() {
        XCTAssertNotNil(file)
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotOne) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        XCTAssertEqual(cert.title, "Certificate title")
        XCTAssertEqual(cert.subtitle, nil)
        XCTAssertEqual(cert.description, "Certificate description")
        XCTAssertEqual(cert.id, "https://www.theissuer.edu/criteria/2016/05/certificate-type.json")
    }
    
    func testImportIssuerProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotOne) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        let issuer = cert.issuer as! IssuerV1
        
        XCTAssertEqual(issuer.name, "Issuing Institution")
        XCTAssertEqual(issuer.email, "issuer@theissuer.edu")
        XCTAssertEqual(issuer.id, URL(string: "https://www.theissuer.edu/issuer/the-issuer.json"))
        XCTAssertEqual(issuer.url, URL(string: "http://www.theissuer.edu"))
    }
    
    func testImportRecipientProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotOne) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        let recipient = cert.recipient
        XCTAssertEqual(recipient.name, "RecipientFirstName RecipientLastName")
        XCTAssertEqual(recipient.identity, "recipient@domain.com")
        XCTAssertEqual(recipient.identityType, "email")
        XCTAssertEqual(recipient.isHashed, false)
        XCTAssertEqual(recipient.publicAddress, "n1EduLzKsTL1pM8Roz9vEV16AQnBdg9JCx")
    }
    
    func testImportAssertionProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotOne) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        let assertion = cert.assertion
        
        //XCTAssertEqual(assertion.issuedOn, Date(timeIntervalSinceReferenceDate: 485978400))
        XCTAssertEqual(assertion.evidence, "")
        XCTAssertEqual(assertion.uid, "68656c6c6f636f6d7077ffff")
        XCTAssertEqual(assertion.id, URL(string: "http://www.theissuer.edu/68656c6c6f636f6d7077ffff"))
    }
    
    func testImportVerifyProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotOne) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        let verifyData = cert.verifyData
        
        XCTAssertEqual(verifyData.type, "ECDSA(secp256k1)")
        XCTAssertEqual(verifyData.signedAttribute, "uid")
        XCTAssertNil(verifyData.publicKey)
        XCTAssertEqual(verifyData.signer, URL(string: "https://www.theissuer.edu/keys/signing-public-key.asc"))
    }
}
