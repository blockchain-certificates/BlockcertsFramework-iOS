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

// This enum is used to encapsuate the parse function. This is so CertificateParser is never instantiated.
enum CertificateParser {
    static func parse(data: Data) -> Certificate? {
        return CertificateV1_1(data: data)
    }
}

//
// MARK: - Certificate Protocol definition
//
// This is common data & functionality to all versions of the Certificate schema. 
//
protocol Certificate {
    var title : String { get }
    var subtitle : String? { get }
    var description: String { get }
    var image : Data { get }
    var language : String { get }
    var id : URL { get }
    
    var issuer : Issuer { get }
    var recipient : Recipient { get }
    var assertion : Assertion { get }
    var verifyData : Verify { get }
    
    init?(data: Data)
    
    func toFile() -> Data
    func verify() -> Bool
    func revoke() throws
}

// Default implementations for new Certificates.
extension Certificate {
    func toFile() -> Data {
        return Data()
    }
    
    func verify() -> Bool {
        return false
    }
    
    func revoke() throws {
        throw RevokeError.notImplemented
    }
}

// MARK: - Certificate Version 1.1
private enum MethodsForV1_1 {
    static func parse(issuerJSON: AnyObject?) -> Issuer? {
        guard let issuerData = issuerJSON as? [String : String],
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
            let isHashed = recipientData["hashed"] as? Bool,
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        guard let assertionData = assertionJSON as? [String : String],
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
        return Assertion(issuedOn: issuedOnDate,
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

struct CertificateV1_1 : Certificate {
    let version = "1.1"
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
    init?(data: Data) {
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
            let subtitleMap = certificateData["subtitle"] as? [String : String],
            let certificateImageURI = certificateData["image:certificate"] as? String,
            let certificateIdString = certificateData["id"] as? String,
            let certificateIdUrl = URL(string: certificateIdString),
            let description = certificateData["description"] as? String else {
            return nil
        }
        let certificateImage = imageData(from: certificateImageURI)
        let subtitle = subtitleMap["display"] == "FALSE" ? nil : subtitleMap["content"]
        
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.image = certificateImage
        language = ""
        id = certificateIdUrl

        
        // Use helper methods to parse Issuer, Recipient, Assert, and Verify objects.
        guard let issuer = MethodsForV1_1.parse(issuerJSON: certificateData["issuer"]) else {
                return nil
        }
        self.issuer = issuer
        
        guard let recipient = MethodsForV1_1.parse(recipientJSON: json["recipient"]) else {
                return nil
        }
        self.recipient = recipient
        
        guard let assertion = MethodsForV1_1.parse(assertionJSON: json["assertion"]) else {
                return nil
        }
        self.assertion = assertion
        
        guard let verifyData = MethodsForV1_1.parse(verifyJSON: json["verify"]) else {
                return nil
        }
        self.verifyData = verifyData
    }
}

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

