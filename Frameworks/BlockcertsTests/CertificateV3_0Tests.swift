//
//  CertificateV3_0Tests.swift
//  Blockcerts
//
//  Created by Matthieu Collé on 24/06/2022.
//  Copyright © 2022 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import Blockcerts

class CertificateV3_0Tests: XCTestCase {
    let certificateFilename = "testnet-valid-3.0"
    
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
    
    func testParses() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .three) else {
                XCTFail("Failed to load the test file in CertificateV3_0Tests")
                return
        }
        XCTAssertEqual(cert.title, "Certificate of Accomplishment")
        XCTAssertEqual(cert.subtitle, nil)
        XCTAssertEqual(cert.description, "Lorem ipsum dolor sit amet, mei docendi concludaturque ad, cu nec partem graece. Est aperiam consetetur cu, expetenda moderatius neglegentur ei nam, suas dolor laudem eam an.")
        XCTAssertEqual(cert.id, "urn:uuid:bbba8553-8ec1-445f-82c9-a57251dd731c")
    }
    
    func testImportVerifyProperties() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .three) else {
                XCTFail("Failed to load the test file in CertificateV3_0Tests")
                return
        }
        let verifyData = cert.verifyData
        
        XCTAssertEqual(verifyData.type, "MerkleProofVerification2017")
        XCTAssertNil(verifyData.signedAttribute)
        XCTAssertEqual(verifyData.publicKey, "ecdsa-koblitz-pubkey:msBCHdwaQ7N2ypBYupkp6uNxtr9Pg76imj")
        XCTAssertNil(verifyData.signer)
    }
    
    func testHtmlDisplayFromHtmlMediaType() {
        guard let file = file,
            let cert = try? CertificateParser.parse(data: file, asVersion: .three) else {
                XCTFail("Failed to laod the test file in CertificateV3_0Tests")
                return
        }
    }
}
