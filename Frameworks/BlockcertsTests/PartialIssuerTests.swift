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
        let filename = "sample_signed_cert-valid-1.1.0"
        let testBundle = Bundle(for: type(of: self))
        
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: file, options: []) as! [String : Any] else {
                XCTFail()
                return
        }

        guard let certificateData = json["certificate"] as? [String: Any],
            let issuerData = certificateData["issuer"] as? [String: Any] else {
                XCTFail()
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
        let filename = "multiimage_1.2"
        let testBundle = Bundle(for: type(of: self))
        
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: file, options: []) as! [String : Any] else {
                XCTFail()
                return
        }
        
        guard let documentData = json["document"] as? [String : Any],
            let certificateData = documentData["certificate"] as? [String: Any],
            let issuerData = certificateData["issuer"] as? [String: Any] else {
                XCTFail()
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
        let filename = "sample_cert-valid-2.0a"
        let testBundle = Bundle(for: type(of: self))
        
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: file, options: []) as! [String : Any] else {
                XCTFail()
                return
        }
        
        guard let certificateData = json["badge"] as? [String: Any],
            let issuerData = certificateData["issuer"] as? [String: Any] else {
                XCTFail()
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
        let filename = "sample_cert-valid-2.0"
        let testBundle = Bundle(for: type(of: self))
        
        guard let fileUrl = testBundle.url(forResource: filename, withExtension: "json"),
            let file = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: file, options: []) as! [String : Any] else {
                XCTFail()
                return
        }
        
        guard let certificateData = json["badge"] as? [String: Any],
            let issuerData = certificateData["issuer"] as? [String: Any] else {
                XCTFail()
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
}
