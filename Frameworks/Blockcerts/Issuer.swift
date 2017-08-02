//
//  Issuer.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation


/// Basic protocol, common to all Issuers
public protocol Issuer {
    /// What Issuer data version this issuer is using.
    var version : IssuerVersion { get }

    /// The name of the issuer.
    var name : String { get }
    
    /// The email address where you can contact the issuer
    var email : String { get }
    
    /// Image data for the issuer. This can be used to populate a UIImage object
    var image : Data { get }
    
    /// Unique identifier for an Issuer. Also, the URL where you can re-request data. This is useful if an instance of this struct only has partial data, or if you want to see that the keys are still valid.
    var id : URL { get }
    
    /// This defines how the recipient shoudl introduce to the issuer.
    var introductionMethod : IssuerIntroductionMethod { get }
    
    /// This shows all the public keys the issuer used to sign any certificates.
    var publicKeys: [KeyRotation] { get }
    
    // This will be deprecated come Swift 4
    func toDictionary() -> [String: Any]
}

public protocol AnalyticsSupport {
    var analyticsURL: URL? { get }
}

public protocol ServerBasedRevocationSupport {
    var revocationURL : URL? { get }
}

public typealias IssuerWithAnalytics = Issuer & AnalyticsSupport
public typealias IssuerWithRevocation = Issuer & ServerBasedRevocationSupport


public enum IssuerParser {
    public static func parse(dictionary: [String: Any]) -> Issuer? {
        guard let version = IssuerParser.detectVersion(from: dictionary) else {
            return nil
        }
        
        var issuer : Issuer? = nil
        
        switch version {
        case .two:
            issuer = try? IssuerV2(dictionary: dictionary)
        case .twoAlpha:
            issuer = try? IssuerV2Alpha(dictionary: dictionary)
        case .one:
            issuer = try? IssuerV1(dictionary: dictionary)
        }

        return issuer
    }
    
    public static func parse(dictionary: [String: Any], asVersion version: IssuerVersion) throws -> Issuer {
        switch version {
        case .one:
            return try IssuerV1(dictionary: dictionary)
        case .twoAlpha:
            return try IssuerV2Alpha(dictionary: dictionary)
        case .two:
            return try IssuerV2(dictionary: dictionary)
        }
    }
    
    public static func detectVersion(from dictionary: [String: Any]) -> IssuerVersion? {
        if dictionary["issuerKeys"] != nil {
            return .one
        } else if dictionary["publicKey"] != nil {
            return .two
        } else if dictionary["publicKeys"] != nil {
            return .twoAlpha
        }
        return nil
    }
}

/// Issuer version. Used for parsing; data model is the same
/// - one: This is a v1 issuer
/// - twoAlpha: This is a pre-relase v2 issuer
/// - two: This is a v2 issuer
public enum IssuerVersion : Int {
    // Note, these should always be listed in increasing issuer version order
    case one = 1
    case twoAlpha
    case two
}

public enum IssuerIntroductionMethod : Equatable {
    case unknown
    case basic(introductionURL: URL)
    case webAuthentication(introductionURL: URL, successURL: URL, errorURL: URL)
    
    public static func ==(lhs: IssuerIntroductionMethod, rhs: IssuerIntroductionMethod) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.basic(let leftURL), .basic(let rightURL)):
            return leftURL == rightURL
        case (.webAuthentication(let leftIntroURL, let leftSuccessURL, let leftErrorURL), .webAuthentication(let rightIntroURL, let rightSuccessURL, let rightErrorURL)):
            return leftIntroURL == rightIntroURL && leftSuccessURL == rightSuccessURL && leftErrorURL == rightErrorURL
        default:
            return false
        }
    }
}


/// Signifies when a new key was rotated in for a given purpose.
public struct KeyRotation : Comparable {
    /// This is when the key was published. As long as no other KeyRotation is observed after this date, it can be safely assumed that this key is valid and in use
    public let on : Date
    /// A base64-encoded string representing the data of the key.
    public let key : String
    
    /// When this certificate was revoked
    public let revoked : Date?
    
    /// WHen this certificate expires on its own, unless it is revoked before
    public let expires : Date?
    
    public init(on: Date, key: String, revoked: Date? = nil, expires: Date? = nil) {
        self.on = on
        self.key = key
        self.revoked = revoked
        self.expires = expires
    }
    
    public static func ==(lhs: KeyRotation, rhs: KeyRotation) -> Bool {
        return lhs.on == rhs.on && lhs.key == rhs.key
    }
    
    public static func <(lhs: KeyRotation, rhs: KeyRotation) -> Bool {
        return lhs.on < rhs.on
    }
}



// MARK - Helper functions
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
            let rotation = try keyRotationFunction(dictionary)
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


func keyRotationScheduleV2Alpha(from dictionary: [String : String]) throws -> KeyRotation {
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

func keyRotationScheduleV2(from dictionary: [String : String]) throws -> KeyRotation {
    guard let dateString = dictionary["created"] else {
        throw IssuerError.missing(property: "created")
    }
    
    guard let key : String = dictionary["id"] else {
        throw IssuerError.missing(property: "id")
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
