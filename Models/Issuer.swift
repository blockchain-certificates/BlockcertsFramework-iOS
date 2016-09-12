//
//  Issuer.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

struct KeyRotation {
    let on : Date
    let key : String
}

struct Issuer {
    let name : String
    let email : String
    let image : Data
    let id : URL
    let url : URL
    let issuerKeys : [KeyRotation]
    let revocationKeys : [KeyRotation]
    
    var publicKey : String? {
        return issuerKeys.first?.key
    }
    let introductionURL : URL

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
        introductionURL = URL(string: "http://google.com")!
    }
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
    
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
            let email = dictionary["email"] as? String,
            let imageString = dictionary["image"] as? String,
            let imageURL = URL(string: imageString),
            let image = try? Data(contentsOf: imageURL),
            let idString = dictionary["id"] as? String,
            let id = URL(string: idString),
            let urlString = dictionary["url"] as? String,
            let url = URL(string: urlString),
            let introductionString = dictionary["introductionURL"] as? String,
            let introductionURL = URL(string: introductionString) else {
            return nil
        }
        
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        self.introductionURL = introductionURL
        
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

        return [
            "name": name,
            "email": email,
            "image": String(data: image, encoding: .utf8)!,
            "id": "\(id)",
            "url": "\(url)",
            "introductionURL": "\(introductionURL)",
            "issuerKeys": serializedIssuerKeys,
            "revocationKeys": serializedRevocationKeys
        ]
    }
    
    
    func introduce(recipient: Recipient) {
        
    }
}

// MARK: - Equality test
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
