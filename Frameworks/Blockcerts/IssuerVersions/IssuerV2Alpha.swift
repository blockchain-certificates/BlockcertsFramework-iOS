//
//  IssuerV2Alpha.swift
//  cert-wallet
//
//  Created by Chris Downie on 7/31/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation


public struct IssuerV2Alpha : Issuer, AnalyticsSupport, ServerBasedRevocationSupport, Codable {
    public let version = IssuerVersion.twoAlpha
    public let name : String
    public let id : URL
    public let url : URL
    public let introductionMethod : IssuerIntroductionMethod
    public var publicKeys: [KeyRotation] {
        return issuerKeys.map { $0.toKeyRotation() }
    }
    
    // MARK: Optional Properties
    public let email : String?
    public let image : Data?
    public let revocationURL : URL?
    public let analyticsURL: URL?
    private let issuerKeys : [KeyRotationV2a]
    
    private enum CodingKeys : String, CodingKey {
        case name, email, image, id, url
        case issuerKeys = "publicKeys"
        
        case revocationURL = "revocationList"
        case analyticsURL
        
        case introductionAuthenticationMethod
        case introductionURL
        case introductionSuccessURL
        case introductionErrorURL
    }
    
    private struct KeyRotationV2a : Codable {
        let publicKey : BlockchainAddress
        let created : Date
        let expires : Date?
        let revoked : Date?
        
        private enum CodingKeys : CodingKey {
            case publicKey, created, expires, revoked
        }
        
        init(from keyRotation: KeyRotation) {
            created = keyRotation.on
            publicKey = keyRotation.key
            expires = keyRotation.expires
            revoked = keyRotation.revoked
        }
        
