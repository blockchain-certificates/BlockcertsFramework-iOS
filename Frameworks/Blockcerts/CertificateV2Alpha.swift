//
//  CertificateV2.swift
//  cert-wallet
//
//  Created by Chris Downie on 4/12/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

struct CertificateV2Alpha : Certificate {
    let version = CertificateVersion.twoAlpha
    let title : String
    let subtitle : String?
    let description: String
    let image : Data
    let language : String
    let id : String
    let file : Data
    
    let issuer : Issuer
    let recipient : Recipient
    let assertion : Assertion
    let verifyData : Verify
    let signature: String?
    
    let receipt : Receipt?
    let metadata: Metadata
    let htmlDisplay: String?
    let shareUrl: URL?
    
    
    init(data: Data) throws {
        file = data
        
        // Deserialize JSON
        var json: [String: AnyObject]
        do {
            try json = JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
        } catch {
            throw CertificateParserError.notValidJSON
        }
        
        let assertionVal = json
        guard let fileType = json["type"] as? String else {
            throw CertificateParserError.jsonLDError(description: "Missing type property")
        }
        guard var certificateData = json["badge"] as? [String: AnyObject] else {
            throw CertificateParserError.missingData(description: "Missing 'badge' property.")
        }
        
        switch fileType {
        case "Assertion": break
        default:
            throw CertificateParserError.jsonLDError(description: "Unknown file type \(fileType)")
        }
        
        // Validate normal certificate data
        guard let title = certificateData["name"] as? String else {
            throw CertificateParserError.missingData(description: "Missing certificate's title property.")
        }
        guard let certificateImageURI = certificateData["image"] as? String else {
            throw CertificateParserError.missingData(description: "Missing certificate's image property.")
        }
        guard let description = certificateData["description"] as? String else {
            throw CertificateParserError.missingData(description: "Missing certificate's description property.")
        }
        guard let certificateIdString = json["id"] as? String else {
            throw CertificateParserError.missingData(description: "Missing certificate's id property.")
        }
        id = certificateIdString
        shareUrl = URL(string: id)
        
        let certificateImage = imageData(from: certificateImageURI)
        let subtitle = certificateData["subtitle"] as? String
        
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.image = certificateImage
        language = ""
        
        // Use helper methods to parse Issuer, Recipient, Assert, and Verify objects.
        guard let issuer = MethodsForV2.parse(issuerJSON: certificateData["issuer"]),
            let recipient = MethodsForV2.parse(recipientJSON: json["recipient"]),
            let assertion = MethodsForV2.parse(assertionJSON: assertionVal as AnyObject?),
            let verifyData = MethodsForV2.parse(verifyJSON: json["verification"]),
            let receiptData = MethodsForV2.parse(receiptJSON: json["signature"]) else {
                throw CertificateParserError.genericError
        }
        self.issuer = issuer
        self.recipient = recipient
        self.assertion = assertion
        self.verifyData = verifyData
        self.receipt = receiptData
        self.signature = nil
        self.metadata = assertion.metadata
        self.htmlDisplay = json["displayHtml"] as? String
    }
}

fileprivate enum MethodsForV2 {
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
        var revocationURL : URL? = nil
        
        if issuerData["revocationList"] != nil {
            revocationURL = URL(string: issuerData["revocationList"]!)
        }
        
        return IssuerV2Alpha(name: issuerName,
                             email: issuerEmail,
                             image: logo,
                             id: issuerIdURL,
                             url: issuerURL,
                             revocationURL: revocationURL)
    }
    
    static func parse(recipientJSON: AnyObject?) -> Recipient? {
        guard let recipientData = recipientJSON as? [String : AnyObject],
            let recipientProfile = recipientData["recipientProfile"] as? [String : AnyObject],
            let name = recipientProfile["name"] as? String, // difference from v1.2
            let identityType = recipientData["type"] as? String,
            let isHashed = recipientData["hashed"] as? Bool,
            let publicKey = recipientProfile["publicKey"] as? String,  // difference from v1.2
            let identity = recipientData["identity"] as? String else {
                return nil
        }
        
        return Recipient(name: name,
                         identity: identity,
                         identityType: identityType,
                         isHashed: isHashed,
                         publicAddress: publicKey)
        
    }
    static func parse(assertionJSON: AnyObject?) -> Assertion? {
        guard let assertionData = assertionJSON as? [String : Any],
            let issuedOnString = assertionData["issuedOn"] as? String,
            let issuedOnDate = issuedOnString.toDate(),
            let assertionID = assertionData["id"] as? String else {
                return nil
        }
        
        var assertionUID : String!
        let assertionIDURL = URL(string: assertionID)
        if assertionIDURL != nil {
            assertionUID = assertionID
        } else if let range = assertionID.range(of:Constants.guidRegexp, options: .regularExpression) {
            assertionUID = assertionID.substring(with: range)
        }
        
        guard assertionUID != nil else {
            return nil
        }
        
        // evidence is optional in 1.2. This is a hack workaround. This field is irritating -- we never use it practically, and it forces a
        // hosting requirement, which is why I made it optional. But it is required for OBI compliance. Still on the fence.
        let evidenceObj : AnyObject? = assertionData["evidence"] as AnyObject?
        var evidence : String = ""
        if (evidenceObj as? String) != nil {
            evidence = evidenceObj as! String
        }
        
        var signatureImages = [SignatureImage]()
        let signatureImageData = assertionData["signatureLines"]
        if let signatureImageURI = signatureImageData as? String {
            signatureImages.append(SignatureImage(image: imageData(from: signatureImageURI), title: nil))
        } else if let signatureImageArray = signatureImageData as? [[String : Any]] {
            for var datum in signatureImageArray {
                guard let imageURI = datum["image"] as? String else {
                    return nil
                }
                let title = datum["jobTitle"] as? String
                
                signatureImages.append(SignatureImage(image: imageData(from: imageURI), title: title))
            }
        }
        
        return Assertion(issuedOn: issuedOnDate,
                         signatureImages: signatureImages,
                         evidence: evidence,
                         uid: assertionUID,
                         id: assertionIDURL)
    }
    static func parse(verifyJSON: AnyObject?) -> Verify? {
        guard let verifyData = verifyJSON as? [String : AnyObject],
            let type : Array<String> = verifyData["type"] as! Array<String>? else {
                return nil
        }
        
        var signerURL : URL? = nil
        if let signer = verifyData["creator"] {
            signerURL = URL(string: signer as! String)
        }
        
        return Verify(signer: signerURL, signedAttribute: nil, type: type[0])
    }
    
    static func parse(receiptJSON: AnyObject?) -> Receipt? {
        guard let receiptData = receiptJSON as? [String : AnyObject],
            let merkleRoot = receiptData["merkleRoot"] as? String,
            let targetHash = receiptData["targetHash"] as? String,
            let anchors = receiptData["anchors"] as? [[String : AnyObject]],
            let transactionId = anchors[0]["sourceId"] as? String,
            let proof = receiptData["proof"] as? [[String : AnyObject]] else {
                return nil
        }
        
        return Receipt(merkleRoot: merkleRoot,
                       targetHash: targetHash,
                       proof: proof,
                       transactionId : transactionId)
    }
}
