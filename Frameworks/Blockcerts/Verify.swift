//
//  Verify.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// Representing any data needed to verify a certificate.
public struct Verify {
    /// URI where issuer's public key is presented, or the public key itself. One of these will be present
    public let signer : URL?
    public let publicKey : String?
    
    /// Name of the attribute in the json that is signed by the issuer's private key. Default is `"uid"`, referring to the uid attribute.
    public let signedAttribute : String?
    
    /// Name of the signing method. Default is `"ECDSA(secp256k1)"`, referring to the Bitcoin method of signing messages with the issuer's private key.
    public let type : String
    
    public init(signer: URL?, publicKey: String?, signedAttribute: String?, type: String) {
        self.signer = signer
        self.publicKey = publicKey
        self.signedAttribute = signedAttribute
        self.type = type
    }
}

