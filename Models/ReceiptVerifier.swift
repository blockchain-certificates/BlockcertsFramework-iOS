//
//  ReceiptVerifier.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/15/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

class ReceiptVerifier {
    
    /**
     Takes a receipt
     Checks the validity of the proof and return true or false
     :param receipt:
     :return:
     */
    func validate(receipt : Receipt, chain: String) -> Bool {
        guard let proof = receipt.proof else {
            // no siblings, single item tree, so the hash should also be the root
            return receipt.targetHash == receipt.merkleRoot
        }
        
        guard let targetHash = receipt.targetHash.asHexData(),
            let merkleRoot = receipt.merkleRoot.asHexData() else {
                // Receipt's target hash and merkle root should both be hex strings.
                return false
        }
        
        var proofHash = targetHash
        for x in proof {
            if let xLeft = x["left"] as? String,
                let xLeftBuffer = xLeft.asHexData() {
                let appendedBuffer = xLeftBuffer + proofHash
                proofHash = sha256(data: appendedBuffer)
            } else if let xRight = x["right"] as? String,
                let xRightBuffer = xRight.asHexData() {
                let appendedBuffer = proofHash + xRightBuffer
                proofHash = sha256(data: appendedBuffer)
            } else {
                // Either:
                // 1. There's no left or right key.
                // 2. There is, but it's not properly formatted hex data.
                //
                // In either case, we can't correctly compute the hash. This receipt is clearly invalid.
                return false
            }
        }
        
        return proofHash == merkleRoot
    }
}
