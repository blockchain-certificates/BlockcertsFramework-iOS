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

enum CertificateVersion {
    case oneDotOne
    case oneDotTwo
}

// This enum is used to encapsuate the parse function. This is so CertificateParser is never instantiated.
enum CertificateParser {
    static func parse(data: Data) -> Certificate? {
        return CertificateParser.parse(data: data, withMinimumVersion: .oneDotOne)
    }
    
    static func parse(data: Data, asVersion version: CertificateVersion) -> Certificate? {
        switch version {
        case .oneDotTwo:
            return CertificateV1_2(data: data)
        case .oneDotOne:
            return CertificateV1_1(data: data)
        }
    }
    
    static func parse(data: Data, withMinimumVersion version: CertificateVersion) -> Certificate? {
        var cert : Certificate?
        switch version {
        case .oneDotOne:
            if cert == nil {
                cert = CertificateV1_1(data: data)
            }
            fallthrough
        case .oneDotTwo:
            if cert == nil {
                cert = CertificateV1_2(data: data)
            }
        }
        return cert
    }
}

//
// MARK: - Certificate Protocol definition
//
// This is common data & functionality to all versions of the Certificate schema. 
//
protocol Certificate {
    var version : CertificateVersion { get }
    
    var title : String { get }
    var subtitle : String? { get }
    var description: String { get }
    var image : Data { get }
    var language : String { get }
    var id : URL { get }
    var file : Data { get }
    var signature : String? { get }

    var issuer : Issuer { get }
    var recipient : Recipient { get }
    var assertion : Assertion { get }
    var verifyData : Verify { get }
    var receipt : Receipt? { get }
    
    init?(data: Data)
    
    func verify() -> Bool
    func revoke() throws
}

// Default implementations for new Certificates.
extension Certificate {
    func verify() -> Bool {
        return false
    }
    
    func revoke() throws {
        throw RevokeError.notImplemented
    }
}


//
// MARK: - Private Implementation Details
//
// Below here, everything is private. This includes:
// * The concrete types for different versions of Certificate
// * Any version-specific or version-agnostic helper functions


// These are useful parsing functions that are version-independent.
private func imageData(from dataURI: String?) -> Data {
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


// MARK: Certificate Version 1.1
private enum MethodsForV1_1 {
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
        
        return Issuer(name: issuerName,
                      email: issuerEmail,
                      image: logo,
                      id: issuerIdURL,
                      url: issuerURL,
                      publicKey: "",
                      publicKeyAddress: URL(string: "https://google.com")!,
                      requestUrl: URL(string: "https://google.com")!)
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
                         publicKey: publicKey)
    }
    
    static func parse(assertionJSON: AnyObject?) -> Assertion? {
        // TODO: the json schema allowed datetime, which inclues yyyy-MM-dd and TBD others. How can we make date formatter
        // accept multiple string formats?
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd"
        
        guard let assertionData = assertionJSON as? [String : String],
            let issuedOnString = assertionData["issuedOn"],
            let signatureImageURI = assertionData["image:signature"],
            let assertionId = assertionData["id"],
            let assertionIdUrl = URL(string: assertionId),
            let assertionUid = assertionData["uid"] else {
                return nil
        }
        
        var issuedOnDate : Date?
        
        if let iod = dateFormatter.date(from: issuedOnString) as Date? {
            issuedOnDate = iod
        } else {
            issuedOnDate = dateFormatter2.date(from: issuedOnString)
        }
        
        if issuedOnDate == nil {
            // issuedOnDate didn't match either format
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
        return Assertion(issuedOn: issuedOnDate!,
                         signatureImage: signatureImage,
                         evidence: evidence,
                         uid: assertionUid,
                         id: assertionIdUrl)
    }
    
    static func parse(verifyJSON: AnyObject?) -> Verify? {
        guard let verifyData = verifyJSON as? [String : String],
            let signer = verifyData["signer"],
            let signedAttribute = verifyData["attribute-signed"],
            let type = verifyData["type"],
            let signerUrl = URL(string: signer) else {
                return nil
        }
        
        return Verify(signer: signerUrl, signedAttribute: signedAttribute, type: type)
    }
}

private struct CertificateV1_1 : Certificate {
    let version = CertificateVersion.oneDotOne
    let title : String
    let subtitle : String?
    let description: String
    let image : Data
    let language : String
    let id : URL
    let file : Data
    let signature: String?
    
    let issuer : Issuer
    let recipient : Recipient
    let assertion : Assertion
    let verifyData : Verify
    let receipt: Receipt? = nil
    
