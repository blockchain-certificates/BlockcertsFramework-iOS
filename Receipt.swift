//
//  Receipt.swift
//  cert-wallet
//
//  Created by Kim Duffy on 8/29/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

struct Receipt {
    let merkleRoot : String
    let targetHash : String
    let proof : [[String : AnyObject]]?
    let transactionId : String
}

class ReceiptVerifier {
    
    /**
     Takes a receipt
     Checks the validity of the proof and return true or false
     :param receipt:
     :return:
     */
    func validate(receipt : Receipt, chain: String) -> Bool {
        
        if receipt.proof == nil {
            // no siblings, single item tree, so the hash should also be the root
            return receipt.targetHash == receipt.merkleRoot
        }
        
        let targetHash = receipt.targetHash.asHexData()
        let merkleRoot = receipt.merkleRoot.asHexData()

        var proofHash = targetHash
        for x in receipt.proof! {
            if let xLeft : String? = x["left"] as? String? {
                let xLeftBuffer = xLeft?.asHexData()
                let appendedBuffer = xLeftBuffer! + proofHash!
                proofHash = sha256(data: appendedBuffer)
            } else {
                let xRight : String? = (x["right"] as? String?)!
                let xRightBuffer = xRight?.asHexData()
                let appendedBuffer = proofHash! + xRightBuffer!
                proofHash = sha256(data: appendedBuffer)
            }
        }
        return proofHash == merkleRoot
    }
}
