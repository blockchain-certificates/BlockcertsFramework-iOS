//
//  IssuerV1.swift
//  cert-wallet
//
//  Created by Chris Downie on 7/31/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

public enum IssuerError : Error {
    case missing(property: String)
    case invalid(property: String)
    case unknownVersion
}

public struct KeyRotationV1 : Codable, Equatable {
    public let date : Date
    public let key : String
    
    private enum CodingKeys : CodingKey {
        case date, key
    }
    
    init(date: Date, key: String) {
        self.date = date
        self.key = key
    }
    
    init(from keyRotation: KeyRotation) {
        date = keyRotation.on
        key = keyRotation.key
    }
    
    public func toKeyRotation() -> KeyRotation {
        return KeyRotation(on: date, key: key)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try container.decode(String.self, forKey: .key)
        let dateString = try container.decode(String.self, forKey: .date)
        if let date = dateString.toDate() {
            self.date = date
        } else {
            throw IssuerError.invalid(property: "date")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(date.toString(), forKey: .date)
        try container.encode(key, forKey: .key)
    }

    public static func ==(lhs: KeyRotationV1, rhs: KeyRotationV1) -> Bool {
        return lhs.date == rhs.date
                && lhs.key == rhs.key
    }
}

public struct IssuerV1 : Issuer, Codable {
    public let version = IssuerVersion.one
    public let name : String
    public let email : String
    public let image : Data
    public let id : URL
    public let url : URL
    public var publicKeys: [KeyRotation] {
        return issuerKeys.map { $0.toKeyRotation() }
    }

    // MARK: Optional Properties
    /// An ordered list of KeyRotation objects, with the most recent key rotation first. These represent the keys used to issue certificates during specific date ranges
    public let issuerKeys : [KeyRotationV1]
    
    /// An ordered list of KeyRotation objects, with the most recent key rotation first. These represent the keys used to revoke certificates.
    public let revocationKeys : [KeyRotationV1]
    
    /// This defines how the recipient shoudl introduce to the issuer. It replaces `introductionURL`
    public let introductionMethod : IssuerIntroductionMethod

    private enum CodingKeys : CodingKey {
        case id
        case url
        case name
        case email
        case image
        case issuerKeys
        case revocationKeys
        
