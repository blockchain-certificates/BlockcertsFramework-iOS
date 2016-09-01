//
//  IssuerCreationRequestTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/1/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest

class IssuerCreationRequestTests: XCTestCase {
    func testSuccessfulIssuerResponse() {
        let url = URL(string: "http://blockcerts.org/issuer/")!
        
        let expectedName = "BlockCerts Issuer"
        let expectedEmail = "issuer@blockcerts.org"
        
        // Mock out the network
        let session = MockURLSession()
        let jsonResponse = ""
            + "{"
            + "\"name\":\"\(expectedName)\","
            + "\"email\":\"\(expectedEmail)\","
            + "}"
        session.respond(to: url,
                        with: jsonResponse.data(using: .utf8),
                        response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                        error: nil)
        
        // Create the request
        let request = IssuerCreationRequest(withUrl: url, session: session) { (issuer) in
            XCTAssertNotNil(issuer)
            
            XCTAssertEqual(issuer!.name, expectedName)
            XCTAssertEqual(issuer!.email, expectedEmail)
        }
        request.start()
    }
}
