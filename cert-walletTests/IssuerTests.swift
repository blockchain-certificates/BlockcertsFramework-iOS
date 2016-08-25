//
//  IssuerTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/25/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest

class IssuerTests: XCTestCase {
    let nameValue = "Name"
    let emailValue = "Email"
    let imageDataValue = ""
    let idValue = "https://example.com/id"
    let urlValue = "https://example.com/url"
    let publicKeyValue = "BadPublicKey"
    let publicKeyAddressValue = "https://example.com/pubkey"
    let requestUrlValue = "https://example.com/request"
    

    func testDictionaryConversion() {
        let issuer = Issuer(name: nameValue,
                            email: emailValue,
                            image: Data(base64Encoded: imageDataValue)!,
                            id: URL(string: idValue)!,
                            url: URL(string: urlValue)!,
                            publicKey: publicKeyValue,
                            publicKeyAddress: URL(string: publicKeyAddressValue)!,
                            requestUrl: URL(string: requestUrlValue)!)
        let expectedResult = [
            "name": nameValue,
            "email": emailValue,
            "image": imageDataValue,
            "id": idValue,
            "url": urlValue,
            "publicKey": publicKeyValue,
            "publicKeyAddress": publicKeyAddressValue,
            "requestUrl": requestUrlValue
        ]
        
        let result = issuer.toDictionary()
        XCTAssertEqual(result, expectedResult)
    }
    
    func testDictionaryInitialization() {
        let input = [
            "name": nameValue,
            "email": emailValue,
            "image": imageDataValue,
            "id": idValue,
            "url": urlValue,
            "publicKey": publicKeyValue,
            "publicKeyAddress": publicKeyAddressValue,
            "requestUrl": requestUrlValue
        ]
        let expectedResult = Issuer(name: nameValue,
                                    email: emailValue,
                                    image: Data(base64Encoded: imageDataValue)!,
                                    id: URL(string: idValue)!,
                                    url: URL(string: urlValue)!,
                                    publicKey: publicKeyValue,
                                    publicKeyAddress: URL(string: publicKeyAddressValue)!,
                                    requestUrl: URL(string: requestUrlValue)!)
        let result = Issuer(dictionary: input)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, expectedResult)
    }
}
