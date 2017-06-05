//
//  CertificateV1_2.swift
//  cert-wallet
//
//  Created by Chris Downie on 4/12/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

struct CertificateV1_2 : Certificate {
    let version = CertificateVersion.oneDotTwo
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
    
    let receipt : Receipt?
    let metadata: Metadata
    let htmlDisplay: String?
    let shareUrl: URL?
    let universalIdentifier: String
    
    init(data: Data) throws {
        file = data
        
        // Deserialize JSON
        var json: [String: AnyObject]
        do {
            try json = JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
        } catch {
            throw CertificateParserError.notValidJSON
        }
        
        guard let fileType = json["type"] as? String else {
            throw CertificateParserError.jsonLDError(description: "Missing type property")
        }
        guard var documentData = json["document"] as? [String: AnyObject] else {
            throw CertificateParserError.missingData(description: "Missing root 'document' property.")
        }
        guard var certificateData = documentData["certificate"] as? [String: AnyObject] else {
            throw CertificateParserError.missingData(description: "Missing 'document.certificate' property.")
        }
        
        switch fileType {
        case "BlockchainCertificate": break
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
        guard let certificateIdString = certificateData["id"] as? String else {
            throw CertificateParserError.missingData(description: "Missing certificate's ID property")
        }
        id = certificateIdString
        shareUrl = URL(string: certificateIdString)
        
        let certificateImage = imageData(from: certificateImageURI)
        let subtitle = certificateData["subtitle"] as? String
        
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.image = certificateImage
        language = ""
        
        // Use helper methods to parse Issuer, Recipient, Assert, and Verify objects.
        guard let issuer = MethodsForV1_2.parse(issuerJSON: certificateData["issuer"]),
            let recipient = MethodsForV1_2.parse(recipientJSON: documentData["recipient"]),
            let assertion = MethodsForV1_2.parse(assertionJSON: documentData["assertion"]),
            let verifyData = MethodsForV1_2.parse(verifyJSON: documentData["verify"]),
            let receiptData = MethodsForV1_2.parse(receiptJSON: json["receipt"]) else {
                throw CertificateParserError.genericError
        }
        self.issuer = issuer
        self.recipient = recipient
        self.assertion = assertion
        self.verifyData = verifyData
        self.receipt = receiptData
        let signatureValue = documentData["signature"] as? String
        self.signature = signatureValue
        self.metadata = assertion.metadata
        self.htmlDisplay = assertion.htmlDisplay
        universalIdentifier = assertion.uid
    }
}

enum MethodsForV1_2 {
    static func parse(issuerJSON: AnyObject?) -> Issuer? {
        return MethodsForV1_1.parse(issuerJSON: issuerJSON)
    }
    
    static func parse(recipientJSON: AnyObject?) -> Recipient? {
        guard let recipientData = recipientJSON as? [String : AnyObject],
            let identityType = recipientData["type"] as? String,
            let familyName = recipientData["familyName"] as? String,
            let givenName = recipientData["givenName"] as? String,
            let isHashed = recipientData["hashed"] as? Bool,        // difference from v1.1
            let publicKey = recipientData["publicKey"] as? String,  // difference from v1.1
            let revocationKey = recipientData["revocationKey"] as? String,  // difference from v1.1
            let identity = recipientData["identity"] as? String else {
                return nil
        }
        
        return Recipient(givenName: givenName,
                         familyName: familyName,
                         identity: identity,
                         identityType: identityType,
                         isHashed: isHashed,
                         publicAddress: publicKey,
                         revocationAddress: revocationKey)
        
    }
    
    static func parse(assertionJSON: AnyObject?) -> Assertion? {
        guard let assertionData = assertionJSON as? [String : Any],
            let issuedOnString = assertionData["issuedOn"] as? String,
            let issuedOnDate = issuedOnString.toDate(),
            let assertionID = assertionData["id"] as? String,
            let assertionIDURL = URL(string: assertionID),
            let assertionUID = assertionData["uid"] as? String else {
                return nil
        }
        
        // evidence is optional in 1.2. This is a hack workaround. This field is irritating -- we never use it practically, and it forces a
        // hosting requirement, which is why I made it optional. But it is required for OBI compliance. Still on the fence.
        let evidenceObj : AnyObject? = assertionData["evidence"] as AnyObject?
        var evidence : String = ""
        if ((evidenceObj as? String) != nil) {
            evidence = evidenceObj as! String
        }
        
        var signatureImages = [SignatureImage]()
        let signatureImageData = assertionData["image:signature"]
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
        
        var metadataJson : [String : Any] = [:]
        if let metadataString = assertionData["metadataJson"] as? String {
            do {
                let data = metadataString.data(using: .utf8)
                metadataJson = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
            } catch {
                print("Failed to parse metadata json:")
                print(metadataString)
            }
        }
        
        let htmlDisplay = assertionData["displayHtml"] as? String
        
        return Assertion(issuedOn: issuedOnDate,
                         signatureImages: signatureImages,
                         evidence: evidence,
                         uid: assertionUID,
                         id: assertionIDURL,
                         metadata: Metadata(json: metadataJson),
                         htmlDisplay: htmlDisplay)
    }
    
    static func parse(verifyJSON: AnyObject?) -> Verify? {
        return MethodsForV1_1.parse(verifyJSON: verifyJSON)
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
