//
//  Recipient.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Learning Machine. All rights reserved.
//

import Foundation

struct Recipient {
    let givenName : String
    let familyName : String
    
    let identity : String       // Usually, an email address
    let identityType : String   // "email" by default
    let isHashed : Bool         // false by default
    let publicKey : String      // bitcoin address of recipient
}
