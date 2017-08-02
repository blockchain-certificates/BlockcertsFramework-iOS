//
//  IssuerV2.swift
//  cert-wallet
//
//  Created by Chris Downie on 7/31/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation


public struct IssuerV2 : Issuer, AnalyticsSupport, ServerBasedRevocationSupport {
    public let version = IssuerVersion.two
    public let name : String
    public let email : String
    public let image : Data
    public let id : URL
    public let url : URL
    public var publicKeys: [KeyRotation] {
        return issuerKeys
    }
    
    // MARK: Optional Properties
    /// An ordered list of KeyRotation objects, with the most recent key rotation first. These represent the keys used to issue certificates during specific date ranges
    public let issuerKeys : [KeyRotation]
    
    /// An ordered list of KeyRotation objects, with the most recent key rotation first. These represent the keys used to revoke certificates.
    public let revocationKeys : [KeyRotation]
    
    /// This defines how the recipient shoudl introduce to the issuer. It replaces `introductionURL`
    public let introductionMethod : IssuerIntroductionMethod
        
    /// v2+ only; url where revocation list is located
    public let revocationURL : URL?
    
    /// v2+ only. This is where you report usage analytics directly to the issuer.
    public let analyticsURL: URL?
    

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
        issuerKeys = publicKeys.sorted(by: <)
        revocationKeys = []
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
        
        let parsedIssuerKeys = try parseKeys(from: dictionary, with: "publicKeys", converter: keyRotationScheduleV2)
        issuerKeys = parsedIssuerKeys.sorted(by: <)
        
        revocationKeys = []
        
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