        public func toKeyRotation() -> KeyRotation {
            return KeyRotation(on: created, key: publicKey, revoked: revoked, expires: expires)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            publicKey = try container.decode(BlockchainAddress.self, forKey: .publicKey)
            let createdString = try container.decode(String.self, forKey: .created)
            if let date = createdString.toDate() {
                created = date
            } else {
                throw IssuerError.invalid(property: "publicKeys..created")
            }
            
            let expiresString = try container.decodeIfPresent(String.self, forKey: .expires)
            expires = expiresString?.toDate()
            let revokedString = try container.decodeIfPresent(String.self, forKey: .revoked)
            revoked = revokedString?.toDate()
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(publicKey, forKey: .publicKey)
            try container.encode(created.toString(), forKey: .created)
            try container.encodeIfPresent(expires?.toString(), forKey: .expires)
            try container.encodeIfPresent(revoked?.toString(), forKey: .revoked)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        id = try container.decode(URL.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        issuerKeys = try container.decode(Array.self, forKey: .issuerKeys)
        let imageURL = try container.decode(URL.self, forKey: .image)
        image = try Data(contentsOf: imageURL)
        
        revocationURL = try container.decodeIfPresent(URL.self, forKey: .revocationURL)
        analyticsURL = try container.decodeIfPresent(URL.self, forKey: .analyticsURL)
        
        introductionMethod = try IssuerIntroductionMethod.methodFrom(name: try container.decodeIfPresent(String.self, forKey: .introductionAuthenticationMethod),
                                                                     introductionURL: try container.decodeIfPresent(URL.self, forKey: .introductionURL),
                                                                     successURL: try container.decodeIfPresent(URL.self, forKey: .introductionSuccessURL),
                                                                     errorURL: try container.decodeIfPresent(URL.self, forKey: .introductionErrorURL))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(issuerKeys, forKey: .issuerKeys)
        
        if let issuerImage = image?.base64EncodedString() {
            try container.encode("data:image/png;base64,\(issuerImage)", forKey: .image)
        }
        
        try container.encodeIfPresent(revocationURL, forKey: .revocationURL)
        try container.encodeIfPresent(analyticsURL, forKey: .analyticsURL)
        
        switch introductionMethod {
        case .basic(let introductionURL):
            try container.encode("basic", forKey: .introductionAuthenticationMethod)
            try container.encode(introductionURL, forKey: .introductionURL)
        case .webAuthentication(let introductionURL, let successURL, let errorURL):
            try container.encode("web", forKey: .introductionAuthenticationMethod)
            try container.encode(introductionURL, forKey: .introductionURL)
            try container.encode(successURL, forKey: .introductionSuccessURL)
            try container.encode(errorURL, forKey: .introductionErrorURL)
        case .unknown:
            fallthrough
        default:
            break;
        }
    }
    
    /// Create an issuer from a complete set of data.
    ///
    /// - parameter name:                 The issuer's name
    /// - parameter email:                The issuer's email.
    /// - parameter image:                A data object for the issuer's image.
    /// - parameter id:                   The refresh URL for the issuer. Also a unique identifier.
    /// - parameter url:                  URL to list all certificates issued by identifier
    /// - parameter publicKeys:           An array of KeyRotation objects used to issue certificates.
    /// - parameter introductionMethod:   How the recipient should be introduced to the issuer.
    ///
    /// - returns: An initialized Issuer object.
    public init(name: String,
                email: String,
                image: Data,
                id: URL,
                url: URL,
                revocationURL: URL? = nil,
                publicKeys: [KeyRotation],
                introductionMethod: IssuerIntroductionMethod,
                analyticsURL: URL?) {
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        self.revocationURL = revocationURL
        issuerKeys = publicKeys.sorted(by: <).map { KeyRotationV2a(from: $0) }
        self.introductionMethod = introductionMethod
        self.analyticsURL = analyticsURL
    }
    
    
    /// Create an issuer from a dictionary of data. Typically used when reading from disk or from a network response
    /// This is the inverse of `toDictionary`
    ///
    /// - parameter dictionary: A set of key-value pairs with data used to create the Issuer object
    /// - parameter version: Version hint for parsing
    public init(dictionary: [String: Any], asVersion strictVersion: IssuerVersion? = nil) throws {
        // Required properties first
        guard let name = dictionary["name"] as? String else {
            throw IssuerError.missing(property: "name")
        }
        guard let email = dictionary["email"] as? String else {
            throw IssuerError.missing(property: "email")
        }
        guard let imageString = dictionary["image"] as? String else {
            throw IssuerError.missing(property: "image")
        }
        guard let imageURL = URL(string: imageString),
            let image = try? Data(contentsOf: imageURL) else {
                throw IssuerError.invalid(property: "image")
        }
        guard let idString = dictionary["id"] as? String else {
            throw IssuerError.invalid(property: "id")
        }
        guard let id = URL(string: idString) else {
            throw IssuerError.invalid(property: "id")
        }
        guard let urlString = dictionary["url"] as? String else {
            throw IssuerError.missing(property: "url")
        }
        guard let url = URL(string: urlString) else {
            throw IssuerError.invalid(property: "url")
        }
        
        let parsedIssuerKeys = try parseKeys(from: dictionary, with: "publicKeys", converter: keyRotationScheduleV2Alpha)
        issuerKeys = parsedIssuerKeys.sorted(by: <).map { KeyRotationV2a(from: $0) }
        
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        if let analyticsString = dictionary["analyticsURL"] as? String,
            let analyticsURL = URL(string:analyticsString) {
            self.analyticsURL = analyticsURL
        } else {
            analyticsURL = nil
        }
        
        // Restore the introduction method.
        let introductionMethod = dictionary["introductionAuthenticationMethod"] as? String
        let introductionStringURL = dictionary["introductionURL"] as? String
        
        if let introductionMethod = introductionMethod {
            switch introductionMethod {
            case "none":
                fallthrough
            case "basic":
                if let introductionStringURL = introductionStringURL,
                    let introductionURL = URL(string: introductionStringURL) {
                    self.introductionMethod = .basic(introductionURL: introductionURL)
                } else {
                    self.introductionMethod = .unknown
                }
            case "web":
                if let introductionStringURL = introductionStringURL,
                    let introductionURL = URL(string: introductionStringURL),
                    let successStringURL = dictionary["introductionSuccessURL"] as? String,
                    var successURL = URL(string: successStringURL),
                    let errorStringURL = dictionary["introductionErrorURL"] as? String,
                    var errorURL = URL(string: errorStringURL) {
                    
                    // Remove any query string parameters from the success & error urls
                    if var successComponents = URLComponents(url: successURL, resolvingAgainstBaseURL: false) {
                        successComponents.queryItems = nil
                        successURL = successComponents.url ?? successURL
                    }
                    
                    if var errorComponents = URLComponents(url: errorURL, resolvingAgainstBaseURL: false) {
                        errorComponents.queryItems = nil
                        errorURL = errorComponents.url ?? errorURL
                    }
                    
                    self.introductionMethod = .webAuthentication(introductionURL: introductionURL, successURL: successURL, errorURL: errorURL)
                } else {
                    self.introductionMethod = .unknown
                }
            case "unknown":
                fallthrough
            default:
                self.introductionMethod = .unknown
            }
        } else if let introductionStringURL = introductionStringURL,
            let introductionURL = URL(string: introductionStringURL) {
            self.introductionMethod = .basic(introductionURL: introductionURL)
        } else {
            self.introductionMethod = .unknown
        }
        
        // Optional: restore the revocation data
        if let revocationString = dictionary["revocationList"] as? String,
            let revocationURL = URL(string: revocationString) {
            self.revocationURL = revocationURL
        } else {
            self.revocationURL = nil
        }
    }
    
    
    /// Convert this Issuer structure into a dictionary format.
    ///
    /// - returns: The dictionary representing this Issuer.
    public func toDictionary() -> [String: Any] {
        let serializedIssuerKeys = publicKeys.map { (keyRotation) -> [String : String] in
            return [
                "date": keyRotation.on.toString(),
                "key": keyRotation.key.scopedValue
            ]
        }

        var issuerImageBase64 = ""
        if let issuerImage = image?.base64EncodedString() {
            issuerImageBase64 = "data:image/png;base64,\(issuerImage)"
        }
        
        var dictionary : [String: Any] = [
            "name": name,
            "email": email,
            "image": issuerImageBase64,
            "id": "\(id)",
            "url": "\(url)",
            "issuerKeys": serializedIssuerKeys,
        ]
        
        switch introductionMethod {
        case .basic(let introductionURL):
            dictionary["introductionAuthenticationMethod"] = "basic"
            dictionary["introductionURL"] = "\(introductionURL)"
        case .webAuthentication(let introductionURL, let successURL, let errorURL):
            dictionary["introductionAuthenticationMethod"] = "web"
            dictionary["introductionURL"] = "\(introductionURL)"
            dictionary["introductionSuccessURL"] = "\(successURL)"
            dictionary["introductionErrorURL"] = "\(errorURL)"
        case .unknown:
            dictionary["introductionAuthenticationMethod"] = "unknown"
        }
        
        if let url = analyticsURL {
            dictionary["analyticsURL"] = url
        }
        
        return dictionary
    }
}

// MARK: - Equatable & Comparable conformance
extension IssuerV2Alpha : Equatable {
    public static func ==(lhs: IssuerV2Alpha, rhs: IssuerV2Alpha) -> Bool {
        return lhs.name == rhs.name
            && lhs.email == rhs.email
            && lhs.image == rhs.image
            && lhs.id == rhs.id
            && lhs.url == rhs.url
            && lhs.publicKeys == rhs.publicKeys
            && lhs.introductionMethod == rhs.introductionMethod
    }
}

fileprivate func keyRotationScheduleV2Alpha(from dictionary: [String : String]) throws -> KeyRotation {
    guard let dateString = dictionary["created"] else {
        throw IssuerError.missing(property: "created")
    }
    
    guard let key : String = dictionary["publicKey"] else {
        throw IssuerError.missing(property: "publicKey")
    }
    let publicKey = BlockchainAddress(string: key)
    
    guard let date = dateString.toDate() else {
        throw IssuerError.invalid(property: "created")
    }
    
    var expires : Date? = nil
    var revoked : Date? = nil
    
    if let expiresString = dictionary["expires"] {
        expires = expiresString.toDate()
    }
    if let revokedString = dictionary["revoked"] {
        revoked = revokedString.toDate()
    }
    
    return KeyRotation(on: date, key: publicKey, revoked: revoked, expires: expires)
}

