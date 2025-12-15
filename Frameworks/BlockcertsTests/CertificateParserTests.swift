//
//  CertificateParser.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/16/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import Blockcerts

class CertificateParserTests: XCTestCase {
    let v1_1filename = "sample_unsigned_cert-1.1.0"
    let v1_1signedFilename = "sample_signed_cert-valid-1.1.0"
    let v1_2filename = "sample_unsigned_cert-1.2.0"
    let v1_2signedFilename = "sample_signed_cert-1.2.0"
    let v1_2signedValidFilename = "sample_signed_cert-valid-1.2.0"
    let v2alpha_signedValidFilename = "sample_cert-valid-2.0a"
    let v2alpha_signedRevokedFilename = "sample_cert-revoked-2.0a"
    let v2_filename = "sample_cert-valid-2.0"
    let v3_testValidFilename = "testnet-valid-3.0"
    
    // MARK: - Simple parse(data:) calls
    func testExpectingV1_1Certificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
            return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, .oneDotOne)
    }
    
    func testExpectingV1_1SignedCertificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1signedFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, .oneDotOne)
    }
    
    // I expect this to fail in v1.2
    func testExpectingV1_2UnsignedCertificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNil(certificate)
    }
    
    func testExpectingV1_2SignedCertificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2signedFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, .oneDotTwo)
    }
    
    func testExpectingV1_2SignedValidCertificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2signedValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, .oneDotTwo)
    }
    
    // MARK: - parse(data:asVersion:) calls
    func testInvalidParsingV1asV2() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file, asVersion: .oneDotTwo)
        XCTAssertNil(certificate)
    }
    
    func testInvalidParsingV2asV1() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file, asVersion: .oneDotOne)
        XCTAssertNil(certificate)
    }
    
    func testExpectingV2SignedValidCertificateAsV2_() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v2alpha_signedValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file, asVersion: .twoAlpha)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, .twoAlpha)
    }
    
    func testExpectingV2SignedRevokedCertificateAsV2_() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v2alpha_signedRevokedFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file, asVersion: .twoAlpha)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, .twoAlpha)
    }
    
    func testGetBlockcertsVersion1_1_() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1signedFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let blockcertsVersion = try? CertificateParser.getBlockcertsVersion(data: file)
        XCTAssertNotNil(blockcertsVersion)
        XCTAssertEqual(blockcertsVersion, "v1.1")
    }
    
    func testGetBlockcertsVersion1_2_() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2signedValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let blockcertsVersion = try? CertificateParser.getBlockcertsVersion(data: file)
        XCTAssertNotNil(blockcertsVersion)
        XCTAssertEqual(blockcertsVersion, "v1")
    }
    
    func testGetBlockcertsVersion2_() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v2_filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let blockcertsVersion = try? CertificateParser.getBlockcertsVersion(data: file)
        XCTAssertNotNil(blockcertsVersion)
        XCTAssertEqual(blockcertsVersion, "v2")
    }
    
    func testGetBlockcertsVersion2alpha_() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v2alpha_signedValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let blockcertsVersion = try? CertificateParser.getBlockcertsVersion(data: file)
        XCTAssertNotNil(blockcertsVersion)
        XCTAssertEqual(blockcertsVersion, "v2.0-alpha")
    }
    
    func testGetBlockcertsVersion3_() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v3_testValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let blockcertsVersion = try? CertificateParser.getBlockcertsVersion(data: file)
        XCTAssertNotNil(blockcertsVersion)
        XCTAssertEqual(blockcertsVersion, "v3")
    }
}
