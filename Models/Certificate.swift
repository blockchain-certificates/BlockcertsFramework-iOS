//
//  Certificate.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation
//import UIKit

enum RevokeError : Error {
    case notImplemented
}

struct Certificate {
    let title : String
    let subtitle : String?
    let description: String
    let image : Data
    let language : String
    let id : URL
    
    let issuer : Issuer
    let recipient : Recipient
    let assertion : Assertion
    let verifyData : Verify
    
    // Not sure if this is better as a static func or an initialization function. This has the fewest 
    static func from(file: Data) -> Certificate? {
        // Deserialize JSON
        var json: [String: AnyObject]
        do {
            try json = JSONSerialization.jsonObject(with: file, options: []) as! [String: AnyObject]
        } catch {
            return nil
        }
        
        // Creating dummy objects with terrible values to pass the type checker for now
        let issuer = Issuer(name: "", email: "", image: Data(), id: URL(string: "https://google.com")!, url: URL(string: "https://google.com")!, publicKey: "", publicKeyAddress: URL(string: "https://google.com")!, requestUrl: URL(string: "https://google.com")!)
        let recipient = Recipient(givenName: "", familyName: "", identity: "", identityType: "", isHashed: false, publicKey: "")
        let assertion = Assertion(issuedOn: Date(), signatureImage: Data(), evidence: "", uid: "", id: URL(string: "https://google.com")!)
        
        
        // This is how I expect to be able to parse the JSON into the typed object we've defined.
        guard let verifyData = json["verify"] as? [String : String],
            let signer = verifyData["signer"],
            let signedAttribute = verifyData["attribute-signed"],
            let type = verifyData["type"],
            let signerUrl = URL(string: signer) else {
                return nil
        }
        let verify = Verify(signer: signerUrl, signedAttribute: signedAttribute, type: type)
        
        
        return Certificate(title: "", subtitle: nil, description: "", image: Data(), language: "", id: URL(string: "https://google.com")!, issuer: issuer, recipient: recipient, assertion: assertion, verifyData: verify)
    }
    
    func toFile() -> Data {
        return Data()
    }
    
    // Is verification binary? How could this fail?
    func verify() -> Bool {
        return false
    }
    
    func revoke() throws {
        throw RevokeError.notImplemented
    }
}

