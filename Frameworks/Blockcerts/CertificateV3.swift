//
//  CertificateV3.swift
//  Blockcerts
//
//  Created by Matthieu Collé on 01/06/2022.
//  Copyright © 2022 Digital Certificates Project. All rights reserved.
//

import Foundation
import UIKit

struct CertificateV3 : Certificate {
    let version = CertificateVersion.three
    
    let title: String
    let subtitle: String?
    let description: String
    let image: Data
    let signature: String?
    let receipt: Receipt?
    
    let language : String
    let id : String
    let file : Data
    
    let recipient : Recipient
    let assertion : Assertion
    let verifyData : Verify
    let shareUrl: URL?
    
    let issuer : Issuer
    let metadata: Metadata
    let credentialSubject: [String: AnyObject]
    let issuanceDate : String
    let expirationDate : String
    
    var htmlDisplay: String?
    
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

        guard let certificateIdString = json["id"] as? String else {
            throw CertificateParserError.missingData(description: "Missing certificate's id property.")
        }
        
        var certificateTitle = ""
        var certificateDescription = ""
        
        if let credentialSubject = json["credentialSubject"] as? [String : AnyObject],
            let claim = credentialSubject["claim"] as? [String: AnyObject] {
            certificateTitle = claim["name"] as? String ?? ""
            certificateDescription = claim["description"] as? String ?? ""
        }
        
        self.title = certificateTitle
        self.description = certificateDescription
        
        id = certificateIdString
        shareUrl = URL(string: id)
        language = ""
        
        self.subtitle = ""
        self.image = imageData(from: "")
        
        // Use helper methods to parse Issuer, CredentialSubject and Display.
        guard let recipient = MethodsForV3.parse(recipientJSON: json),
              let issuerJson = MethodsForV3.parse(issuerJSON: json["issuer"] as AnyObject),
              let display = MethodsForV3.parse(displayJSON: json["display"]),
              let metadataJSON = MethodsForV3.parse(metadataJSON: json),
              let assertion = MethodsForV3.parse(assertionJSON: assertionVal as AnyObject?),
              let verifyData = MethodsForV3.parse(verifyJSON: json) else {
            throw CertificateParserError.genericError
        }
        
        self.issuer = issuerJson
        self.recipient = recipient
        self.assertion = assertion
        self.verifyData = verifyData
        self.receipt = nil // receiptData
        self.metadata = metadataJSON
        self.htmlDisplay = display
        self.signature = nil
        self.credentialSubject = json["credentialSubject"] as! [String : AnyObject]
        self.issuanceDate = json["issuanceDate"] as! String
        self.expirationDate = json["expirationDate"] as? String ?? ""
        
//        guard let receiptData = MethodsForV3.parse(receiptJSON: json["signature"]) else {
//            throw CertificateParserError.genericError
//        }
    }
}

