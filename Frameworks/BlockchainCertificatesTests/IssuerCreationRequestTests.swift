//
//  IssuerIdentificationRequestTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/1/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import BlockchainCertificates

class IssuerIdentificationRequestTests: XCTestCase {
    func testSuccessfulIssuerResponse() {
        let itShouldCallTheCallback = expectation(description: "The request's callback handler will be called.")
        
        let url = URL(string: "http://blockcerts.org/issuer/the-issuer.json")!
        
        let expectedURLString = "https://blockcerts.org/certificates/"
        let expectedIntroductionURLString = "https://blockcerts.org/intro/"
        let expectedName = "BlockCerts Issuer"
        let expectedEmail = "issuer@blockcerts.org"
        let rawImageData = UIImagePNGRepresentation(#imageLiteral(resourceName: "Pen"))!.base64EncodedString()
        let expectedImageData = "data:image/png;base64,\(rawImageData)"

        // Mock out the network
        let session = MockURLSession()
        let response : [String : Any] = [
            "id": "\(url)",
            "url": expectedURLString,
            "introductionURL": expectedIntroductionURLString,
            "name": expectedName,
            "email": expectedEmail,
            "image": expectedImageData,
            "issuerKeys": [
                [
                    "date": "2016-05-01",
                    "key": "FAKE_ISSUER_KEY"
                ]
            ],
            "revocationKeys": [
                [
                    "date": "2016-05-01",
                    "key": "FAKE_REVOCATION_KEY"
                ]

            ]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: response, options: [])
        
        session.respond(to: url,
                        with: jsonData,
                        response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                        error: nil)
        
        // Create the request
        let request = IssuerIdentificationRequest(id: url, session: session) { (issuer) in
            XCTAssertNotNil(issuer)
            XCTAssertEqual(issuer!.name, expectedName)
            XCTAssertEqual(issuer!.email, expectedEmail)
            XCTAssertEqual(issuer!.image, try! Data(contentsOf: URL(string: expectedImageData)!))
            XCTAssertEqual(issuer!.id, url)
            XCTAssertEqual(issuer!.url, URL(string: expectedURLString)!)
            XCTAssertEqual(issuer!.introductionURL, URL(string: expectedIntroductionURLString)!)
            
            itShouldCallTheCallback.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
}
