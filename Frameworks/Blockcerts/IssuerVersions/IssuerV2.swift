//
//  IssuerV2.swift
//  cert-wallet
//
//  Created by Chris Downie on 7/31/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation


public struct IssuerV2 : Issuer, AnalyticsSupport, ServerBasedRevocationSupport, Decodable {
    public let version = IssuerVersion.two
    public let name : String
    public let email : String
    public let image : Data
    public let id : URL
    public let url : URL
    public let introductionMethod : IssuerIntroductionMethod
    public let publicKeys: [KeyRotation]
    
    // MARK: Optional Properties
    public let revocationURL : URL?
    public let analyticsURL: URL?
    
    private enum CodingKeys : String, CodingKey {
        case name, email, image, id, url
        case publicKeys = "publicKey"
        
        case revocationURL = "revocationList"
        case analyticsURL
        
        case introductionAuthenticationMethod
        case introductionURL
        case introductionSuccessURL
        case introductionErrorURL
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
        self.publicKeys = publicKeys.sorted(by: <)
        self.introductionMethod = introductionMethod
        self.analyticsURL = analyticsURL
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        id = try container.decode(URL.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        publicKeys = try container.decode(Array.self, forKey: .publicKeys)
        let imageURL = try container.decode(URL.self, forKey: .image)
        image = try Data(contentsOf: imageURL)
        
        revocationURL = try container.decodeIfPresent(URL.self, forKey: .revocationURL)
        analyticsURL = try container.decodeIfPresent(URL.self, forKey: .analyticsURL)
        
        introductionMethod = try IssuerIntroductionMethod.methodFrom(name: try container.decodeIfPresent(String.self, forKey: .introductionAuthenticationMethod),
                                                                     introductionURL: try container.decodeIfPresent(URL.self, forKey: .introductionURL),
                                                                     successURL: try container.decodeIfPresent(URL.self, forKey: .introductionSuccessURL),
                                                                     errorURL: try container.decodeIfPresent(URL.self, forKey: .introductionErrorURL))
    }
    
    
    /// Create an issuer from a dictionary of data. Typically used when reading from disk or from a network response
    /// This is the inverse of `toDictionary`
    ///
    /// - parameter dictionary: A set of key-value pairs with data used to create the Issuer object
    /// - parameter version: Version hint for parsing
    public init(dictionary: [String: Any], asVersion strictVersion: IssuerVersion? = nil) throws {
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
        
        let parsedIssuerKeys = try parseKeys(from: dictionary, with: "publicKey", converter: keyRotationScheduleV2)
        publicKeys = parsedIssuerKeys.sorted(by: <)
        
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

fileprivate func keyRotationScheduleV2(from dictionary: [String : String]) throws -> KeyRotation {
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
