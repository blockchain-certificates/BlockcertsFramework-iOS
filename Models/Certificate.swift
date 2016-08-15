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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        // Deserialize JSON
        var json: [String: AnyObject]
        do {
            try json = JSONSerialization.jsonObject(with: file, options: []) as! [String: AnyObject]
        } catch {
            return nil
        }
        
        // Creating dummy objects with terrible values to pass the type checker for now
        guard let certificateData = json["certificate"] as? [String: AnyObject] else {
            return nil
        }
        
        guard let issuerData = certificateData["issuer"] as? [String: String],
            let issuerURLString = issuerData["url"],
            let issuerURL = URL(string: issuerURLString),
            let logoURI = issuerData["image:logo"],
            let issuerEmail = issuerData["email"],
            let issuerName = issuerData["name"],
            let issuerId = issuerData["id"],
            let issuerIdURL = URL(string: issuerId) else {
                return nil
        }
        let logo = imageData(from: logoURI)
        let issuer = Issuer(name: issuerName, email: issuerEmail, image: logo, id: issuerIdURL, url: issuerURL, publicKey: "", publicKeyAddress: URL(string: "https://google.com")!, requestUrl: URL(string: "https://google.com")!)
        
        
        guard let recipientData = json["recipient"] as? [String : AnyObject],
            let identityType = recipientData["type"] as? String,
            let familyName = recipientData["familyName"] as? String,
            let givenName = recipientData["givenName"] as? String,
            let isHashed = recipientData["hashed"] as? Bool,
            let publicKey = recipientData["pubkey"] as? String,
            let identity = recipientData["identity"] as? String else {
                return nil
        }
        let recipient = Recipient(givenName: givenName, familyName: familyName, identity: identity, identityType: identityType, isHashed: isHashed, publicKey: publicKey)
        
        guard let assertionData = json["assertion"] as? [String : String],
            let issuedOnString = assertionData["issuedOn"],
            let issuedOnDate = dateFormatter.date(from: issuedOnString),
            let signatureImageURI = assertionData["image:signature"],
            let assertionId = assertionData["id"],
            let assertionIdUrl = URL(string: assertionId),
            let assertionUid = assertionData["uid"],
            let evidence = assertionData["evidence"] else {
                return nil
        }
        let signatureImage = imageData(from: signatureImageURI)
        let assertion = Assertion(issuedOn: issuedOnDate, signatureImage: signatureImage, evidence: evidence, uid: assertionUid, id: assertionIdUrl)
        
        
        // This is how I expect to be able to parse the JSON into the typed object we've defined.
        guard let verifyData = json["verify"] as? [String : String],
            let signer = verifyData["signer"],
            let signedAttribute = verifyData["attribute-signed"],
            let type = verifyData["type"],
            let signerUrl = URL(string: signer) else {
                return nil
        }
        let verify = Verify(signer: signerUrl, signedAttribute: signedAttribute, type: type)
        
        guard let title = certificateData["title"] as? String,
            let subtitleMap = certificateData["subtitle"] as? [String : String],
            let certificateImageURI = certificateData["image:certificate"] as? String,
            let certificateIdString = certificateData["id"] as? String,
            let certificateIdUrl = URL(string: certificateIdString),
            let description = certificateData["description"] as? String else {
                return nil
        }
        let certificateImage = imageData(from: certificateImageURI)
        let subtitle = subtitleMap["display"] == "FALSE" ? nil : subtitleMap["content"]
        return Certificate(title: title, subtitle: subtitle, description: description, image: certificateImage, language: "", id: certificateIdUrl, issuer: issuer, recipient: recipient, assertion: assertion, verifyData: verify)
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
    
    private static func imageData(from dataURI: String?) -> Data {
        guard let dataURI = dataURI else {
            // Passed in an empty string. Return empty data.
            return Data()
        }
        guard let imageUrl = URL(string: dataURI) else {
            // dataURI is invalid. Probably didn't start with `data:`
            return Data()
        }
        do {
            return try Data(contentsOf: imageUrl)
        } catch {
            return Data()
        }
    }
}

