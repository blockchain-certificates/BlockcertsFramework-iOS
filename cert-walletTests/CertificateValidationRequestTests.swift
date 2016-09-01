//
//  CertificateValidationRequestTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/19/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest

class CertificateValidationRequestTests: XCTestCase {
    
    let v1_1filename = "sample_signed_cert-1.1.0"
    let v1_1transactionId = "d5df311055bf0fe656b9d6fa19aad15c915b47303e06677b812773c37050e35d"
    let v1_1ValidFilename = "sample_signed_cert-valid-1.1.0"
    let v1_1ValidTransactionId = "1703d2f5d706d495c1c65b40a086991ab755cc0a02bef51cd4aff9ed7a8586aa"
    let v1_2ValidFilename = "sample_signed_cert-valid-1.2.0"
    
    func testTamperedV1_1Certificate() {
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        let expectedURL = URL(string:"https://blockchain.info/rawtx/\(v1_1transactionId)?cors=true")!
        let mockedResponse = HTTPURLResponse(url: expectedURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockedData = "{\"ver\":1,\"inputs\":[{\"sequence\":4294967295,\"prev_out\":{\"spent\":true,\"tx_index\":151120487,\"type\":0,\"addr\":\"1HVE4FE9jqEe914WYhtZ9VzAJpjC4nuCig\",\"value\":23025,\"n\":2,\"script\":\"76a914b4d88edb2677121b603b8ee1326247aaad45cbea88ac\"},\"script\":\"47304402207c7f06af8b8b8ba1c349d63252b3b4570370202168b3afbad3319695b609986a02201750f276c4d534904ba69342d7a97d371e28131c0b2c704fb5093aa0fe1e6255012103cc68e3493cfe9467d7ef6da336ed554f4425a4450f062048d18860ee68556ebe\"}],\"block_height\":413966,\"relayed_by\":\"45.33.85.58\",\"out\":[{\"spent\":false,\"tx_index\":151122290,\"type\":0,\"addr\":\"18DmEbKzRBo6gQz9ET6hQeWUDcUbGAMqzC\",\"value\":2750,\"n\":0,\"script\":\"76a9144f32cc080424addd43421ad862ae327bb84d894888ac\"},{\"spent\":false,\"tx_index\":151122290,\"type\":0,\"addr\":\"1JQ7ma9qcL2EZDMAnKneKeNXGU3WFoNtjg\",\"value\":2750,\"n\":1,\"script\":\"76a914bed95b01064d287267bb49b44de2ce577ca5468f88ac\"},{\"spent\":true,\"tx_index\":151122290,\"type\":0,\"addr\":\"1HVE4FE9jqEe914WYhtZ9VzAJpjC4nuCig\",\"value\":7525,\"n\":2,\"script\":\"76a914b4d88edb2677121b603b8ee1326247aaad45cbea88ac\"},{\"spent\":false,\"tx_index\":151122290,\"type\":0,\"value\":0,\"n\":3,\"script\":\"6a20b200240216e10d988bc748e675abb1b5cc1b29384e9f1c68cad9f5a03a6ed531\"}],\"lock_time\":0,\"size\":302,\"double_spend\":false,\"time\":1464548606,\"tx_index\":151122290,\"vin_sz\":1,\"hash\":\"d5df311055bf0fe656b9d6fa19aad15c915b47303e06677b812773c37050e35d\",\"vout_sz\":4}".data(using: .utf8)
        let session = MockURLSession()
        session.respond(to: expectedURL,
                        with: mockedData,
                        response: mockedResponse,
                        error: nil)
        
        let request = CertificateValidationRequest(for: certificate!, with: v1_1transactionId, session: session) { (success, errorMessage) in
            XCTAssertFalse(success)
            XCTAssertNotNil(errorMessage)
            
            let isErrorExpected = errorMessage?.contains("Local hash doesn't match remote hash") ?? false
            XCTAssertTrue(isErrorExpected)
            
            testExpectation.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testValidV1_1Certificate() {
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1ValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        let request = CertificateValidationRequest(for: certificate!, with:v1_1ValidTransactionId, chain: "testnet") { (success, errorMessage) in
            XCTAssertTrue(success)
            XCTAssertNil(errorMessage)
            testExpectation.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testValidV1_2Certificate() {
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2ValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        let request = CertificateValidationRequestV2(for: certificate!, chain: "testnet") { (success, errorMessage) in
            XCTAssertTrue(success)
            XCTAssertNil(errorMessage)
            testExpectation.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
}
