//
//  Receipt.swift
//  cert-wallet
//
//  Created by Kim Duffy on 8/29/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

public struct Receipt {
    public let merkleRoot : String
    public let targetHash : String
    public let proof : [[String : AnyObject]]?
    public let transactionId : String
    
    public init(merkleRoot: String, targetHash: String, proof:[[String: AnyObject]]?, transactionId: String) {
        self.merkleRoot = merkleRoot
        self.targetHash = targetHash
        self.proof = proof
        self.transactionId = transactionId
    }
}
