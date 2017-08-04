//
//  PartialIssuerTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/3/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import Blockcerts

class PartialIssuerTests: XCTestCase {
    let nameValue = "Name"
    let emailValue = "Email"
    let imageDataValue = ""
    let idValue = "https://example.com/id"
    let urlValue = "https://example.com/url"
    
    func testIssuerInV1_1Certificate() {
        guard let issuerData = getPartialIssuerFromV1_1Certificate() else {
            XCTFail("Failed to load data for this test.")
            return
        }
        
        do {
            let issuer = try PartialIssuer(dictionary: issuerData)
            XCTAssertEqual(issuer.email, "fakeEmail@gamoeofthronesxyz.org")
            XCTAssertEqual(issuer.id, URL(string:"http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")!)
        } catch {
            XCTFail("Parser threw when it shouldn't have.")
        }
    }
    
    func testIssuerInV1_2Certificate() {
        guard let issuerData = getPartialIssuerFromV1_2Certificate() else {
            XCTFail("Failed to load data for this test.")
            return
        }
        
        do {
            let issuer = try PartialIssuer(dictionary: issuerData)
            XCTAssertEqual(issuer.email, "fakeEmail@gamoeofthronesxyz.org")
            XCTAssertEqual(issuer.id, URL(string:"http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")!)
        } catch {
            XCTFail("Parser threw when it shouldn't have.")
        }
    }
    
    func testIssuerInV2_0AlphaCertificate() {
        guard let issuerData = getPartialIssuerFromV2_0AlphaCertificate() else {
            XCTFail("Failed to load data for this test.")
            return
        }
        
        do {
            let issuer = try PartialIssuer(dictionary: issuerData)
            XCTAssertEqual(issuer.email, "contact@issuer.org")
            XCTAssertEqual(issuer.id, URL(string:"https://www.blockcerts.org/samples/2.0-alpha/issuerTestnet.json")!)
        } catch {
            XCTFail("Parser threw when it shouldn't have.")
        }
    }
    
    func testIssuerInV2_0Certificate() {
        guard let issuerData = getPartialIssuerFromV2_0Certificate() else {
            XCTFail("Failed to load data for this test.")
            return
        }
        
        do {
            let issuer = try PartialIssuer(dictionary: issuerData)
            XCTAssertEqual(issuer.email, "contact@issuer.org")
            XCTAssertEqual(issuer.id, URL(string:"https://www.blockcerts.org/samples/2.0/issuer-testnet.json")!)
        } catch {
            XCTFail("Parser threw when it shouldn't have.")
        }
    }
    
    func testGeneralParserWithPartialIssuerData() {
        let issuerJSON : [String: Any] = [
            "id": idValue,
            "name": nameValue,
            "url": urlValue,
            "image": "data:image/png;base64,",
            "email": emailValue,
        ]
        
        let version = IssuerParser.detectVersion(from: issuerJSON)
        XCTAssertEqual(version, IssuerVersion.embedded)
        
        let issuer = IssuerParser.parse(dictionary: issuerJSON)
        XCTAssertNotNil(issuer)
        XCTAssertEqual(issuer?.version, .embedded)
        XCTAssertEqual(issuer?.id, URL(string: idValue)!)
    }
    
    
    private func getPartialIssuerFromV1_1Certificate() -> [String: Any]? {
        let filename = "sample_signed_cert-valid-1.1.0"
        let testBundle = Bundle(for: type(of: self))
        
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: file, options: []) as! [String : Any] else {
                return nil
        }
        
        guard let certificateData = json["certificate"] as? [String: Any],
            let issuerData = certificateData["issuer"] as? [String: Any] else {
                return nil
        }
        
        return issuerData
    }
    
    private func getPartialIssuerFromV1_2Certificate() -> [String : Any]? {
        let filename = "multiimage_1.2"
        let testBundle = Bundle(for: type(of: self))
        
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: file, options: []) as! [String : Any] else {
                return nil
        }
        
        guard let documentData = json["document"] as? [String : Any],
            let certificateData = documentData["certificate"] as? [String: Any],
            let issuerData = certificateData["issuer"] as? [String: Any] else {
                return nil
        }
        
        return issuerData
    }
    
    private func getPartialIssuerFromV2_0AlphaCertificate() -> [String: Any]? {
        let filename = "sample_cert-valid-2.0a"
        let testBundle = Bundle(for: type(of: self))
        
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: file, options: []) as! [String : Any] else {
                return nil
        }
        
        guard let certificateData = json["badge"] as? [String: Any],
            let issuerData = certificateData["issuer"] as? [String: Any] else {
                return nil
        }
        
        return issuerData
    }
    
    private func getPartialIssuerFromV2_0Certificate() -> [String: Any]? {
        let filename = "sample_cert-valid-2.0"
        let testBundle = Bundle(for: type(of: self))
        
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: file, options: []) as! [String : Any] else {
                return nil
        }
        
        guard let certificateData = json["badge"] as? [String: Any],
            let issuerData = certificateData["issuer"] as? [String: Any] else {
                return nil
        }
        
        return issuerData
    }
}
