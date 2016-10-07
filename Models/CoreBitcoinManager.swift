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
    func address(for certificate: Certificate, on chain: String) -> String? {
        guard let signature = certificate.signature else {
            return nil
        }
        guard let data = Data(base64Encoded: signature) else {
            return nil
        }
        
        let key = BTCKey.verifySignature(data, forMessage: certificate.assertion.uid)
        
        if chain == "testnet" {
            return key?.addressTestnet.string
        } else {
            return key?.address.string
        }
//        
//        // base64 decode the signature on the certificate
//        let decodedData = NSData.init(base64Encoded: (self?.certificate.signature)!, options: NSData.Base64DecodingOptions(rawValue: 0))
//        // derive the key that produced this signature
//        let btcKey = BTCKey.verifySignature(decodedData as Data!, forMessage: self?.certificate.assertion.uid)
//        // if this succeeds, we successfully derived a key, but still have to check that it matches the issuerKey
//        
//        
//        let address : String?
//        if self?.chain == "testnet" {
//            address = btcKey?.addressTestnet?.string
//        } else {
//            address = btcKey?.address?.string
//        }
        

    }
}
