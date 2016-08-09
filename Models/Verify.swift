//
//  Verify.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

struct Verify {
    let signer : URL
    let signedAttribute : String    // default is "uid"
    let type : String               // "ECDSA(secp256k1)" is default -- what else is valid?
}
