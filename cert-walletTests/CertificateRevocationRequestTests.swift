//
//  CertificateRevocationRequestTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/6/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest

class CertificateRevocationRequestTests: XCTestCase {
    func testUnsuccessfulV1_1Request() {
        let itShouldCallTheCallback = expectation(description: "It should call the request's callback method")
        
        let filename = "sample_unsigned_cert-1.1.0"
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        let request = CertificateRevocationRequest(revoking: certificate!) { (success, error) in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            itShouldCallTheCallback.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
}
