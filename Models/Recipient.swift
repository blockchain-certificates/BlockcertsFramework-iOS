//
//  Recipient.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// This represents who a certificate is issued to. It also more abstractly represents the user, but they may choose to use different names with differing institutions.
struct Recipient {
    /// The recipient's given name.
    let givenName : String
    
    /// The recipient's family name
    let familyName : String
    
    /// A unique string identifying the recipient. Currently, only an email address is supported
    let identity : String
    
    /// Signifies what type of data exists in the `identity` property. Currently, `"email"` is the only valid value.
    let identityType : String
    
    /// Describes if the value in the identity field is hashed or not. Default is false, indicating that the identity is not hashed.
    let isHashed : Bool
    
    /// Bitcoin address (compressed public key, usually 24 characters) of the recipient.
    let publicAddress : String
}
