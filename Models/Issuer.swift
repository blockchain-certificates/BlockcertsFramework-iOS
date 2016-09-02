//
//  Issuer.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

struct Issuer {
    let name : String
    let email : String
    let image : Data
    let id : URL
    let url : URL
    
    var publicKey : String?
    let publicKeyAddress : URL?
    let requestUrl : URL?

    init(name: String, email: String, image: Data, id: URL, url: URL, publicKey: String?, publicKeyAddress: URL?, requestUrl: URL) {
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        self.publicKey = publicKey
        self.publicKeyAddress = publicKeyAddress
        self.requestUrl = requestUrl
    }
    init(name: String, email: String, image: Data, id: URL, url: URL) {
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        publicKey = nil
        publicKeyAddress = nil
        requestUrl = nil
    }
    
    init?(dictionary: [String: String]) {
        guard let name = dictionary["name"],
            let email = dictionary["email"],
            let imageString = dictionary["image"],
            let image = Data(base64Encoded: imageString),
            let idString = dictionary["id"],
            let id = URL(string: idString),
            let urlString = dictionary["url"],
            let url = URL(string: urlString) else {
            return nil
        }
        
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        self.publicKey = dictionary["publicKey"]
        if let addressString = dictionary["publicKeyAddress"],
            let publicKeyAddress = URL(string: addressString) {
            self.publicKeyAddress = publicKeyAddress
        } else {
            publicKeyAddress = nil
        }
        if let requestString = dictionary["requestUrl"],
            let requestUrl = URL(string: requestString) {
            self.requestUrl = requestUrl
        } else {
            requestUrl = nil
        }
    }
    
    
    func toDictionary() -> [String: String] {
        var dictionary = [
            "name": name,
            "email": email,
            "image": String(data: image, encoding: .utf8)!,
            "id": "\(id)",
            "url": "\(url)",
        ]
        if let publicKey = publicKey {
            dictionary["publicKey"] = publicKey
        }
        if let publicKeyAddress = publicKeyAddress {
            dictionary["publicKeyAddress"] = "\(publicKeyAddress)"
        }
        if let requestUrl = requestUrl {
            dictionary["requestUrl"] = "\(requestUrl)"
        }
        
        return dictionary
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
        && lhs.publicKey == rhs.publicKey
        && lhs.publicKeyAddress == rhs.publicKeyAddress
        && lhs.requestUrl == rhs.requestUrl
}
