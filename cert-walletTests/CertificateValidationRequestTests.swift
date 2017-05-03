//
//  CertificateValidationRequestTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/19/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest
import JSONLD
import BlockchainCertificates

class CertificateValidationRequestTests: XCTestCase {
    
    func testTamperedV1_1Certificate() {
        let v1_1transactionId = "d5df311055bf0fe656b9d6fa19aad15c915b47303e06677b812773c37050e35d"
        let v1_1filename = "sample_signed_cert-1.1.0"
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let session = MockURLSession()
        
        let transactionURL = URL(string:"https://blockchain.info/rawtx/\(v1_1transactionId)?cors=true")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = "{\"ver\":1,\"inputs\":[{\"sequence\":4294967295,\"prev_out\":{\"spent\":true,\"tx_index\":151120487,\"type\":0,\"addr\":\"1HVE4FE9jqEe914WYhtZ9VzAJpjC4nuCig\",\"value\":23025,\"n\":2,\"script\":\"76a914b4d88edb2677121b603b8ee1326247aaad45cbea88ac\"},\"script\":\"47304402207c7f06af8b8b8ba1c349d63252b3b4570370202168b3afbad3319695b609986a02201750f276c4d534904ba69342d7a97d371e28131c0b2c704fb5093aa0fe1e6255012103cc68e3493cfe9467d7ef6da336ed554f4425a4450f062048d18860ee68556ebe\"}],\"block_height\":413966,\"relayed_by\":\"45.33.85.58\",\"out\":[{\"spent\":false,\"tx_index\":151122290,\"type\":0,\"addr\":\"18DmEbKzRBo6gQz9ET6hQeWUDcUbGAMqzC\",\"value\":2750,\"n\":0,\"script\":\"76a9144f32cc080424addd43421ad862ae327bb84d894888ac\"},{\"spent\":false,\"tx_index\":151122290,\"type\":0,\"addr\":\"1JQ7ma9qcL2EZDMAnKneKeNXGU3WFoNtjg\",\"value\":2750,\"n\":1,\"script\":\"76a914bed95b01064d287267bb49b44de2ce577ca5468f88ac\"},{\"spent\":true,\"tx_index\":151122290,\"type\":0,\"addr\":\"1HVE4FE9jqEe914WYhtZ9VzAJpjC4nuCig\",\"value\":7525,\"n\":2,\"script\":\"76a914b4d88edb2677121b603b8ee1326247aaad45cbea88ac\"},{\"spent\":false,\"tx_index\":151122290,\"type\":0,\"value\":0,\"n\":3,\"script\":\"6a20b200240216e10d988bc748e675abb1b5cc1b29384e9f1c68cad9f5a03a6ed531\"}],\"lock_time\":0,\"size\":302,\"double_spend\":false,\"time\":1464548606,\"tx_index\":151122290,\"vin_sz\":1,\"hash\":\"d5df311055bf0fe656b9d6fa19aad15c915b47303e06677b812773c37050e35d\",\"vout_sz\":4}".data(using: .utf8)
        session.respond(to: transactionURL,
                        with: transactionData,
                        response: transactionResponse,
                        error: nil)
        
        // Issue the validation request
        let request = CertificateValidationRequest(for: certificate!, with: v1_1transactionId, bitcoinManager: CoreBitcoinManager(), session: session) { (success, errorMessage) in
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
        let v1_1ValidFilename = "sample_signed_cert-valid-1.1.0"
        let v1_1ValidTransactionId = "1703d2f5d706d495c1c65b40a086991ab755cc0a02bef51cd4aff9ed7a8586aa"
        let v1_1txFilename = "tx_valid-1.1.0"
        
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1ValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        guard let txUrl = testBundle.url(forResource: v1_1txFilename, withExtension: "json") ,
            let txFile = try? Data(contentsOf: txUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(v1_1ValidTransactionId)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        mockedSession.respond(to: transactionURL, with: txFile, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: "http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")!
        mockedSession.respond(to: issuerURL,
                              with: "{\"issuerKeys\":[{\"date\":\"2016-08-28\",\"key\":\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"}],\"revocationKeys\":[{\"date\":\"2016-08-28\",\"key\":\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"}]}".data(using: .utf8),
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, with:v1_1ValidTransactionId, bitcoinManager: CoreBitcoinManager(), chain: .testnet, session: mockedSession) { (success, errorMessage) in
            XCTAssertTrue(success)
            XCTAssertNil(errorMessage)
            testExpectation.fulfill()
        }
        request.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testValidV1_2Certificate() {
        let v1_2ValidFilename = "sample_signed_cert-valid-1.2.0"
        let v1_2normalized = "normalized-1.2.0"
        let v1_2txFilename = "tx_valid-1.2.0"
        let gotIssuerFilename = "got_issuer"
        
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2ValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        guard let txUrl = testBundle.url(forResource: v1_2txFilename, withExtension: "json") ,
            let txFile = try? Data(contentsOf: txUrl) else {
                return
        }
        
        guard let issuerUrl = testBundle.url(forResource: gotIssuerFilename, withExtension: "json") ,
            let issuerFile = try? Data(contentsOf: issuerUrl) else {
                return
        }
        
        guard let normalizedUrl = testBundle.url(forResource: v1_2normalized, withExtension: "txt") ,
            let normalizedFile = try? Data(contentsOf: normalizedUrl) else {
                return
        }
        
        let normalizedString = String(data: normalizedFile, encoding: String.Encoding.utf8)! as String
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let id = certificate?.receipt?.transactionId
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(id!)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = txFile;
        
        mockedSession.respond(to: transactionURL, with: transactionData, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: "http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")!
        mockedSession.respond(to: issuerURL,
                              with: issuerFile,
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, bitcoinManager: CoreBitcoinManager(), chain: .testnet, jsonld: MockJSONLD(normalizedString: normalizedString), session: mockedSession) { (success, errorMessage) in
            XCTAssertTrue(success)
            XCTAssertNil(errorMessage)
            testExpectation.fulfill()
        }
        XCTAssertNotNil(request)
        request!.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testValidV2Certificate() {
        let certFilename = "sample_cert-valid-2.0"
        let txFilename = "tx_valid-2.0"
        let sampleIssuerFilename = "sample_issuer"
        let normalizedFilename = "normalized-2.0"
        let revocationList = "revocation_list-2.0"
        let revocationUrlString = "https://www.blockcerts.org/samples/2.0-alpha/revocationList.json"
        let issuerUrlString = "https://www.blockcerts.org/samples/2.0-alpha/issuerTestnet.json"

        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: certFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        guard let txUrl = testBundle.url(forResource: txFilename, withExtension: "json") ,
            let txFile = try? Data(contentsOf: txUrl) else {
                return
        }
        
        guard let issuerUrl = testBundle.url(forResource: sampleIssuerFilename, withExtension: "json") ,
            let issuerFile = try? Data(contentsOf: issuerUrl) else {
                return
        }
        
        guard let normalizedUrl = testBundle.url(forResource: normalizedFilename, withExtension: "txt") ,
            let normalizedFile = try? Data(contentsOf: normalizedUrl) else {
                return
        }
        
        guard let revocationUrl = testBundle.url(forResource: revocationList, withExtension: "json") ,
            let revocationFile = try? Data(contentsOf: revocationUrl) else {
                return
        }
        
        let normalizedString = String(data: normalizedFile, encoding: String.Encoding.utf8)! as String
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let id = certificate?.receipt?.transactionId
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(id!)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = txFile
        mockedSession.respond(to: transactionURL, with: transactionData, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: issuerUrlString)!
        mockedSession.respond(to: issuerURL,
                              with: issuerFile,
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)

        let revocationURL = URL(string: revocationUrlString)!
        mockedSession.respond(to: revocationURL,
                              with: revocationFile,
                              response: HTTPURLResponse(url: revocationURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, bitcoinManager: CoreBitcoinManager(), chain: .testnet, jsonld: MockJSONLD(normalizedString: normalizedString), session: mockedSession) { (success, errorMessage) in
            XCTAssertTrue(success)
            XCTAssertNil(errorMessage)
            testExpectation.fulfill()
        }
        XCTAssertNotNil(request)
        request!.start()
        
        waitForExpectations(timeout: 2000.0, handler: nil)
    }
    
    /// A revoked assertion should fail
    func testRevokedV2Certificate() {
        let certFilename = "sample_cert-revoked-2.0"
        let txFilename = "tx_valid-2.0"
        let sampleIssuerFilename = "sample_issuer"
        let normalizedFilename = "normalized_revoked-2.0"
        let revocationList = "revocation_list-2.0"
        let revocationUrlString = "https://www.blockcerts.org/samples/2.0-alpha/revocationList.json"
        let issuerUrlString = "https://www.blockcerts.org/samples/2.0-alpha/issuerTestnet.json"
        
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: certFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        guard let txUrl = testBundle.url(forResource: txFilename, withExtension: "json") ,
            let txFile = try? Data(contentsOf: txUrl) else {
                return
        }
        
        guard let issuerUrl = testBundle.url(forResource: sampleIssuerFilename, withExtension: "json") ,
            let issuerFile = try? Data(contentsOf: issuerUrl) else {
                return
        }
        
        guard let normalizedUrl = testBundle.url(forResource: normalizedFilename, withExtension: "txt") ,
            let normalizedFile = try? Data(contentsOf: normalizedUrl) else {
                return
        }
        
        guard let revocationUrl = testBundle.url(forResource: revocationList, withExtension: "json") ,
            let revocationFile = try? Data(contentsOf: revocationUrl) else {
                return
        }
        
        let normalizedString = String(data: normalizedFile, encoding: String.Encoding.utf8)! as String
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let id = certificate?.receipt?.transactionId
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(id!)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = txFile
        mockedSession.respond(to: transactionURL, with: transactionData, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: issuerUrlString)!
        mockedSession.respond(to: issuerURL,
                              with: issuerFile,
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        let revocationURL = URL(string: revocationUrlString)!
        mockedSession.respond(to: revocationURL,
                              with: revocationFile,
                              response: HTTPURLResponse(url: revocationURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, bitcoinManager: CoreBitcoinManager(), chain: BitcoinChain.testnet, jsonld: MockJSONLD(normalizedString: normalizedString), session: mockedSession) { (success, errorMessage) in
            XCTAssertFalse(success)
            XCTAssertEqual(errorMessage, "Certificate has been revoked by issuer. Revoked assertion uid is eda7d784-c03b-40a2-ac10-4857e9627329 and reason is Issued in error.")
            testExpectation.fulfill()
        }
        XCTAssertNotNil(request)
        request!.start()
        
        waitForExpectations(timeout: 2000.0, handler: nil)
    }
    
    /// If the transaction was issued after the issuer revoked the key, verification should fail
    func testV2CertificateAuthenticityFailure() {
        let certFilename = "sample_cert-authenticity-2.0"
        let txFilename = "tx_invalid-authenticity-2.0"
        let sampleIssuerFilename = "sample_issuer"
        let normalizedFilename = "normalized_authenticity-2.0"
        let revocationList = "revocation_list-2.0"
        let revocationUrlString = "https://www.blockcerts.org/samples/2.0-alpha/revocationList.json"
        let issuerUrlString = "https://www.blockcerts.org/samples/2.0-alpha/issuerTestnet.json"
        
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: certFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        guard let txUrl = testBundle.url(forResource: txFilename, withExtension: "json") ,
            let txFile = try? Data(contentsOf: txUrl) else {
                return
        }
        
        guard let issuerUrl = testBundle.url(forResource: sampleIssuerFilename, withExtension: "json") ,
            let issuerFile = try? Data(contentsOf: issuerUrl) else {
                return
        }
        
        guard let normalizedUrl = testBundle.url(forResource: normalizedFilename, withExtension: "txt") ,
            let normalizedFile = try? Data(contentsOf: normalizedUrl) else {
                return
        }
        
        guard let revocationUrl = testBundle.url(forResource: revocationList, withExtension: "json") ,
            let revocationFile = try? Data(contentsOf: revocationUrl) else {
                return
        }
        
        let normalizedString = String(data: normalizedFile, encoding: String.Encoding.utf8)! as String
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let id = certificate?.receipt?.transactionId
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(id!)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = txFile
        mockedSession.respond(to: transactionURL, with: transactionData, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: issuerUrlString)!
        mockedSession.respond(to: issuerURL,
                              with: issuerFile,
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        let revocationURL = URL(string: revocationUrlString)!
        mockedSession.respond(to: revocationURL,
                              with: revocationFile,
                              response: HTTPURLResponse(url: revocationURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, bitcoinManager: CoreBitcoinManager(), chain: BitcoinChain.testnet, jsonld: MockJSONLD(normalizedString: normalizedString), session: mockedSession) { (success, errorMessage) in
            XCTAssertFalse(success)
            XCTAssertEqual(errorMessage, "Transaction was issued after Issuer revoked the key.")
            testExpectation.fulfill()
        }
        XCTAssertNotNil(request)
        request!.start()
        
        waitForExpectations(timeout: 2000.0, handler: nil)
    }
    
    /// A tampered V2 certificate (field changed) should fail
    func testV2TamperedCertificateFailure() {
        let certFilename = "sample_cert-tampered-2.0"
        let txFilename = "tx_invalid-authenticity-2.0"
        let sampleIssuerFilename = "sample_issuer"
        let normalizedFilename = "normalized_tampered-2.0"
        let revocationList = "revocation_list-2.0"
        let revocationUrlString = "https://www.blockcerts.org/samples/2.0-alpha/revocationList.json"
        let issuerUrlString = "https://www.blockcerts.org/samples/2.0-alpha/issuerTestnet.json"
        
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: certFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        guard let txUrl = testBundle.url(forResource: txFilename, withExtension: "json") ,
            let txFile = try? Data(contentsOf: txUrl) else {
                return
        }
        
        guard let issuerUrl = testBundle.url(forResource: sampleIssuerFilename, withExtension: "json") ,
            let issuerFile = try? Data(contentsOf: issuerUrl) else {
                return
        }
        
        guard let normalizedUrl = testBundle.url(forResource: normalizedFilename, withExtension: "txt") ,
            let normalizedFile = try? Data(contentsOf: normalizedUrl) else {
                return
        }
        
        guard let revocationUrl = testBundle.url(forResource: revocationList, withExtension: "json") ,
            let revocationFile = try? Data(contentsOf: revocationUrl) else {
                return
        }
        
        let normalizedString = String(data: normalizedFile, encoding: String.Encoding.utf8)! as String
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let id = certificate?.receipt?.transactionId
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(id!)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = txFile
        mockedSession.respond(to: transactionURL, with: transactionData, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: issuerUrlString)!
        mockedSession.respond(to: issuerURL,
                              with: issuerFile,
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        let revocationURL = URL(string: revocationUrlString)!
        mockedSession.respond(to: revocationURL,
                              with: revocationFile,
                              response: HTTPURLResponse(url: revocationURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, bitcoinManager: CoreBitcoinManager(), chain: BitcoinChain.testnet, jsonld: MockJSONLD(normalizedString: normalizedString), session: mockedSession) { (success, errorMessage) in
            XCTAssertFalse(success)
            XCTAssertEqual(errorMessage, "Local hash doesn\'t match remote hash:\n Local:b4d4d3a66673dbbed784301e45db08659e852098f427b1b18193873a50dbed62\nRemote:7d5ee19584a27a9bf7d558e0128a27e18f8d11ace3c99cd72423c9db6cbc50d7")
            testExpectation.fulfill()
        }
        XCTAssertNotNil(request)
        request!.start()
        
        waitForExpectations(timeout: 2000.0, handler: nil)
    }
    
    /// A valid v2 certificate with a legacy-formatted issuer identification should pass
    func testValidV2CertificateWithV1Issuer() {
        let v2ValidFilename = "sample_cert-v1-issuer-2.0"
        let v2txFilename = "tx_valid-v1-issuer-2.0"
        let sampleIssuerFilename = "sample_v1_issuer"
        let v2normalized = "normalized_v1-issuer-2.0"
        let v2revocationList = "revocation_list-2.0"
        let revocationUrlString = "https://www.blockcerts.org/samples/2.0-alpha/revocationList.json"
        let issuerUrlString = "https://w3id.org/blockcerts/mockissuer/issuer/issuerTestnet_v1.json"
        
        let testExpectation = expectation(description: "Validation will call the completion handler")
        
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v2ValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        guard let txUrl = testBundle.url(forResource: v2txFilename, withExtension: "json") ,
            let txFile = try? Data(contentsOf: txUrl) else {
                return
        }
        
        guard let issuerUrl = testBundle.url(forResource: sampleIssuerFilename, withExtension: "json") ,
            let issuerFile = try? Data(contentsOf: issuerUrl) else {
                return
        }
        
        guard let normalizedUrl = testBundle.url(forResource: v2normalized, withExtension: "txt") ,
            let normalizedFile = try? Data(contentsOf: normalizedUrl) else {
                return
        }
        
        guard let revocationUrl = testBundle.url(forResource: v2revocationList, withExtension: "json") ,
            let revocationFile = try? Data(contentsOf: revocationUrl) else {
                return
        }
        
        let normalizedString = String(data: normalizedFile, encoding: String.Encoding.utf8)! as String
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let id = certificate?.receipt?.transactionId
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(id!)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = txFile
        mockedSession.respond(to: transactionURL, with: transactionData, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: issuerUrlString)!
        mockedSession.respond(to: issuerURL,
                              with: issuerFile,
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        let revocationURL = URL(string: revocationUrlString)!
        mockedSession.respond(to: revocationURL,
                              with: revocationFile,
                              response: HTTPURLResponse(url: revocationURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, bitcoinManager: CoreBitcoinManager(), chain: BitcoinChain.testnet, jsonld: MockJSONLD(normalizedString: normalizedString), session: mockedSession) { (success, errorMessage) in
            XCTAssertTrue(success)
            XCTAssertNil(errorMessage)
            testExpectation.fulfill()
        }
        XCTAssertNotNil(request)
        request!.start()
        
        waitForExpectations(timeout: 2000.0, handler: nil)
    }
    
    class MockJSONLD : JSONLDProcessor {
        
        let normalizedString:String
        
        init(normalizedString: String) {
            self.normalizedString = normalizedString
        }
        
        func compact(docData: Data, context: [String : Any]?, callback: ((Error?, [String : Any]?) -> Void)?) {
            if let reformatted = try? JSONSerialization.jsonObject(with: docData, options: []),
                let result = reformatted as? [String: Any] {
                callback?(nil, result)
            } else {
                callback?(nil, nil)
            }
        }
        func normalize(docData: Data, callback: @escaping (Error?, String?) -> Void) {
            callback(nil, self.normalizedString)
        }
    }
}