fileprivate enum MethodsForV3 {
    
    static func getIssuerId(issuerJSON: AnyObject?) -> String? {
        if issuerJSON is String {
            return issuerJSON as? String
        } else {
            return issuerJSON?["id"] as? String
        }
    }
    
    static func fetchIssuerProfile(issuerProfileId : String) -> [String: AnyObject]? {
        if let issuerProfileUrl = URL(string: issuerProfileId) {
            do {
                let parsedJson: [String: AnyObject] = try deserializeJson(from: Data(contentsOf: issuerProfileUrl))
                return parsedJson
            } catch {
                print("fetching issuer failed with error: \(error)")
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func fetchIssuer(issuerID: String) throws -> String? {
        var issuerProfileId : String = issuerID
        
        if (issuerID.isDid()) {
            let didDocumentLoaded : DidDocument = DidMethods.resolveDidDocument(didUri: issuerProfileId)!
            issuerProfileId = didDocumentLoaded.getIssuerProfileUrl()
        }
        
        if (issuerProfileId.count == 0) {
            throw CertificateParserError.missingData(description: "No issuer profile ID")
        }
        
        return issuerProfileId
    }
    
    static func fetchIssuerProfile(issuerProfileUrl: String) -> IssuerV2? {
        do {
            let issuerProfile : Data = try JsonLoader.loadJsonUrl(jsonUrl: issuerProfileUrl)!
            let res: IssuerV2 = try JSONDecoder().decode(IssuerV2.self,
                                                         from: issuerProfile)
            return res
        } catch let error {
            print("resolveDidDocument :: could not resolve Did Document : ", error)
            return nil
        }
    }
    
    static func parse(issuerJSON issuerJson: AnyObject) -> Issuer? {
        let issuerId: String = MethodsForV3.getIssuerId(issuerJSON: issuerJson)!
    
        // If issuer profile can be retrieved
        do {
            let issuerIdURLString = try MethodsForV3.fetchIssuer(issuerID: issuerId)
            let fetchedIssuerProfile = MethodsForV3.fetchIssuerProfile(issuerProfileUrl: issuerIdURLString!)!
            
            return IssuerV2(name: fetchedIssuerProfile.name,
                            email: fetchedIssuerProfile.email,
                            image: fetchedIssuerProfile.image,
                            id: URL(string: issuerIdURLString!)!,
                            url: fetchedIssuerProfile.url!,
                            publicKeys: [],
                            introductionMethod: .unknown,
                            analyticsURL: nil)
        } catch {
            // If issuer profile cannot be retrieved, we use the potential values in the Blockcerts document
            guard let issuerData = issuerJson as? [String : String],
                let issuerURLString = issuerData["url"],
                let issuerURL = URL(string: issuerURLString),
                let logoURI = issuerData["image"],
                let issuerEmail = issuerData["email"],
                let issuerName = issuerData["name"],
                let issuerIdURL = URL(string: issuerId) else {
                    return nil
            }
            
            let logo = imageData(from: logoURI)
            
            return IssuerV2(name: issuerName,
                            email: issuerEmail,
                            image: logo,
                            id: issuerIdURL,
                            url: issuerURL,
                            publicKeys: [],
                            introductionMethod: .unknown,
                            analyticsURL: nil)
        }
    }
    
    static func parse(recipientJSON json: [String : Any]) -> Recipient? {
        if let recipientData = json["credentialSubject"] as? [String : Any] {
            let publicKey = recipientData["publicKey"] as? BlockchainAddress
            let name : String = recipientData["name"] as? String ?? recipientData["id"] as! String
            
            return Recipient(name: name,
                             publicAddress: publicKey)
        }
        
        return nil
    }
    
    static func parse(metadataJSON: [String : Any]) -> Metadata? {
        if let metadataString = metadataJSON["metadata"] as? String {
            do {
                let data = metadataString.data(using: .utf8)
                let metadataJson : [String : Any] = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                return Metadata(json: metadataJson)
            } catch {
                print("Failed to parse metadata json:")
                print(metadataString)
            }
        }
        
        return nil
    }
    
    static func parse(assertionJSON: AnyObject?) -> Assertion? {
        guard let assertionData = assertionJSON as? [String : Any],
            let issuedOnString = assertionData["issuanceDate"] as? String,
            let issuedOnDate = issuedOnString.toDate(),
            let assertionID = assertionData["id"] as? String else {
                return nil
        }
        
        var assertionUID : String!
        let assertionIDURL = URL(string: assertionID)
        if assertionIDURL != nil {
            assertionUID = assertionID
        } else if let range = assertionID.range(of:Constants.guidRegexp, options: .regularExpression) {
            assertionUID = String(assertionID[range])
        }
        
        guard assertionUID != nil else {
            return nil
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
                         uid: assertionUID,
                         id: assertionIDURL,
                         metadata: Metadata(json: metadataJson),
                         htmlDisplay: htmlDisplay)
    }
    
    static func parse(verifyJSON: [String: AnyObject?]) -> Verify? {
        guard let type : Array<String> = verifyJSON["type"] as! Array<String>? else {
            return nil
        }

        var address : BlockchainAddress? = nil
        if let publicKey = verifyJSON["publicKey"] as? String {
            address = BlockchainAddress(string: publicKey)
        }

        return Verify(signer: nil, publicKey: address, signedAttribute: nil, type: type[0])
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
    
    static func parse(displayJSON json: AnyObject?) -> String? {
        guard let displayJsonData = json as? [String : String],
              let contentMediaType = displayJsonData["contentMediaType"],
              let content = displayJsonData["content"] else {
            return "No readable content"
        }
        
        var contentEncoding : String = ""
        if let _contentEncoding = displayJsonData["contentEncoding"] {
            contentEncoding = "\(_contentEncoding),"
        }
        
        let rawContentMediaType = ContentMediaType(rawValue: contentMediaType)
        
        switch rawContentMediaType {
        case .textHtml:
            return content
        case .imagePng, .imageJpeg, .imageGif, .imageBmp:
            
            return "<img src=\"data:\(contentMediaType);\(contentEncoding)\(content)\"/>"
        case .applicationPdf:
            return "<embed width=\"100%\" height=\"100%\" type=\"application/pdf\" src=\"data:\(contentMediaType);\(contentEncoding)\(content)\"/>"
        default:
            return "No readable content"
        }
    }
}