    init?(data: Data) {
        self.file = data
        
        // Deserialize JSON
        var json: [String: AnyObject]
        do {
            try json = JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
        } catch {
            return nil
        }
        
        // Get any key properties on the Certificate object
        guard let certificateData = json["certificate"] as? [String: AnyObject],
            let title = certificateData["title"] as? String,
            let subtitleMap = certificateData["subtitle"] as? [String : AnyObject],
            let certificateImageURI = certificateData["image"] as? String,
            let certificateIdString = certificateData["id"] as? String,
            let certificateIdUrl = URL(string: certificateIdString),
            let description = certificateData["description"] as? String else {
            return nil
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
        id = certificateIdUrl

        
        // Use helper methods to parse Issuer, Recipient, Assert, and Verify objects.
        guard let issuer = MethodsForV1_1.parse(issuerJSON: certificateData["issuer"]),
            let recipient = MethodsForV1_1.parse(recipientJSON: json["recipient"]),
            let assertion = MethodsForV1_1.parse(assertionJSON: json["assertion"]),
            let verifyData = MethodsForV1_1.parse(verifyJSON: json["verify"]) else {
                return nil
        }
        self.issuer = issuer
        self.recipient = recipient
        self.assertion = assertion
        self.verifyData = verifyData
        self.signature = json["signature"] as? String
    }
}

// MARK: Certificate Version 1.2
private enum MethodsForV1_2 {
    static func parse(issuerJSON: AnyObject?) -> Issuer? {
        guard let issuerData = issuerJSON as? [String : String],
            let issuerURLString = issuerData["url"],
            let issuerURL = URL(string: issuerURLString),
            let logoURI = issuerData["image:logo"], // main difference from v1.1
            let issuerEmail = issuerData["email"],
            let issuerName = issuerData["name"],
            let issuerId = issuerData["id"],
            let issuerIdURL = URL(string: issuerId) else {
                return nil
        }
        let logo = imageData(from: logoURI)
        
        return Issuer(name: issuerName,
                      email: issuerEmail,
                      image: logo,
                      id: issuerIdURL,
                      url: issuerURL,
                      publicKey: "",
                      publicKeyAddress: URL(string: "https://google.com")!,
                      requestUrl: URL(string: "https://google.com")!)
    }
    
    static func parse(recipientJSON: AnyObject?) -> Recipient? {
        guard let recipientData = recipientJSON as? [String : AnyObject],
            let identityType = recipientData["type"] as? String,
            let familyName = recipientData["familyName"] as? String,
            let givenName = recipientData["givenName"] as? String,
            let isHashed = recipientData["hashed"] as? Bool, // main difference from v1.1
            let publicKey = recipientData["pubkey"] as? String,
            let identity = recipientData["identity"] as? String else {
                return nil
        }
        
        return Recipient(givenName: givenName,
                         familyName: familyName,
                         identity: identity,
                         identityType: identityType,
                         isHashed: isHashed,
                         publicKey: publicKey)

    }
    static func parse(assertionJSON: AnyObject?) -> Assertion? {
        return MethodsForV1_1.parse(assertionJSON: assertionJSON)
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

private struct CertificateV1_2 : Certificate {

    let version = CertificateVersion.oneDotTwo
    let title : String
    let subtitle : String?
    let description: String
    let image : Data
    let language : String
    let id : URL
    let file : Data
    let signature: String?
    
    let issuer : Issuer
    let recipient : Recipient
    let assertion : Assertion
    let verifyData : Verify
    
    let receipt : Receipt?
    
    init?(data: Data) {
        file = data
        
        // Deserialize JSON
        var json: [String: AnyObject]
        do {
            try json = JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
        } catch {
            return nil
        }
        
        guard let fileType = json["@type"] as? String,
            var documentData = json["document"] as? [String: AnyObject],
            var certificateData = documentData["certificate"] as? [String: AnyObject] else {
                return nil
        }
        
        switch fileType {
        case "IssuedCertificate":
            print("issuedCert")
            let possibleCertificateData = certificateData["certificate"] as? [String: AnyObject]
            json = certificateData
            if (possibleCertificateData != nil) {
                certificateData = possibleCertificateData!
            } else {
                return nil
            }
        case "BlockchainCertificate": break // Nothing special to do in this case, as the normal validation is below.
        default:
            return nil
        }
        
        
        // Validate normal certificate data
        guard let title = certificateData["title"] as? String,
            let certificateImageURI = certificateData["image:certificate"] as? String,
            let certificateIdString = certificateData["id"] as? String,
            let certificateIdUrl = URL(string: certificateIdString),
            let description = certificateData["description"] as? String else {
                return nil
        }
        let certificateImage = imageData(from: certificateImageURI)
        let subtitle = certificateData["subtitle"] as? String
        
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.image = certificateImage
        language = ""
        id = certificateIdUrl
        
        
        // Use helper methods to parse Issuer, Recipient, Assert, and Verify objects.
        guard let issuer = MethodsForV1_2.parse(issuerJSON: certificateData["issuer"]),
            let recipient = MethodsForV1_2.parse(recipientJSON: documentData["recipient"]),
            let assertion = MethodsForV1_2.parse(assertionJSON: documentData["assertion"]),
            let verifyData = MethodsForV1_2.parse(verifyJSON: documentData["verify"]),
            let receiptData = MethodsForV1_2.parse(receiptJSON: json["receipt"]) else {
                return nil
        }
        self.issuer = issuer
        self.recipient = recipient
        self.assertion = assertion
        self.verifyData = verifyData
        self.receipt = receiptData
        self.signature = documentData["signature"] as? String
    }
}

