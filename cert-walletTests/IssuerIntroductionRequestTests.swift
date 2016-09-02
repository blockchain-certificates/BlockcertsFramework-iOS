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
        let itShouldCallTheServer = expectation(description: "Mocking framework should call our fake server function.")
        
        let issuer = Issuer(name: "BlockCerts Issuer",
                            email: "issuer@blockcerts.org",
                            image: "data:image/png;base64,".data(using: .utf8)!,
                            id: URL(string: "https://blockcerts.org/issuer.json")!,
                            url: URL(string: "https://blockcerts.org")!,
                            publicKey: "FakeIssuerPublicKey",
                            publicKeyAddress: URL(string: "https://blockcerts.org/pubkey")!,
                            requestUrl: URL(string: "https://blockcerts.org/introduce/")!)
        let recipient = Recipient(givenName: "Johnny",
                                  familyName: "Strong",
                                  identity: "johnny@blockcerts.org",
                                  identityType: "email",
                                  isHashed: false,
                                  publicKey: "FakeRecipientPublicKey")
        
        // Mock out the network
        let session = MockURLSession()
        let url = issuer.requestUrl!
        session.respond(to: url) { request in
            itShouldCallTheServer.fulfill()
            
            XCTAssertEqual(request.url, url)
            
            // TODO: Check the post body of the request.
            
            return (
                data: "Success".data(using: .utf8),
                response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                error: nil
            )
        }
        
        // Create the request
        let request = IssuerIntroductionRequest(introduce: recipient, to: issuer, session: session) { (success, error) in
            
            XCTAssertTrue(success)
            XCTAssertNil(error)
            itShouldCallTheCallback.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)

    }
}
