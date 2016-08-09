//
//  Issuer.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Learning Machine. All rights reserved.
//

import Foundation

struct Issuer {
    let name : String
    let email : String
    let image : Data
    let id : URL
    let url : URL
    
    let publicKey : String
    let publicKeyAddress : URL
    let requestUrl : URL
    
    func introduce(recipient: Recipient) {
        
    }
}
