//
//  Issuer.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// <#Description#>
struct KeyRotation {
    let on : Date
    let key : String
}

struct Issuer {
    // MARK: - Properties
    // MARK: Required properties
    /// The name of the issuer.
    let name : String
    
    /// The email address where you can contact the issuer
    let email : String
    
    /// Image data for the issuer. This can be used to populate a UIImage object
    let image : Data
    
    /// Unique identifier for an Issuer. Also, the URL where you can re-request data. This is useful if an instance of this struct only has partial data, or if you want to see that the keys are still valid.
    let id : URL
    
    /// Where you can go to check a list of certificates issued by this issuer.
    let url : URL
    
    // MARK: Optional Properties
    /// An ordered list of KeyRotation objects, with the most recent key rotation first. These represent the keys used to issue certificates during specific date ranges
    let issuerKeys : [KeyRotation]
    
    /// An ordered list of KeyRotation objects, with the most recent key rotation first. These represent the keys used to revoke certificates.
    let revocationKeys : [KeyRotation]
    
    /// The URL where you can make a POST request with recipient data in order to introduce a Recipient to an Issuer. For more information, look at `IssuerIntroductionRequest`
    let introductionURL : URL?
    
    // MARK: Convenience Properties
    /// A convenience method for the most recent (and theoretically only valid) issuerKey.
    var publicKey : String? {
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
    init(name: String,
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
    init(name: String,
         email: String,
         image: Data,
         id: URL,
         url: URL,
         publicIssuerKeys: [KeyRotation],
         publicRevocationKeys: [KeyRotation],
         introductionURL: URL) {
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        issuerKeys = publicIssuerKeys.sorted(by: <)
        revocationKeys = publicRevocationKeys.sorted(by: <)
        self.introductionURL = introductionURL
    }
    
    /// Create an issuer from a dictionary of data. Typically used when reading from disk or from a network response
    /// This is the inverse of `toDictionary`
    ///
    /// - parameter dictionary: A set of key-value pairs with data used to create the Issuer object
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
            let email = dictionary["email"] as? String,
            let imageString = dictionary["image"] as? String,
            let imageURL = URL(string: imageString),
            let image = try? Data(contentsOf: imageURL),
            let idString = dictionary["id"] as? String,
            let id = URL(string: idString),
            let urlString = dictionary["url"] as? String,
            let url = URL(string: urlString) else {
            return nil
        }
        
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        if let introductionString = dictionary["introductionURL"] as? String,
            let introductionURL = URL(string: introductionString) {
            self.introductionURL = introductionURL
        } else {
            self.introductionURL = nil
        }
        
        guard let issuerKeyData = dictionary["issuerKey"] as? [[String: String]],
            let revocationKeyData = dictionary["revocationKey"] as? [[String : String]] else {
                return nil
        }
        
        func keyRotationSchedule(from dictionary: [String : String]) -> KeyRotation? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            guard let dateString = dictionary["date"],
                let date = dateFormatter.date(from: dateString),
                let key = dictionary["key"] else {
                    return nil
            }
            
            return KeyRotation(on: date, key: key)
        }
        issuerKeys = issuerKeyData.flatMap(keyRotationSchedule).sorted(by: <)
        revocationKeys = revocationKeyData.flatMap(keyRotationSchedule).sorted(by: <)

        // This is only valid if we have at least 1 issuerKey and 1 revocation key.
        // Also, if the `flatMap` returned nil from any of the keyData items, then fail. We may be able to relax this constraint, but since it would have an impact on valid public key date ranges, I figure we should just fail the parse.
        guard issuerKeys.count > 0,
            issuerKeys.count == issuerKeyData.count,
            revocationKeys.count > 0,
            revocationKeys.count == revocationKeyData.count else {
                return nil
        }
    }
    
    
    /// Convert this Issuer structure into a dictionary format.
    ///
    /// - returns: The dictionary representing this Issuer.
    func toDictionary() -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let serializedIssuerKeys = issuerKeys.map { (keyRotation) -> [String : String] in
            return [
                "date": dateFormatter.string(from: keyRotation.on),
                "key": keyRotation.key
            ]
        }
        let serializedRevocationKeys = revocationKeys.map { (keyRotation) -> [String : String] in
            return [
                "date": dateFormatter.string(from: keyRotation.on),
                "key": keyRotation.key
            ]
        }

        var dictionary : [String: Any] = [
            "name": name,
            "email": email,
            "image": String(data: image, encoding: .utf8)!,
            "id": "\(id)",
            "url": "\(url)",
            "issuerKeys": serializedIssuerKeys,
            "revocationKeys": serializedRevocationKeys
        ]
        if introductionURL != nil {
            dictionary["introductionURL"] = "\(introductionURL)"
        }
        
        return dictionary
    }
}

// MARK: - Equatable & Comparable conformance
extension Issuer : Equatable {}

func ==(lhs: Issuer, rhs: Issuer) -> Bool {
    return lhs.name == rhs.name
        && lhs.email == rhs.email
        && lhs.image == rhs.image
        && lhs.id == rhs.id
        && lhs.url == rhs.url
        && lhs.issuerKeys == rhs.issuerKeys
        && lhs.revocationKeys == rhs.revocationKeys
}

extension KeyRotation : Comparable {}

func ==(lhs: KeyRotation, rhs: KeyRotation) -> Bool {
    return lhs.on == rhs.on && lhs.key == rhs.key
}

func <(lhs: KeyRotation, rhs: KeyRotation) -> Bool {
    return lhs.on < rhs.on
}