        case introductionAuthenticationMethod
        case introductionURL
        case introductionSuccessURL
        case introductionErrorURL
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        let imageURL = try container.decode(URL.self, forKey: .image)
        image = try Data(contentsOf: imageURL)
        id = try container.decode(URL.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        issuerKeys = try container.decode(Array.self, forKey: .issuerKeys)
        revocationKeys = try container.decode(Array.self, forKey: .revocationKeys)
        
        // TODO: We can make this into its own functions with @autoclosures for perf.
        
        // Parse out the introduction method. Yikes.
        introductionMethod = try IssuerIntroductionMethod.methodFrom(name: try container.decodeIfPresent(String.self, forKey: .introductionAuthenticationMethod),
                                                                     introductionURL: try container.decodeIfPresent(URL.self, forKey: .introductionURL),
                                                                     successURL: try container.decodeIfPresent(URL.self, forKey: .introductionSuccessURL),
                                                                     errorURL: try container.decodeIfPresent(URL.self, forKey: .introductionErrorURL))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode("data:image/png;base64,\(image.base64EncodedString())", forKey: .image)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(issuerKeys, forKey: .issuerKeys)
        try container.encode(revocationKeys, forKey: .revocationKeys)
        
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
    
    // MARK: - Initializers
    /// Create an Issuer from partial data. This is commonly done from data available in a certificate.
    /// Once this is created, you'll need to refresh it to get one with updated keys and an introduction URL. Without those, you will be unable to verify that this issuer *actually issued* certificates, or introduce new Recipients to that issuer.
    ///
    /// The parameter names happen to correspond to the property names of the Issuer struct.
    ///
    /// - parameter name:  The issuer's name
    /// - parameter email: The issuer's email.
    /// - parameter image: A data object for the issuer's image.
    /// - parameter id:    The refresh URL for the issuer. Also a unique identifier.
    /// - parameter url:   URL to list all certificates issued by identifier
    ///
    /// - returns: An initialized Issuer object.
    public init(name: String,
                email: String,
                image: Data,
                id: URL,
                url: URL) {
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        issuerKeys = []
        revocationKeys = []
        introductionMethod = .unknown
    }
    
    /// Create an issuer from a complete set of data.
    ///
    /// - parameter name:                 The issuer's name
    /// - parameter email:                The issuer's email.
    /// - parameter image:                A data object for the issuer's image.
    /// - parameter id:                   The refresh URL for the issuer. Also a unique identifier.
    /// - parameter url:                  URL to list all certificates issued by identifier
    /// - parameter publicIssuerKeys:     An array of KeyRotation objects used to issue certificates.
    /// - parameter publicRevocationKeys: An array of KeyRotation objects used to revoke certificates.
    /// - parameter introductionURL:      URL to introduce a recipient to this issuer.
    ///
    /// - returns: An initialized Issuer object.
    public init(name: String,
                email: String,
                image: Data,
                id: URL,
                url: URL,
                revocationURL: URL? = nil,
                publicIssuerKeys: [KeyRotation],
                publicRevocationKeys: [KeyRotation],
                introductionURL: URL) {
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        issuerKeys = publicIssuerKeys.sorted(by: <).map{ KeyRotationV1(from: $0) }
        revocationKeys = publicRevocationKeys.sorted(by: <).map{ KeyRotationV1(from: $0) }
        introductionMethod = .basic(introductionURL: introductionURL)
    }
    
    public init(name: String,
                email: String,
                image: Data,
                id: URL,
                url: URL,
                revocationURL: URL? = nil,
                publicIssuerKeys: [KeyRotation],
                publicRevocationKeys: [KeyRotation],
                introductionMethod: IssuerIntroductionMethod) {
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        issuerKeys = publicIssuerKeys.sorted(by: <).map { KeyRotationV1(from : $0) }
        revocationKeys = publicRevocationKeys.sorted(by: <).map { KeyRotationV1(from : $0) }
        self.introductionMethod = introductionMethod
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
        
        let parsedIssuerKeys = try parseKeys(from: dictionary, with: "issuerKeys", converter: keyRotationSchedule)
        let parsedRevocationKeys = try parseKeys(from: dictionary, with: "revocationKeys", converter: keyRotationSchedule)
        
        issuerKeys = parsedIssuerKeys.sorted(by: <).map { KeyRotationV1(from : $0) }
        revocationKeys = parsedRevocationKeys.sorted(by: <).map { KeyRotationV1(from : $0) }
        
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        // Restore the introduction method.
        do {
            introductionMethod = try IssuerIntroductionMethod.methodFrom(name: dictionary["introductionAuthenticationMethod"] as? String,
                                                                         introductionURL: dictionary["introductionURL"] as? String,
                                                                         successURL: dictionary["introductionSuccessURL"] as? String,
                                                                         errorURL: dictionary["introductionErrorURL"] as? String)
        } catch  {
            introductionMethod = .unknown
        }
    }
    
    
    /// Convert this Issuer structure into a dictionary format.
    ///
    /// - returns: The dictionary representing this Issuer.
    public func toDictionary() -> [String: Any] {
        let serializedIssuerKeys = issuerKeys.map { (keyRotation) -> [String : String] in
            return [
                "date": keyRotation.date.toString(),
                "key": keyRotation.key
            ]
        }
        let serializedRevocationKeys = revocationKeys.map { (keyRotation) -> [String : String] in
            return [
                "date": keyRotation.date.toString(),
                "key": keyRotation.key
            ]
        }
        
        var dictionary : [String: Any] = [
            "name": name,
            "email": email,
            "image": "data:image/png;base64,\(image.base64EncodedString())",
            "id": "\(id)",
            "url": "\(url)",
            "issuerKeys": serializedIssuerKeys,
            "revocationKeys": serializedRevocationKeys
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

        return dictionary
    }
}

// MARK: - Equatable & Comparable conformance
extension IssuerV1 : Equatable {
//    public static func ==(lhs: Issuer, rhs: IssuerV1) -> Bool {
//        // Switch the order of the arguments
//        return rhs == lhs
//    }
//    
//    public static func ==(lhs: IssuerV1, rhs: Issuer) -> Bool {
//        guard let rhsIssuerV1 = rhs as? IssuerV1 else {
//            return false
//        }
//        return lhs == rhsIssuerV1
//    }
    public static func ==(lhs: IssuerV1, rhs: IssuerV1) -> Bool {
        return lhs.name == rhs.name
            && lhs.email == rhs.email
            && lhs.image == rhs.image
            && lhs.id == rhs.id
            && lhs.url == rhs.url
            && lhs.issuerKeys == rhs.issuerKeys
            && lhs.revocationKeys == rhs.revocationKeys
            && lhs.introductionMethod == rhs.introductionMethod
    }
}

fileprivate func keyRotationSchedule(from dictionary: [String : String]) throws -> KeyRotation {
    guard let dateString = dictionary["date"] else {
        throw IssuerError.missing(property: "date")
    }
    guard let key = dictionary["key"] else {
        throw IssuerError.missing(property: "key")
    }
    guard let date = dateString.toDate() else {
        throw IssuerError.invalid(property: "date")
    }
    
    return KeyRotation(on: date, key: key)
}



