//
//  IssuerIntroductionRequestTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/2/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest

class IssuerIntroductionRequestTests: XCTestCase {
    func testSuccessfulIntroductionRequest() {
        let itShouldCallTheCallback = expectation(description: "The request's callback handler will be called.")
        
        let url = URL(string: "http://blockcerts.org/issuer/request")!
        
        // Mock out the network
        let session = MockURLSession()
        let response = "Success"
        session.respond(to: url,
                        with: response.data(using: .utf8),
                        response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                        error: nil)
        
        // Create the request
        let request = IssuerIntroductionRequest(with: url, session: session) { (success, error) in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            itShouldCallTheCallback.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)

    }
}
