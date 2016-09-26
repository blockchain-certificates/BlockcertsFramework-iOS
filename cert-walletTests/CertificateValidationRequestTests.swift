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
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(v1_1ValidTransactionId)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = "{\"block_hash\":\"00000000000c3bda534366f2e46dc9fb03710d7ccff8648ca4ca9d494f12a94d\",\"block_height\":925859,\"block_index\":40,\"hash\":\"1703d2f5d706d495c1c65b40a086991ab755cc0a02bef51cd4aff9ed7a8586aa\",\"addresses\":[\"mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x\",\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\",\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"total\":99708246,\"fees\":17595,\"size\":303,\"preference\":\"high\",\"relayed_by\":\"\",\"confirmed\":\"2016-08-29T18:51:08Z\",\"received\":\"2016-08-29T18:51:08Z\",\"ver\":1,\"lock_time\":0,\"double_spend\":false,\"vin_sz\":1,\"vout_sz\":4,\"confirmations\":451,\"confidence\":1,\"data_protocol\":\"unknown\",\"inputs\":[{\"prev_hash\":\"ae3fe5aeaf287197f1381008b1b5457d394c8f1d7a220223c50d6fe7e677b4cb\",\"output_index\":2,\"script\":\"483045022100ef49bf597ebec9e9c9b5e0bff1d925cd1c382b73b2d41a9788550d6fe8b9d27002201032f7f9822ab8d78ff9adeb55f95eb8d172e01a6d069fd22495c0b265873dc60121037175dfbeecd8b5a54eb5ad9a696f15b7b39da2ea7d67b4cd7a3299bb95e28884\",\"output_value\":99725841,\"sequence\":4294967295,\"addresses\":[\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"],\"script_type\":\"pay-to-pubkey-hash\"}],\"outputs\":[{\"value\":2750,\"script\":\"76a91407747de3dc1873c9dbd7ceccfbfc6d71a34abac088ac\",\"addresses\":[\"mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":99702746,\"script\":\"76a9144103222e7c72b869c5e47bfe86702684531f2c9088ac\",\"addresses\":[\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":0,\"script\":\"6a20d2aeff9a376da8239f6fbcab330038b1771d637752217f367d909ec36a1048ab\",\"addresses\":null,\"script_type\":\"null-data\",\"data_hex\":\"d2aeff9a376da8239f6fbcab330038b1771d637752217f367d909ec36a1048ab\"}]}".data(using: .utf8)
        mockedSession.respond(to: transactionURL, with: transactionData, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: "http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")!
        mockedSession.respond(to: issuerURL,
                              with: "{\"issuerKeys\":[{\"date\":\"2016-08-28\",\"key\":\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"}],\"revocationKeys\":[{\"date\":\"2016-08-28\",\"key\":\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"}]}".data(using: .utf8),
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
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        
        // Build mocked network request & response
        let mockedSession = MockURLSession()
        let id = certificate?.receipt?.transactionId
        let transactionURL = URL(string: "http://api.blockcypher.com/v1/btc/test3/txs/\(id!)")!
        let transactionResponse = HTTPURLResponse(url: transactionURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let transactionData = "{\"block_hash\":\"00000000f6d978e187508e1e4678632b21c44bf2402f6111d639c9d3635df020\",\"block_height\":928758,\"block_index\":20,\"hash\":\"03b2ed7e474d7577276beba4ca947fd1432f08419da05a4429417dc51e9c8b52\",\"addresses\":[\"mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x\",\"mgrZkCBM1Z3r6BnjHLrdkBQinH7P3sWUtr\",\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\",\"mpqCxRQqEEpCnTnEbpEA5UGVMkmZgyrc9F\",\"msM9tTGxNHEsYvW4pK2JFDLW7hJNhazntb\",\"muo6VjBPkwWaCcYnXcSrmWpNugAVjsvHHW\",\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"total\":199633771,\"fees\":28747,\"size\":574,\"preference\":\"high\",\"relayed_by\":\"188.166.158.139:18333\",\"confirmed\":\"2016-09-18T21:11:50Z\",\"received\":\"2016-09-18T21:07:56.151Z\",\"ver\":1,\"lock_time\":0,\"double_spend\":false,\"vin_sz\":1,\"vout_sz\":12,\"confirmations\":305,\"confidence\":1,\"data_protocol\":\"unknown\",\"inputs\":[{\"prev_hash\":\"f0015b3eb762d8ac16af852e33e5c10eb5d20a474a4e54494ff3725c9723dec7\",\"output_index\":10,\"script\":\"47304402204617b3b0d363b26b93844b37988c3bd6ba67ba88ee2837a91a6604c12ed6c99802203c9247260ed60aeb6d6753c3e369ed2ff7d001a2fac8dccaa3f733c10f95abf40121037175dfbeecd8b5a54eb5ad9a696f15b7b39da2ea7d67b4cd7a3299bb95e28884\",\"output_value\":199662518,\"sequence\":4294967295,\"addresses\":[\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"],\"script_type\":\"pay-to-pubkey-hash\"}],\"outputs\":[{\"value\":2750,\"script\":\"76a914662cdbb1ab07d15cf2550fd64748b7cc1651c34088ac\",\"addresses\":[\"mpqCxRQqEEpCnTnEbpEA5UGVMkmZgyrc9F\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a91407747de3dc1873c9dbd7ceccfbfc6d71a34abac088ac\",\"addresses\":[\"mgCNaPM3TFhh8Yn6U6VcEM9jWLhQbizy1x\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a9149c9f432f68edd715cb0a92811b02e846105f784588ac\",\"addresses\":[\"muo6VjBPkwWaCcYnXcSrmWpNugAVjsvHHW\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a9140ead9f2e0c70cd312977454caa74366f2aa9192c88ac\",\"addresses\":[\"mgrZkCBM1Z3r6BnjHLrdkBQinH7P3sWUtr\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a91481c706f7e6b2d9546169c1e76f50a3ee18e1e1d788ac\",\"addresses\":[\"msM9tTGxNHEsYvW4pK2JFDLW7hJNhazntb\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":2750,\"script\":\"76a914cc0a909c4c83068be8b45d69b60a6f09c2be0fda88ac\",\"addresses\":[\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":199606271,\"script\":\"76a9144103222e7c72b869c5e47bfe86702684531f2c9088ac\",\"addresses\":[\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"],\"script_type\":\"pay-to-pubkey-hash\"},{\"value\":0,\"script\":\"6a20222861e011ab191dc77b3de44a2d54a939d5a6135fc17e2b2a65cc52c2f45543\",\"addresses\":null,\"script_type\":\"null-data\",\"data_hex\":\"222861e011ab191dc77b3de44a2d54a939d5a6135fc17e2b2a65cc52c2f45543\"}]}".data(using: .utf8)
        
        mockedSession.respond(to: transactionURL, with: transactionData, response: transactionResponse, error: nil)
        
        let issuerURL = URL(string: "http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")!
        mockedSession.respond(to: issuerURL,
                              with: "{\"id\":\"http://cert-intro.herokuapp.com/issuer/the-issuer.json\",\"url\":\"http://cert-intro.herokuapp.com/certificates/\",\"introductionURL\":\"http://cert-intro.herokuapp.com/intro/\",\"name\":\"Some organization\",\"email\":\"org@org.org\",\"image\":\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAW0AAAFtCAYAAADMATsiAAAAAXNSR0IArs4c6QAAAAlwSFlzAAAuIwAALiMBeKU/dgAAActpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgICAgIDx4bXA6Q3JlYXRvclRvb2w+QWRvYmUgSW1hZ2VSZWFkeTwveG1wOkNyZWF0b3JUb29sPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KsiN+8QAAIVFJREFUeAHt3QWsHNXbx/FTwYpDcS8EDxCc4NBAiwZIcQ9QPHhIsCKBwh8pEAhaIGiQFncplOAUK+5uLVDc5z3PvsxmZ54zu3tvd+aec893knZ3zo48+zlzf3fv7Egf8/9D8t8jDwgggAACHgv09bg2SkMAAQQQyAkQ2jkQRhFAAAGfBQhtn3uH2hBAAIGcAKGdA2EUAQQQ8Fmgf1FxScJ3k0U2tCOAAAJVCPTp00ethk/aioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF8BQtvfvqEyBBBAQAkQ2oqEBgQQQMBfAULb376hMgQQQEAJENqKhAYEEEDAXwFC29++oTIEEEBACRDaioQGBBBAwF+B/v6WFn5ln3/+uTn11FOdb2T//fc3K620kvO1xsbJkyeb4447rrGp/vy0004zAwcOrI/zxJgvvvjCnHLKKYpir732MmussYZqpwGB0AQI7RJ7bIEFFjCffPKJue+++9RaJNDvuusu1Z5vuPzyy82ll16abzbbbrstga1UjJkyZYrTa4MNNiC0HV40hSfA7pGS++yss85yruHuu+82r7zyivO1tPG3334z//vf/9LRzKN8ymZAAIH4BAjtkvt8+eWXN8OHD3eu5cwzz3S2p4033XST+e6779LR+uO+++5rlllmmfo4TxBAIB4BQruCvj7xxBNN//56T9SNN95o3n33XWcF//77rznjjDPUa3379jWyPAYEEIhTgNCuoN/nn39+c9JJJznXdPbZZzvb7733XmegH3300WbBBRd0zkMjAgj0fgFCu6I+Puyww5xfHMoXjZ9++qmqwrXrZIYZZjAS2q2GP//800ycONE88cQT5uuvv241uZevf//997UjQbwszlFUWeZJkpgvv/zS/P333461Tl1TWTVPXVXM3UpA/83eag5e75bATDPNZORLyb333jszv/xQjho1ypxzzjn19meffdY8+eST9fH0yYgRI8ycc86ZjmYeH374YXPdddeZCRMmmNdeey3z2myzzWZWX3312tETRx11lJllllkyr+dHTj/9dPUl6XbbbWe23377/KS18c8++8wceeSR6jWpZ5pppsm0X3zxxebxxx/PtMn7kn30cnij7BKSX2Q//vijWXfddWu/eDITezTSSfPGtzVp0iRz2WWXGdkOxo0bV7Po06ePWXHFFc1uu+1mDj300NrutuOPP179NSbb2CKLLNK4uMzzsmrOrISRSgQSu5bMPxsmDB0W+Ouvv5Jll1024yzu/fr1S7755pv62oYNG6ammWuuuZKff/65Pk36RJZpf3jV9Pn+TMcHDRqUvPTSS+nszsehQ4eq5Z188snOaaXx9ddfV9PL+uzRL2oe+0tLTTt+/PjE7ttP5phjjsxrNrTV/K0a3njjjcwy0vdtvz9oNWvbr5dhnq78zTffTGzoOt9D+l5WW2215IcffkjsL2I13auvvpouKvNYZs2ZFTHSUYG0zxsf2T1iNaoa5MvIc889V63un3/+MRdddFGtXb6YvOWWW9Q08gl0xhlnzLTLn80bbrih6crhfx988IFZeeWVzRVXXJFZVk+O/PLLL2azzTZzHinTk3W51l2muXyqlr75+OOPXauutz3//PNGjiCy6VBva/akzJqbrZfXyhVQv7E7+uuChWUENtlkE+Vt91fXPj0dfPDB6rUlllgikU9K+cH1idxuJmr+oraiT9xVf9JeddVVnTX7+Em7LPNff/01kb+mivqq3XbXJ+2yas5vj4x3XsDV73zStipVD64TbuREGrsLwsg+3/wgX0rmDxl8+umnnZ/I7Q9+bd+2/TPbfPvtt+bRRx81e+yxR36RtfFjjjnG2V514wsvvFD1Kru1vjLNr7nmmlp/5QubdtppjQ3d2j5u+Stt8803z0/SdLzMmpuumBdLF1C/4Tv/O4MlNgrss88+ytz2smqT/Zf2mO3GWWvja6+9tpp26aWXTuzp8Zlp05GRI0eq6WV9999/fzpJ/bHqT9rp+954442Tq6++OrFfpib2pKLE/tKp19Tuk7L2aUsflGX++++/J/PNN5/qHxvYyTvvvKPeut21paZNDRs/aZdZsyqKhlIE0n7NPdpRR1iUUgELrQvYw/xqX0C67Bvb7Cfl+jzpkxdffNH5QztmzJh0EvVoDxlLFl98cTWf/eSmpu2J0LZHpyR//PGHqqWrDWWFdpnmDzzwgOoX2QZuvfXWwre/0047OedpDO0yay4sjBc6KtCYBelzdo9YiZ4Y5ASZE044oemqhwwZUvuiMT/R22+/nW8ycgLPVlttpdrTBnuEijniiCPS0fqj3a9df95TT2TXz7XXXmtkV4CvQ5nmH374oXrbcqikXBSsaGjneP0yay6qi/byBQjt8o0L1yAhag9zK3zddRq7TPzWW2+peeQyrxLMzQZ7uKF6WS5lag8lVO1VNmyxxRZGThzyeSjT/P3331dvXY4ikWOziwZXX+anLbPm/LoYr06A0K7OWq1p5plnNq4zH2XCXXfdtfB623YXgFrWoosuqtryDXKpWNfgCg3XdGW1hXBafpnm7733nqJdYYUVVFtjw3TTTWfkS+dmQ5k1N1svr5UrQGiX69ty6XKctWuwX8q5mmttcrZgfhgwYEC+SY0XfZr96aef1LRVNjT7a6PKOpqtq0xzl3+rs1al1vzZpvn6y6w5vy7GqxMgtKuz7tia7FEiallys4VWg+wKcQ32LElXc9ttrsvHtj2znbDVbp2uLKusacs0t8fhq7Jffvll1dbYYI/bb3ltljJrbqyF59UKENrVendkbUsttZRajpzp2GpwXZhKvvyzh5tlZpU/vfODXFyoaJBjwnv7UKa5PapH8T311FNNz3j86KOP1Dz5hjJrzq+L8eoECO3qrDu2piWXXFItS05QcR0t0DihXL87P8gXmPkvvFwXpZITdYoG177TomlDbS/T3BXacrLVI488Ush14YUXFr6WvlBmzek6eKxegNCu3nyq12hP+zaufdj2BJrCZcuV/2677Tb1+pZbbqnaXPuYH3zwQeflQeUTn5zN19uHMs3tCVTqF6d4ypmQcgXF/PDQQw+ZdkK7zJrzNTFevYA6UL+jR4izsEIBe+SAsrfdn1x11VWF88gL5513nnO+/fbbL5Ez7BoHe13txH6xpaafffbZE/tlVeOktedXXnmlmlZq2nPPPevT290lib1wUSJnYcprrn/tXuWv2RUEVXEtGuynfmctcmLROuus06V/9iJembWVaW4vbeusW86UtNdiT+xNoGsn2xxwwAHO6VL/xpNrpPgya87gMFKKQNqvuUc76vihK6UCFqoEuhvaEogLLbSQ8wfYnqySrLfeeolcKGjhhRd2TiN9bu/y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qxZVXIuGrob2l19+qUzE0O5qarEmXkagHAFXNrN7xKr0huGee+5Rb0PO9rOfflV7//79a7sBVllllcxrjz32WG3f9iyzzJJpd41st912tWt2TDvttOrlqmtRBfzXcPjhh5tvvvkm8/KSSy6ZGW8ckSNrXIMNc9NsPtc8tCFQlgChXZZsxct955131BrlKoJFwworrGAkvP/+++/MJM8995yRfbvNBplPzhp0BbbMV2UtzeosOgSxaB55X/ILK/+lrIQ2AwK+CBDaPdgTckW59dZbr2UFjz/+uNlpp52aTidfJuaHUaNGmSuuuCLfXB//999/68/TJ5988kn6tPBRjv2WY72LhiprKaqhu+0LLbSQydf/2WefdXdxzIdAxwUI7Y6Ttr9A+XN8vvnmazmDnLjSbLDHEhtX2LZ71EnjsuXMxlbDggsuWDhJ1bUUFtLNF+aff34V2p9//nk3l8ZsCHRegOO0O29a+RLbCdp2i8rvLnHN1+yXSNW1uOqbmraZZppJzV60G0hNSAMCFQjwSbsC5LJXMc8885h+/fqZf/75J7Oqgw46qOlujMzE/43kv5x0TSPrKhqqrqWoju62y8k4+UF2mTAg4IsAoe1LT0xFHX379jXyxaLcIadxkOuLtBPCjfNM7XOfaunOe/nqq6/UbM12B6mJaUCgZAF2j5QMXNXil19+ebWqfIirCUpq8KmWrr5FV2gvsMACXV0M0yNQmgCftEujrXbBSy+9tFqh3AxYjjqZccYZ1Wsvv/yycR0SePPNN5t5551XTd+VBl9quf/++01+H/vCCy9s1l57befbkf35P/30k3qN0FYkNHggoM4EK+f8njiXWnRGZCev8idX3bP7mlU/ylX87AkmGXh7d3jnVQBt2GamkxHXGZEnn3yymq6xoaxaGtfRzvOunhFpP2UrP7kMgA3zdlbHNAh0XMD+blDbJLtHPPiN2YkSllhiCXPBBReoRclFqeR62muttZY55phjate8XmyxxZxXATzzzDPV/N1p8KmWrtTvuumB3K292RevXVk+0yLQCQF2j3RC0ZNl7L///mbMmDHmkUceURU988wzRv4VDXJ1wK222qro5S63+1RLu8Xb67SoSe1fKqqNBgR6UoBP2j2p3+F1y5Eb119/feEdZFyrk3kuueQS56d01/TttvlUS7s15+/kI98FyP0jGRDwSYDQ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\",\"issuerKeys\":[{\"date\":\"2016-08-28\",\"key\":\"mmShyF6mhf6LeQzPdEsmiCghhgMuEn9TNF\"}],\"revocationKeys\":[{\"date\":\"2016-08-28\",\"key\":\"mz7poFND7hVGRtPWjiZizcCnjf6wEDWjjT\"}]}".data(using: .utf8),
                              response: HTTPURLResponse(url: issuerURL, statusCode: 200, httpVersion: nil, headerFields:nil)!,
                              error: nil)
        
        class MockJSONLD : JSONLD {
            func compact(docData: Data, context: [String : Any]?, callback: ((Error?, [String : Any]?) -> Void)?) {
                if let reformatted = try? JSONSerialization.jsonObject(with: docData, options: []),
                    let result = reformatted as? [String: Any] {
                    callback?(nil, result)
                } else {
                    callback?(nil, nil)
                }
            }
        }
        
        // Make the validation request.
        let request = CertificateValidationRequest(for: certificate!, chain: "testnet", jsonld: MockJSONLD(), session: mockedSession) { (success, errorMessage) in
            XCTAssertTrue(success)
            XCTAssertNil(errorMessage)
            testExpectation.fulfill()
        }
        XCTAssertNotNil(request)
        request!.start()
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
}
