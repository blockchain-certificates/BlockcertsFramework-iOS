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
        XCTAssertEqual(cert.title, "Game of Thrones Character")
        XCTAssertEqual(cert.subtitle, nil)
        XCTAssertEqual(cert.description, "This certifies that the named character is an official Game of Thrones character.")
        XCTAssertEqual(cert.id, "http://certificates.gamoeofthronesxyz.org/criteria/2016/08/got.json")
    }
    
}
