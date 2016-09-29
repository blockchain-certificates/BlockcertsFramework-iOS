//
//  CertificateTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/15/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest

class CertificateV1_2UnsignedInvalidTests: XCTestCase {
    func testMissingIssuerEmail() {
        let filename = "sample_unsigned_cert-invalid_no_email-1.2.0"
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl) else {
                XCTFail("Failed to load \(filename) in \(#function)")
                return
        }
        
        let cert = try? CertificateParser.parse(data: file)
        
        XCTAssertNil(cert)
    }
}


class CertificateV1_2SignedTests: XCTestCase {
    let certificateFilename = "sample_signed_cert-1.2.0"
    
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
    
    func testImportProperties() {
        XCTAssertNotNil(file)
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotTwo) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        XCTAssertEqual(cert.title, "Game of Thrones Character")
        XCTAssertEqual(cert.subtitle, nil)
        XCTAssertEqual(cert.description, "This certifies that the named character is an official Game of Thrones character.")
        XCTAssertEqual(cert.id, URL(string: "http://certificates.gamoeofthronesxyz.org/criteria/2016/08/got.json"))
    }
    
    func testImportIssuerProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotTwo) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        let issuer = cert.issuer
        
        XCTAssertEqual(issuer.name, "Game of thrones issuer")
        XCTAssertEqual(issuer.email, "fakeEmail@gamoeofthronesxyz.org")
        XCTAssertEqual(issuer.id, URL(string: "http://www.blockcerts.org/mockissuer/issuer/got-issuer.json"))
        XCTAssertEqual(issuer.url, URL(string: "http://www.blockcerts.org/mockissuer/"))
    }
    
    func testImportRecipientProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotTwo) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        let recipient = cert.recipient
        XCTAssertEqual(recipient.givenName, "Arya")
        XCTAssertEqual(recipient.familyName, "Stark")
        XCTAssertEqual(recipient.identity, "aryaxyz@starkxyz.com")
        XCTAssertEqual(recipient.identityType, "email")
        XCTAssertEqual(recipient.isHashed, false)
        XCTAssertEqual(recipient.publicAddress, "mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x")
    }
    
    func testImportAssertionProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotTwo) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        let assertion = cert.assertion
        
//        XCTAssertEqual(assertion.issuedOn, Date(timeIntervalSinceReferenceDate: 485978400))
        XCTAssertEqual(assertion.evidence, "")
        XCTAssertEqual(assertion.uid, "f813349f-1385-487f-8d89-38a092411fa5")
        XCTAssertEqual(assertion.id, URL(string: "http://certificates.gamoeofthronesxyz.org/f813349f-1385-487f-8d89-38a092411fa5"))
    }
    
    func testImportVerifyProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .oneDotTwo) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        let verifyData = cert.verifyData
        
        XCTAssertEqual(verifyData.type, "ECDSA(secp256k1)")
        XCTAssertEqual(verifyData.signedAttribute, "uid")
        XCTAssertEqual(verifyData.signer, URL(string: "http://www.blockcerts.org/mockissuer/keys/got_public_key.asc"))
    }
}
