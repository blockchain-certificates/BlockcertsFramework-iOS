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
        var issuer : Issuer? = try? IssuerV2(dictionary: dictionary)
        
        if issuer == nil {
            issuer = try? IssuerV2Alpha(dictionary: dictionary)
        }
        if issuer == nil {
            issuer = try? IssuerV1(dictionary: dictionary)
        }
        if issuer == nil {
            issuer = try? PartialIssuer(dictionary: dictionary)
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
        case .embedded:
            return try PartialIssuer(dictionary: dictionary)
        }
    }

    public static func decode<Key>(from container: KeyedDecodingContainer<Key>, forKey key: Key) throws -> Issuer {
        //
        // Attempt to decode with the latest Issuer format, then go back in history until V1.
        //
        do {
            let issuer = try container.decode(IssuerV2.self, forKey: key)
            return issuer
        } catch { }
        
        do {
            let issuer = try container.decode(IssuerV2Alpha.self, forKey: key)
            return issuer
        } catch { }
        
        do {
            let issuer = try container.decode(IssuerV1.self, forKey: key)
            return issuer
        } catch { }
        
        let issuer = try container.decode(PartialIssuer.self, forKey: key)
        return issuer
    }
    
    public static func decodeIfPresent<Key>(from container: KeyedDecodingContainer<Key>, forKey key: Key) throws -> Issuer? {
        //
        // Attempt to decode with the latest Issuer format, then go back in history until V1.
        //
        do {
            let issuer = try container.decodeIfPresent(IssuerV2.self, forKey: key)
            return issuer
        } catch { }
        
        do {
            let issuer = try container.decodeIfPresent(IssuerV2Alpha.self, forKey: key)
            return issuer
        } catch { }
        
        do {
            let issuer = try container.decodeIfPresent(IssuerV1.self, forKey: key)
            return issuer
        } catch { }
        
        let issuer = try container.decodeIfPresent(PartialIssuer.self, forKey: key)
        
        return issuer
    }
    
    public static func encode<Key>(_ value: Issuer, to container: inout KeyedEncodingContainer<Key>, forKey key: Key) throws {
        switch value.version {
        case .two:
            try container.encode(value as! IssuerV2, forKey: key)
        case .twoAlpha:
            try container.encode(value as! IssuerV2Alpha, forKey: key)
        case .one:
            try container.encode(value as! IssuerV1, forKey: key)
        case .embedded:
            try container.encode(value as! PartialIssuer, forKey: key)
        }
    }
    
    public static func encodeIfPresent<Key>(_ value: Issuer?, to container: inout KeyedEncodingContainer<Key>, forKey key: Key) throws {
        guard let issuer = value else {
            return
        }
        try IssuerParser.encode(issuer, to: &container, forKey: key)
    }
}

/// Issuer version. Used for parsing; data model is the same
/// - one: This is a v1 issuer
/// - twoAlpha: This is a pre-relase v2 issuer
/// - two: This is a v2 issuer
public enum IssuerVersion : Int {
    case embedded
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
    
    
    public static func methodFrom(name: String?,
                                  introductionURL introURLString: String?,
                                  successURL successURLString: String?,
                                  errorURL errorURLString: String?) throws -> IssuerIntroductionMethod {
        var introURL : URL?
        if introURLString != nil {
            introURL = URL(string: introURLString!)
        }
        
        var successURL : URL?
        if successURLString != nil {
            successURL = URL(string: successURLString!)
        }
        
        var errorURL : URL?
        if errorURLString != nil {
            errorURL = URL(string : errorURLString!)
        }

        return try IssuerIntroductionMethod.methodFrom(name: name,
                                                   introductionURL: introURL,
                                                   successURL: successURL,
                                                   errorURL: errorURL)
    }
    public static func methodFrom(name: String?,
                                  introductionURL: @autoclosure () throws -> URL?,
                                  successURL: @autoclosure () throws -> URL?,
                                  errorURL: @autoclosure () throws -> URL?) throws -> IssuerIntroductionMethod {
        let methodName = name ?? "none"
        var introMethod : IssuerIntroductionMethod?
        switch methodName {
        case "none":
            fallthrough
        case "basic":
            if let url = try introductionURL() {
                introMethod = .basic(introductionURL: url)
            }
        case "web":
            if let url = try introductionURL(),
                var successURL = try successURL(),
                var errorURL = try errorURL() {
                
                
                // Remove any query string parameters from the success & error urls
                if var successComponents = URLComponents(url: successURL, resolvingAgainstBaseURL: false) {
                    successComponents.queryItems = nil
                    successURL = successComponents.url ?? successURL
                }
                
                if var errorComponents = URLComponents(url: errorURL, resolvingAgainstBaseURL: false) {
                    errorComponents.queryItems = nil
                    errorURL = errorComponents.url ?? errorURL
                }
                
                introMethod = .webAuthentication(introductionURL: url, successURL: successURL, errorURL: errorURL)
            }
        default:
            break
        }
        
        return introMethod ?? .unknown
    }
}


/// Signifies when a new key was rotated in for a given purpose.
public struct KeyRotation : Comparable, Codable {
    /// This is when the key was published. As long as no other KeyRotation is observed after this date, it can be safely assumed that this key is valid and in use
    public let on : Date
    /// A base64-encoded string representing the data of the key.
    public let key : String
    
    /// When this certificate was revoked
    public let revoked : Date?
    
    /// WHen this certificate expires on its own, unless it is revoked before
    public let expires : Date?
    
    private enum CodingKeys : String, CodingKey {
        case key = "id"
        case on = "created"
        case revoked, expires
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        key = try container.decode(String.self, forKey: .key)
        let dateString = try container.decode(String.self, forKey: .on)
        if let date = dateString.toDate() {
            on = date
        } else {
            throw IssuerError.invalid(property: "publicKey..id")
        }
        revoked = try container.decodeIfPresent(Date.self, forKey: .revoked)
        expires = try container.decodeIfPresent(Date.self, forKey: .expires)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(key, forKey: .key)
        try container.encode(on.toString(), forKey: .on)
        try container.encodeIfPresent(revoked, forKey: .revoked)
        try container.encodeIfPresent(expires, forKey: .expires)
    }
    
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

