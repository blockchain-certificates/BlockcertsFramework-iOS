//
//  Certificate.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// These are versionf of the CertificateFormat that the CertificateParser understands. It will also be prsent on the resulting Certificate object
///
/// - oneDotOne: This is a v1.1 certificate
/// - oneDotTwo: This is a v1.2 certificate
public enum CertificateVersion {
    case oneDotOne
    case oneDotTwo
}

/// These are the errors that can be thrown during parsing:
///
/// - notImplemented:
/// - genericError:
/// - notValidJSON:
/// - notSigned:      The format appears to be an unsigned certificate. This version of the parser doesn't recognize unsigned certificates.
/// <#Description#>
///
/// - notImplemented:      This particular version of the parser hasn't been implemented. It's possible you're using the protocol directly rather than a concrete subclass.
/// - genericError:        Something has gone wrong and I don't know exactly what
///
/// - notValidJSON:        We were expecting JSON data, but it didn't pass deserialization
/// - notSigned:           This certificate isn't signed, and this certificate format version only validates signed certificates.
/// - jsonLDError:         Problem in conforming to JSON LD format. http://json-ld.org
/// - missingData:         A particular property was missing in the JSON data.
/// - invalidData:         A property's value is invalid. For instance, a normal string when a URL should be present.
public enum CertificateParserError : Error {
    case notImplemented
    case genericError
    case notValidJSON
    case notSigned
    case jsonLDError(description: String)
    case missingData(description: String)
    case invalidData(description: String)
}

/// CertificateParser should never be instantiated. Call one of its `parse` methods to turn a Data object into a Certificate.
public enum CertificateParser {
    /// This is the most general parse function. Pass it a data object representing the certificate, and it will
    /// auto-detect which version of the Certificate format to use. It will always use the latest version that
    /// passes a valid parse
    ///
    /// - parameter data: A Data-representation of the Certificate. Usually, this is a JSON object.
    ///
    /// - returns: A certificate if the provided data passes any known version of the Certificate format. Nil otherwise.
    public static func parse(data: Data) throws -> Certificate {
        return try CertificateParser.parse(data: data, withMinimumVersion: .oneDotOne)
    }
    
    /// This parses a data object as a specific version of the certificate format. Useful if you're expecting a 1.2
    /// certificate, and you'd like the parse to fail if it only finds a v1.1 certificate
    ///
    /// - parameter data:    A Data-representation of the Certificate. Usually, this is a JSON object
    /// - parameter version: Which version to parse the `data` parameter as.
    ///
    /// - returns: A Certificate if `data` is a valid Certificate at the specified version. Nil otherwise.
    public static func parse(data: Data, asVersion version: CertificateVersion) throws -> Certificate {
        switch version {
        case .oneDotTwo:
            return try CertificateV1_2(data: data)
        case .oneDotOne:
            return try CertificateV1_1(data: data)
        }
    }
    
    /// Parses a data object with a minimum certificate version. This is the most future-compatible parse. If you
    /// want to rely on features introduced in a specific version fo the Certificate format, this is the best way
    /// to do that.
    ///
    /// - parameter data:    A Data-representation of the Certificate. Usually, this is a JSON object
    /// - parameter version: The minimum version to parse `data` parameter as.
    ///
    /// - returns: A Certificate if `data` is a valid Certificate at the specified version or later. Nil otherwise.
    static func parse(data: Data, withMinimumVersion version: CertificateVersion) throws -> Certificate {
        var cert : Certificate?
        var lastError : Error?
        switch version {
        case .oneDotOne:
            if cert == nil {
                do {
                    cert = try CertificateV1_1(data: data)
                } catch {
                    cert = nil
                    lastError = error
                }
            }
            fallthrough
        case .oneDotTwo:
            if cert == nil {
                do {
                    cert = try CertificateV1_2(data: data)
                } catch {
                    cert = nil
                    lastError = error
                }
            }
        }
        
        if cert != nil {
            return cert!
        } else if lastError != nil {
            throw lastError!
        } else {
            throw CertificateParserError.genericError
        }
    }
}

// MARK: - Certificate Protocol definition
//
/// An abstract definition of a Certificate. Private concrete subclasses will conform to this protocol.
public protocol Certificate {
    /// Which version of the Certificate format this was parsed as.
    var version : CertificateVersion { get }
    
    
    /// Title of the certificate
    var title : String { get }
    
    /// Subtitle of the certificate. May be nil.
    var subtitle : String? { get }
    
    /// Description of what the certificate represents or certifies.
    var description: String { get }
    
    /// A base64-encoded png image of the issuer's logo. This is featured prominently in the display of the certifiate.
    var image : Data { get }
    
    /// Represents the IETF language and IETF country codes.
    var language : String { get }
    
    /// Link to a JSON that details the issuer's issuing and recovation keys.
    var id : URL { get }
    
    /// The raw, unedited file representation of the certificate.
    var file : Data { get }
    
    /// String of signature created when the Bitcoin private key signs the value in the attribute-signed field.
    var signature : String? { get }

    
    /// Represents the entity that issued this certifiate. See `Issuer` for more details
    var issuer : Issuer { get }
    
    /// Represents the entity this certificate was issued to. See `Recipient` for more details
    var recipient : Recipient { get }
    
    /// Represents the assertion made by this certificate. See `Assertion` for more details
    var assertion : Assertion { get }
    
    /// Represents data needed to verify this certificate. See `Verify` for more details
    var verifyData : Verify { get }
    
    /// Represents any reciept data to help verify the certificate. See `Reciept` for more details
    var receipt : Receipt? { get }
}

//
// MARK: - Private Implementation Details
//
// Below here, everything is private. This includes:
// * The concrete types for different versions of Certificate
// * Any version-specific or version-agnostic helper functions

private extension Certificate {
    init(data: Data) throws {
        throw CertificateParserError.notImplemented
    }
}

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
        id = certificateIdUrl

        
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
        self.signature = json["signature"] as? String
    }
}

// MARK: Certificate Version 1.2
private enum MethodsForV1_2 {
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
    static func parse(assertionJSON: AnyObject?) -> Assertion? {        // TODO: the json schema allowed datetime, which inclues yyyy-MM-dd and TBD others. How can we make date formatter
        // accept multiple string formats?
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd"
        
        guard let assertionData = assertionJSON as? [String : Any],
            let issuedOnString = assertionData["issuedOn"] as? String,
            let assertionID = assertionData["id"] as? String,
            let assertionIDURL = URL(string: assertionID),
            let assertionUID = assertionData["uid"] as? String else {
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

        return Assertion(issuedOn: issuedOnDate!,
                         signatureImages: signatureImages,
                         evidence: evidence,
                         uid: assertionUID,
                         id: assertionIDURL)
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
        guard let certificateIdString = certificateData["id"] as? String else {
            throw CertificateParserError.missingData(description: "Missing certificate's id property.")
        }
        guard let description = certificateData["description"] as? String else {
            throw CertificateParserError.missingData(description: "Missing certificate's description property.")
        }
        guard let certificateIdUrl = URL(string: certificateIdString) else {
            throw CertificateParserError.invalidData(description: "Certificate ID should be a valid URL.")
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
                throw CertificateParserError.genericError
        }
        self.issuer = issuer
        self.recipient = recipient
        self.assertion = assertion
        self.verifyData = verifyData
        self.receipt = receiptData
        self.signature = documentData["signature"] as? String
    }
}

