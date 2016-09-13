//
//  Verify.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// Representing any data needed to verify a certificate.
struct Verify {
    /// URI where issuer's public key is presented.
    let signer : URL
    
    /// Name of the attribute in the json that is signed by the issuer's private key. Default is `"uid"`, referring to the uid attribute.
    let signedAttribute : String
    
    /// Name of the signing method. Default is `"ECDSA(secp256k1)"`, referring to the Bitcoin method of signing messages with the issuer's private key.
    let type : String
}
