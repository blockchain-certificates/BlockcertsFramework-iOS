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
        
        // Build mocked network request & response
        let expectedURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(v1_1ValidTransactionId)")!
        let mockedResponse = HTTPURLResponse(url: expectedURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockedData = "{\"block_hash\":\"00000000000c3bda534366f2e46dc9fb03710d7ccff8648ca4ca9d494f12a94d\",\"block_height\":925859,\"block_index\":40,\"hash\":\"1703d2f5d706d495c1c65b40a086991ab755cc0a02bef51cd4aff9ed7a8586aa\",\"addresses\":[\"mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x\",\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\",\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"total\":99708246,\"fees\":17595,\"size\":303,\"preference\":\"high\",\"relayed_by\":\"\",\"confirmed\":\"2016-08-29T18:51:08Z\",\"received\":\"2016-08-29T18:51:08Z\",\"ver\":1,\"lock_time\":0,\"double_spend\":false,\"vin_sz\":1,\"vout_sz\":4,\"confirmations\":451,\"confidence\":1,\"data_protocol\":\"unknown\",\"inputs\":[{\"prev_hash\":\"ae3fe5aeaf287197f1381008b1b5457d394c8f1d7a220223c50d6fe7e677b4cb\",\"output_index\":2,\"script\":\"483045022100ef49bf597ebec9e9c9b5e0bff1d925cd1c382b73b2d41a9788550d6fe8b9d27002201032f7f9822ab8d78ff9adeb55f95eb8d172e01a6d069fd22495c0b265873dc60121037175dfbeecd8b5a54eb5ad9a696f15b7b39da2ea7d67b4cd7a3299bb95e28884\",\"output_value\":99725841,\"sequence\":4294967295,\"addresses\":[\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"],\"script_type\":\"pay-to-pubkey-hash\"}],\"outputs\":[{\"value\":2750,\"script\":\"76a91407747de3dc1873c9dbd7ceccfbfc6d71a34abac088ac\",\"addresses\":[\"mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":99702746,\"script\":\"76a9144103222e7c72b869c5e47bfe86702684531f2c9088ac\",\"addresses\":[\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":0,\"script\":\"6a20d2aeff9a376da8239f6fbcab330038b1771d637752217f367d909ec36a1048ab\",\"addresses\":null,\"script_type\":\"null-data\",\"data_hex\":\"d2aeff9a376da8239f6fbcab330038b1771d637752217f367d909ec36a1048ab\"}]}".data(using: .utf8)

        let mockedSession = MockURLSession()
        mockedSession.respond(to: expectedURL, with: mockedData, response: mockedResponse, error: nil)
        
        let issuerURL = URL(string: "http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")!
        mockedSession.respond(to: issuerURL,
                              with: "{\"issuer_key\":[{\"date\":\"2016-08-28\",\"key\":\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"}],\"revocation_key\":[{\"date\":\"2016-08-28\",\"key\":\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"}]}".data(using: .utf8),
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, with:v1_1ValidTransactionId, chain: "testnet", session: mockedSession) { (success, errorMessage) in
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
        
        // Build mocked network request & response
        let id = certificate?.receipt?.transactionId
        let expectedURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(id!)")!
        let mockedResponse = HTTPURLResponse(url: expectedURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockedData = "{\"block_hash\":\"000000000000009924d4d472cfb6d81b10cac8b524d2835f66180440b1b7907e\",\"block_height\":925856,\"block_index\":3,\"hash\":\"39119eca980f5110cc661428cd067053d2696d78b6f8350ab411acedb843610e\",\"addresses\":[\"mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x\",\"mgrZkCBM1Z3r6BnjHLrdkBQinH7P3sWUtr\",\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\",\"mpqCxRQqEEpCnTnEbpEA5UGVMkmZgyrc9F\",\"msM9tTGxNHEsYvW4pK2JFDLW7hJNhazntb\",\"muo6VjBPkwWaCcYnXcSrmWpNugAVjsvHHW\",\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"total\":99799531,\"fees\":28747,\"size\":574,\"preference\":\"high\",\"relayed_by\":\"18.181.6.229:18333\",\"confirmed\":\"2016-08-29T17:50:53Z\",\"received\":\"2016-08-29T17:50:19.16Z\",\"ver\":1,\"lock_time\":0,\"double_spend\":false,\"vin_sz\":1,\"vout_sz\":12,\"confirmations\":467,\"confidence\":1,\"data_protocol\":\"unknown\",\"inputs\":[{\"prev_hash\":\"6773785b4dc5d2cced67d26fc0820329307a8e10dfaef50d506924984387bf0b\",\"output_index\":10,\"script\":\"47304402204c7190a7eff802a08e9b7857b3006c0ef1e74effa8e26e5cfd8218eeecbfe8df02200518d6ffc838ab70750132d592c7748728da60a97a23dc588a74916312816e7e0121037175dfbeecd8b5a54eb5ad9a696f15b7b39da2ea7d67b4cd7a3299bb95e28884\",\"output_value\":99828278,\"sequence\":4294967295,\"addresses\":[\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"],\"script_type\":\"pay-to-pubkey-hash\"}],\"outputs\":[{\"value\":2750,\"script\":\"76a9149c9f432f68edd715cb0a92811b02e846105f784588ac\",\"addresses\":[\"muo6VjBPkwWaCcYnXcSrmWpNugAVjsvHHW\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a91481c706f7e6b2d9546169c1e76f50a3ee18e1e1d788ac\",\"addresses\":[\"msM9tTGxNHEsYvW4pK2JFDLW7hJNhazntb\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a9140ead9f2e0c70cd312977454caa74366f2aa9192c88ac\",\"addresses\":[\"mgrZkCBM1Z3r6BnjHLrdkBQinH7P3sWUtr\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914662cdbb1ab07d15cf2550fd64748b7cc1651c34088ac\",\"addresses\":[\"mpqCxRQqEEpCnTnEbpEA5UGVMkmZgyrc9F\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a91407747de3dc1873c9dbd7ceccfbfc6d71a34abac088ac\",\"addresses\":[\"mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":99772031,\"script\":\"76a9144103222e7c72b869c5e47bfe86702684531f2c9088ac\",\"spent_by\":\"ccb2bdb71db1536aff78bec39a27d59ba0e40f3f7c52d0f81cc16485ced38952\",\"addresses\":[\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":0,\"script\":\"6a2040ab35359d9674907b32b323042d75de3ef3586bfd482b570749b15eb24a6d68\",\"addresses\":null,\"script_type\":\"null-data\",\"data_hex\":\"40ab35359d9674907b32b323042d75de3ef3586bfd482b570749b15eb24a6d68\"}]}".data(using: .utf8)
        
        let mockedSession = MockURLSession()
        mockedSession.respond(to: expectedURL, with: mockedData, response: mockedResponse, error: nil)
        
        let issuerURL = URL(string: "http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")!
        mockedSession.respond(to: issuerURL,
                              with: "{\"issuer_key\":[{\"date\":\"2016-08-28\",\"key\":\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"}],\"revocation_key\":[{\"date\":\"2016-08-28\",\"key\":\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"}]}".data(using: .utf8),
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, chain: "testnet", session: mockedSession) { (success, errorMessage) in
            XCTAssertTrue(success)
            XCTAssertNil(errorMessage)
            testExpectation.fulfill()
        }
        XCTAssertNotNil(request)
        request!.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
}
