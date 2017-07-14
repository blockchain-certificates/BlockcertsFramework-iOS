//
//  CertificateV2_0Tests.swift
//  cert-wallet
//
//  Created by Chris Downie on 7/14/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import Blockcerts

class CertificateV2_0Tests: XCTestCase {
    let certificateFilename = "sample_cert-valid-2.0"
    
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
            let cert = try? CertificateParser.parse(data: file, asVersion: .two) else {
                XCTFail("Failed to laod the test file in CertificateTests")
                return
        }
        XCTAssertEqual(cert.title, "Certificate of Accomplishment")
        XCTAssertEqual(cert.subtitle, nil)
        XCTAssertEqual(cert.description, "Lorem ipsum dolor sit amet, mei docendi concludaturque ad, cu nec partem graece. Est aperiam consetetur cu, expetenda moderatius neglegentur ei nam, suas dolor laudem eam an.")
        XCTAssertEqual(cert.id, "urn:uuid:bbba8553-8ec1-445f-82c9-a57251dd731c")
    }
    
}
