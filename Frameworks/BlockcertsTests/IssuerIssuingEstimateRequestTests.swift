//
//  IssuerIssuingEstimateRequestTests.swift
//  BlockcertsTests
//
//  Created by Chris Downie on 10/19/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import Blockcerts

class IssuerIssuingEstimateRequestTests: XCTestCase {
    func testOneEstimateResponse() {
        // Variable values to test
        let estimateURL = URL(string: "https://issuer.org/estimate/url")!
        let estimateTitle = "Title of Certificate"
        let estimateDate = Date(timeIntervalSince1970: 0)
        let expectedKey = "THIS_IS_NOT_A_REAL_KEY"

        // Standard Expectations
        let itShouldCallTheCallback = expectation(description: "The request's callback handler will be called.")
        let itShouldCallTheServer = expectation(description: "Mocking framework should call our fake server function.")
        
        // Parse the issuer
        let issuerFile = "issuer-v2-with-issuing-estimates"
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: issuerFile, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        let decoder = JSONDecoder()
        var issuer : IssuerV2? = nil
        do {
            issuer = try decoder.decode(IssuerV2.self, from: file)
        } catch {
            XCTFail("Something went wrong \(error)")
        }
        
        // Mock out the network
        let session = MockURLSession()
        session.respond(to: estimateURL) { request in
            itShouldCallTheServer.fulfill()
            
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            XCTAssertNotNil(components)
            
            XCTAssertEqual(components?.queryItems?.count, 1)
            let firstQuery = components?.queryItems?.first
            XCTAssertEqual(firstQuery?.name, "key")
            XCTAssertEqual(firstQuery?.value, expectedKey)
            
            let response = CertificateIssuingEstimate(title: estimateTitle, willIssueOn: estimateDate)
            
            let encoded = try? JSONEncoder().encode(response)
            XCTAssertNotNil(encoded)
            return (
                data: encoded!,
                response: HTTPURLResponse(url: estimateURL, statusCode: 200, httpVersion: nil, headerFields: nil),
                error: nil
            )
        }
        
        // And now... actually do the test bits
        let request = IssuerIssuingEstimateRequest(from: issuer!, with: expectedKey, session: session) { (result) in
            itShouldCallTheCallback.fulfill()
            
            guard case .success(let estimates) = result else {
                XCTFail("IssuerIssuingEstimateRequest did not return a successful result")
                return
            }
            XCTAssertEqual(estimates.count, 1)
            
            let firstEstimate = estimates.first!
            XCTAssertEqual(firstEstimate.title, estimateTitle)
            XCTAssertEqual(firstEstimate.willIssueOn, estimateDate)
        }
        request.start()
    }
}