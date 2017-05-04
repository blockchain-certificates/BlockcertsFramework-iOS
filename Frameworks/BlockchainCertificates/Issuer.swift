//
//  Issuer.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// Signifies when a new key was rotated in for a given purpose.
public struct KeyRotation {
    /// This is when the key was published. As long as no other KeyRotation is observed after this date, it can be safely assumed that this key is valid and in use
    /// In V2 this is an alias for 'created'
    public let on : Date
    /// A base64-encoded string representing the data of the key.
    public let key : String
    
    public let revoked : Date?
    public let expires : Date?
    
    public init(on: Date, key: String, revoked: Date? = nil, expires: Date? = nil) {
        self.on = on
        self.key = key
        self.revoked = revoked
        self.expires = expires
    }
}

/// Issuer version. Used for parsing; data model is the same
/// - one: This is a v1 issuer
/// - two: This is a v2 issuer
public enum IssuerVersion : Int {
    // Note, these should always be listed in increasing issuer version order
    case one = 1
    case two
}

public enum IssuerError : Error {
    case missing(property: String)
    case invalid(property: String)
}

public struct Issuer {
    // MARK: - Properties
    // MARK: Required properties
    /// The name of the issuer.
    public let name : String
    
    /// The email address where you can contact the issuer
    public let email : String
    
    /// Image data for the issuer. This can be used to populate a UIImage object
    public let image : Data
    
    /// Unique identifier for an Issuer. Also, the URL where you can re-request data. This is useful if an instance of this struct only has partial data, or if you want to see that the keys are still valid.
    public let id : URL
    
    /// Where you can go to check a list of certificates issued by this issuer.
    public let url : URL
    
    // MARK: Optional Properties
    /// An ordered list of KeyRotation objects, with the most recent key rotation first. These represent the keys used to issue certificates during specific date ranges
    public let issuerKeys : [KeyRotation]
    
    /// An ordered list of KeyRotation objects, with the most recent key rotation first. These represent the keys used to revoke certificates.
    public let revocationKeys : [KeyRotation]
    
    /// The URL where you can make a POST request with recipient data in order to introduce a Recipient to an Issuer. For more information, look at `IssuerIntroductionRequest`
    public let introductionURL : URL?
    
    /// v2+ only; url where revocation list is located
    public let revocationURL : URL?
    
    // MARK: Convenience Properties
    /// A convenience method for the most recent (and theoretically only valid) issuerKey.
    public var publicKey : String? {
        return issuerKeys.first?.key
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
                url: URL,
                revocationURL: URL? = nil) {
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        self.revocationURL = revocationURL
        
        issuerKeys = []
        revocationKeys = []
        introductionURL = nil
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
        self.revocationURL = revocationURL
        issuerKeys = publicIssuerKeys.sorted(by: <)
        revocationKeys = publicRevocationKeys.sorted(by: <)
        self.introductionURL = introductionURL
    }
    
    /// Create an issuer from a dictionary of data. Typically used when reading from disk or from a network response
    /// This is the inverse of `toDictionary`
    ///
    /// - parameter dictionary: A set of key-value pairs with data used to create the Issuer object
    /// - parameter version: Version hint for parsing
    public init(dictionary: [String: Any], asVersion version: IssuerVersion = .one) throws {
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
        
        if version == IssuerVersion.one {
            let parsedIssuerKeys = try parseKeys(from: dictionary, with: "issuerKeys", converter: keyRotationSchedule)
            let parsedRevocationKeys = try parseKeys(from: dictionary, with: "revocationKeys", converter: keyRotationSchedule)
            
            issuerKeys = parsedIssuerKeys.sorted(by: <)
            revocationKeys = parsedRevocationKeys.sorted(by: <)
        } else {
            let parsedIssuerKeys = try parseKeys(from: dictionary, with: "publicKeys", converter: keyRotationScheduleV2)
            issuerKeys = parsedIssuerKeys.sorted(by: <)
            revocationKeys = []
        }
        
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        // Optional Properties.
        if let introductionString = dictionary["introductionURL"] as? String,
            let introductionURL = URL(string: introductionString) {
            self.introductionURL = introductionURL
        } else {
            self.introductionURL = nil
        }
        
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
        let serializedIssuerKeys = issuerKeys.map { (keyRotation) -> [String : String] in
            return [
                "date": keyRotation.on.toString(),
                "key": keyRotation.key
            ]
        }
        let serializedRevocationKeys = revocationKeys.map { (keyRotation) -> [String : String] in
            return [
                "date": keyRotation.on.toString(),
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
        if let introductionURL = introductionURL {
            dictionary["introductionURL"] = "\(introductionURL)"
        }
        
        return dictionary
    }
}

// MARK: - Equatable & Comparable conformance
extension Issuer : Equatable {}

public func ==(lhs: Issuer, rhs: Issuer) -> Bool {
    return lhs.name == rhs.name
        && lhs.email == rhs.email
        && lhs.image == rhs.image
        && lhs.id == rhs.id
        && lhs.url == rhs.url
        && lhs.issuerKeys == rhs.issuerKeys
        && lhs.revocationKeys == rhs.revocationKeys
}

extension KeyRotation : Comparable {}

public func ==(lhs: KeyRotation, rhs: KeyRotation) -> Bool {
    return lhs.on == rhs.on && lhs.key == rhs.key
}

public func <(lhs: KeyRotation, rhs: KeyRotation) -> Bool {
    return lhs.on < rhs.on
}

func parseKeys(from dictionary: [String: Any], with keyName: String,
                 converter keyRotationFunction: ([String : String]) throws -> KeyRotation) throws -> [KeyRotation] {
    guard let keyProperty = dictionary[keyName] else {
        throw IssuerError.missing(property: keyName)
    }
    guard let keyData = keyProperty as? [[String: String]] else {
        throw IssuerError.invalid(property: keyName)
    }
    
    let parsedKeys = try keyData.enumerated().map { (index: Int, dictionary: [String : String]) throws -> KeyRotation in
        do {
            let rotation = try keyRotationSchedule(from: dictionary)
            return rotation
        } catch IssuerError.missing(let prop) {
            throw IssuerError.missing(property: ".\(keyName).\(index).\(prop)")
        } catch IssuerError.invalid(let prop) {
            throw IssuerError.invalid(property: ".\(keyName).\(index).\(prop)")
        }
    }
    
    return parsedKeys
}

func keyRotationSchedule(from dictionary: [String : String]) throws -> KeyRotation {
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


func keyRotationScheduleV2(from dictionary: [String : String]) throws -> KeyRotation {
    guard let dateString = dictionary["created"] else {
        throw IssuerError.missing(property: "created")
    }
    
    guard let key : String = dictionary["publicKey"] else {
        throw IssuerError.missing(property: "publicKey")
    }
    
    var publicKey = key
    if publicKey.hasPrefix("ecdsa-koblitz-pubkey:") {
        publicKey = key.substring(from: key.index(key.startIndex, offsetBy: 21))
    }
    
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
