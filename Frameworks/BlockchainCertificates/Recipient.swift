//
//  Recipient.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// This represents who a certificate is issued to. It also more abstractly represents the user, but they may choose to use different names with differing institutions.
public struct Recipient {
    /// The recipient's name.
    public let name : String
    
    /// A unique string identifying the recipient. Currently, only an email address is supported
    public let identity : String
    
    /// Signifies what type of data exists in the `identity` property. Currently, `"email"` is the only valid value.
    public let identityType : String
    
    /// Describes if the value in the identity field is hashed or not. Default is false, indicating that the identity is not hashed.
    public let isHashed : Bool
    
    /// Bitcoin address (compressed public key, usually 24 characters) of the recipient.
    public let publicAddress : String
    
    /// Issuer's recipient-specific revocation Bitcoin address (compressed public key, usually 24 characters).
    public let revocationAddress : String?
    
    public init(name: String, identity: String, identityType: String, isHashed: Bool, publicAddress: String, revocationAddress: String?) {
        self.name = name
        self.identity = identity
        self.identityType = identityType
        self.isHashed = isHashed
        self.publicAddress = publicAddress
        self.revocationAddress = revocationAddress
    }
}
