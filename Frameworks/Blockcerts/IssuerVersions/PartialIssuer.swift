//
//  File.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/3/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

public struct PartialIssuer : Issuer, Codable {
    public let version = IssuerVersion.embedded
    public let name : String
    public let email : String
    public let image : Data
    public let id : URL
    public let url : URL
    public let publicKeys = [KeyRotation]()
    public let introductionMethod: IssuerIntroductionMethod = .unknown
    
    public let revocationListURL : URL?
    
    private enum CodingKeys : String, CodingKey {
        case name, email, image, id, url
        case revocationListURL = "revocationList"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        let imageURL = try container.decode(URL.self, forKey: .image)
        image = try Data(contentsOf: imageURL)
        id = try container.decode(URL.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        revocationListURL = try container.decodeIfPresent(URL.self, forKey: .revocationListURL)
    }
    
    public init(dictionary: [String: Any]) throws {
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
        
        self.name = name
        self.email = email
        self.image = image
        self.id = id
        self.url = url
        
        if let revocationListString = dictionary["revocationList"] as? String {
            revocationListURL = URL(string: revocationListString)
        } else {
            revocationListURL = nil
        }
    }
    
    public func toDictionary() -> [String : Any] {
        var dict = [String:Any]()
        dict["id"] = id
        dict["name"] = name
        dict["email"] = email
        dict["image"] = "data:image/png;base64,\(image.base64EncodedString())"
        dict["url"] = url
        return dict
    }
}
