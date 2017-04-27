//
//  IssuerKey.swift
//  cert-wallet
//
//  Created by Kim Duffy on 4/27/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

public struct IssuerKey {
    
    public let publicKey : String
    public let created : Date?
    public let revoked : Date?
    public let expires : Date?
    
    public init(publicKey: String, created: Date?, revoked: Date?, expires: Date?) {
        self.publicKey = publicKey
        self.created = created
        self.revoked = revoked
        self.expires = expires
    }
}
