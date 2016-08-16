//
//  CertificateParser.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/16/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest

class CertificateParserTests: XCTestCase {
    let v1_1filename = "sample_unsigned_cert-1.1.0"
    let v1_2filename = "sample_unsigned_cert-1.2.0"
    let v1_2signedFilename = "sample_signed_cert-1.2.0"
    
    func testExpectingV1_1Certificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
            return
        }
        
        let certificate = CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, "1.1")
    }
    
    func testExpectingV1_2UnsignedCertificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, "1.2")
    }
    
    func testExpectingV1_2SignedCertificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2signedFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, "1.2")
    }
}
