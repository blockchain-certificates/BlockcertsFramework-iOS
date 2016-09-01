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
        let itShouldCallTheCallback = expectation(description: "The request's callback handler will be called.")
        
        let url = URL(string: "http://blockcerts.org/issuer/")!
        
        let expectedName = "BlockCerts Issuer"
        let expectedEmail = "issuer@blockcerts.org"
        let expectedImageData = "data:image/png;base64,"
        let expectedURLString = "https://blockcerts.org"
        let expectedIDString = "https://blockcerts.org/issuer.json"
        let expectedPublicKeyURL = "https://blockcerts.org/pubkey"
        let expectedRequestURL = "https://blockcerts.org/request/"
        
        // Mock out the network
        let session = MockURLSession()
        let jsonResponse = ""
            + "{"
            + "\"name\":\"\(expectedName)\","
            + "\"email\":\"\(expectedEmail)\","
            + "\"image\":\"\(expectedImageData)\","
            + "\"id\":\"\(expectedIDString)\","
            + "\"url\":\"\(expectedURLString)\","
            + "\"publicKeyAddress\":\"\(expectedPublicKeyURL)\","
            + "\"requestURL\":\"\(expectedRequestURL)\"," // maybe introduction URL?
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
            XCTAssertEqual(issuer!.image, try! Data(contentsOf: URL(string: expectedImageData)!))
            XCTAssertEqual(issuer!.id, URL(string: expectedIDString)!)
            XCTAssertEqual(issuer!.url, URL(string: expectedURLString)!)
            XCTAssertEqual(issuer!.publicKeyAddress, URL(string: expectedPublicKeyURL)!)
            XCTAssertEqual(issuer!.requestUrl, URL(string: expectedRequestURL)!)
            
            itShouldCallTheCallback.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
}
