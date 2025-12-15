//
//  CertificateV1_1.swift
//  cert-wallet
//
//  Created by Chris Downie on 4/12/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

struct CertificateV1_1 : Certificate {
    let version = CertificateVersion.oneDotOne
    let title : String
    let subtitle : String?
    let description: String
    let image : Data
    let language : String
    let id : String
    let file : Data
    let signature: String?
    
    let issuer : Issuer
    let recipient : Recipient
    let assertion : Assertion
    let verifyData : Verify
    let receipt: Receipt? = nil
    let metadata: Metadata
    let shareUrl: URL?
    
    init(data: Data) throws {
        self.file = data
        
        // Deserialize JSON
        var json: [String: AnyObject]
        do {
            try json = JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
        } catch {
            throw CertificateParserError.notValidJSON
        }
        
        // Get any key properties on the Certificate object
        guard let certificateData = json["certificate"] as? [String: AnyObject],
            let title = certificateData["title"] as? String,
            let subtitleMap = certificateData["subtitle"] as? [String : AnyObject],
            let certificateImageURI = certificateData["image"] as? String,
            let certificateIdString = certificateData["id"] as? String,
            let certificateIdUrl = URL(string: certificateIdString),
            let description = certificateData["description"] as? String else {
                throw CertificateParserError.genericError
        }
        let certificateImage = imageData(from: certificateImageURI)
        var subtitle : String? = nil
        if let subtitleDisplay = subtitleMap["display"] as? Bool,
            subtitleDisplay {
            subtitle = subtitleMap["content"] as? String
        } else if let subtitleDisplayStr = subtitleMap["display"] as? String,
            subtitleDisplayStr.uppercased() == "TRUE" {
            subtitle = subtitleMap["content"] as? String
        }
        
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.image = certificateImage
        language = ""
        id = certificateIdString
        shareUrl = certificateIdUrl
        
        
        // Use helper methods to parse Issuer, Recipient, Assert, and Verify objects.
        guard let issuer = MethodsForV1_1.parse(issuerJSON: certificateData["issuer"]),
            let recipient = MethodsForV1_1.parse(recipientJSON: json["recipient"]),
            let assertion = MethodsForV1_1.parse(assertionJSON: json["assertion"]),
            let verifyData = MethodsForV1_1.parse(verifyJSON: json["verify"]) else {
                throw CertificateParserError.genericError
        }
        self.issuer = issuer
        self.recipient = recipient
        self.assertion = assertion
        self.verifyData = verifyData
        let signatureValue = json["signature"] as? String
        self.signature = signatureValue
        self.metadata = assertion.metadata
    }
}

enum MethodsForV1_1 {
    static func parse(issuerJSON: AnyObject?) -> Issuer? {
        guard let issuerData = issuerJSON as? [String : String],
            let issuerURLString = issuerData["url"],
            let issuerURL = URL(string: issuerURLString),
            let logoURI = issuerData["image"],
            let issuerEmail = issuerData["email"],
            let issuerName = issuerData["name"],
            let issuerId = issuerData["id"],
            let issuerIdURL = URL(string: issuerId) else {
                return nil
        }
        let logo = imageData(from: logoURI)
        
        return IssuerV1(name: issuerName,
                        email: issuerEmail,
                        image: logo,
                        id: issuerIdURL,
                        url: issuerURL)
    }
    
    static func parse(recipientJSON: AnyObject?) -> Recipient? {
        
        guard let recipientData = recipientJSON as? [String : AnyObject],
            let identityType = recipientData["type"] as? String,
            let familyName = recipientData["familyName"] as? String,
            let givenName = recipientData["givenName"] as? String,
            let isHashedObj = recipientData["hashed"],
            let publicKey = recipientData["pubkey"] as? String,
            let identity = recipientData["identity"] as? String else {
                return nil
        }
        
        var hashed : Bool = false
        
        switch isHashedObj {
        case let value as Bool:
            hashed = value
        case let value as String:
            hashed = value.uppercased() == "TRUE"
        default:
            // error -- unrecognized type
            return nil
        }
        
        return Recipient(givenName: givenName,
                         familyName: familyName,
                         identity: identity,
                         identityType: identityType,
                         isHashed: hashed,
                         publicAddress: publicKey,
                         revocationAddress: nil)
    }
    
    static func parse(assertionJSON: AnyObject?) -> Assertion? {
        guard let assertionData = assertionJSON as? [String : String],
            let issuedOnString = assertionData["issuedOn"],
            let issuedOnDate = issuedOnString.toDate(),
            let signatureImageURI = assertionData["image:signature"],
            let assertionId = assertionData["id"],
            let assertionIdUrl = URL(string: assertionId),
            let assertionUid = assertionData["uid"]else {
                return nil
        }
        
        // evidence is optional in 1.2. This is a hack workaround. This field is irritating -- we never use it practically, and it forces a
        // hosting requirement, which is why I made it optional. But it is required for OBI compliance. Still on the fence.
        let evidenceObj : AnyObject? = assertionData["evidence"] as AnyObject?
        var evidence : String = ""
        if ((evidenceObj as? String) != nil) {
            evidence = evidenceObj as! String
        }
        
        let signatureImage = imageData(from: signatureImageURI)
        return Assertion(issuedOn: issuedOnDate,
                         signatureImage: signatureImage,
                         evidence: evidence,
                         uid: assertionUid,
                         id: assertionIdUrl,
                         expirationDate: nil)
    }
    
    static func parse(verifyJSON: AnyObject?) -> Verify? {
        guard let verifyData = verifyJSON as? [String : String],
            let signedAttribute = verifyData["attribute-signed"],
            let type = verifyData["type"] else {
                return nil
        }
        
        var signerURL : URL? = nil
        if let signer = verifyData["signer"] {
            signerURL = URL(string: signer)
        }
        
        return Verify(signer: signerURL, publicKey: nil, signedAttribute: signedAttribute, type: type)
    }
}
