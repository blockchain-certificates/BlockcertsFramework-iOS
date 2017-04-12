//
//  CoreBitcoinManager.swift
//  cert-wallet
//
//  Created by Chris Downie on 10/7/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation
import BlockchainCertificates

class CoreBitcoinManager : BitcoinManager {
    func address(for message: String, with signature: String, on chain: String) -> String? {
        
        // Check the issuer key: here's how it works:
        // 1. base64 decode the signature that's on the certificate ('signature') field
        // 2. use the CoreBitcoin library method BTCKey.verifySignature to derive the key used to create this signature:
        //    - it takes as input the signature on the certificate and the message (the assertion uid) that we expect it to be the signature of.
        //    - it returns a matching BTCKey if found
        // 3. we still have to check that the BTCKey returned above matches the issuer's public key that we looked up
        guard let data = Data(base64Encoded: signature) else {
            return nil
        }
        
        let key = BTCKey.verifySignature(data, forMessage: message)
        
        if chain == "testnet" {
            return key?.addressTestnet.string
        } else {
            return key?.address.string
        }
    }
}
