//
//  TransactionDataRequest.swift
//  cert-wallet
//
//  Created by Kim Duffy on 8/28/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation


public struct TransactionData {
    public let opReturnScript : String?
    public let revokedAddresses : Set<BlockchainAddress>?
    public let signingPublicKey : BlockchainAddress?
    public let txDate : Date?
}

public class TransactionDataHandler {
    public let transactionUrlAsString : String?
    public var failureReason : String?
    public var transactionData : TransactionData?
    
    public init(transactionUrlAsString: String) {
        self.transactionUrlAsString = transactionUrlAsString
    }
    
    public func parseResponse(json: [String : AnyObject]) {
        // TODO: this actually is intended as a abstract method, which means this should be
        // done differently....
    }
    
    public static func create(chain: BitcoinChain, transactionId: String) -> TransactionDataHandler {
        if chain == .testnet {
            let transactionUrlAsString = "http://api.blockcypher.com/v1/btc/test3/txs/\(transactionId)";
            return BlockcypherHandler(transactionUrlAsString: transactionUrlAsString);
        } else {
            let transactionUrlAsString = "https://api.blockcypher.com/v1/btc/main/txs/\(transactionId)";
            return BlockcypherHandler(transactionUrlAsString: transactionUrlAsString);
        }
        
        // We can use this for fallback in the future if we want...
        //return BlockchainInfoHandler(transactionId: transactionId)
    }
}

public class BlockchainInfoHandler : TransactionDataHandler {
    
    override public func parseResponse(json: [String : AnyObject]) {
        guard let outputs = json["out"] as? [[String: AnyObject]] else {
            super.failureReason = "Missing 'out' property in response:\n\(json)"
            return
        }
        guard let lastOutput = outputs.last else {
            super.failureReason = "Couldn't find the last 'value' key in outputs: \(outputs)"
            return
        }
        guard let value = lastOutput["value"] as? Int,
            let opReturnScript = lastOutput["script"] as? String else {
                super.failureReason = "Couldn't find the last 'value' key in outputs: \(outputs)"
                return
        }
        guard value == 0 else {
            super.failureReason = "No output values were 0: \(outputs)"
            return
        }
        var revoked : Set<BlockchainAddress> = Set()
        for output in outputs {
            if (output["spent"] as? Bool == true) {
                let address = output["addr"] as! String
                revoked.insert(BlockchainAddress(string: address))
            }
        }
        
        super.transactionData = TransactionData(opReturnScript: opReturnScript,
                                                revokedAddresses: revoked,
                                                signingPublicKey: nil,
                                                txDate: nil)
    }
}

public class BlockcypherHandler : TransactionDataHandler {

    override public func parseResponse(json: [String : AnyObject]) {
        guard let outputs = json["outputs"] as? [[String: AnyObject]] else {
            super.failureReason = "Missing 'outputs' property in response:\n\(json)"
            return
        }
        guard let lastOutput = outputs.last else {
            super.failureReason = "Couldn't find the last 'value' key in outputs: \(outputs)"
            return
        }
        guard let value = lastOutput["value"] as? Int,
            let opReturnScript = lastOutput["data_hex"] as? String else {
                super.failureReason = "Couldn't find the last 'value' key in outputs: \(outputs)"
                return
        }
        guard value == 0 else {
            super.failureReason = "No output values were 0: \(outputs)"
            return
        }
        var revoked : Set<BlockchainAddress> = Set()
        for output in outputs {
            if (output["spent_by"] as? String != nil) {
                let addresses = output["addresses"] as! [String]
                revoked.insert(BlockchainAddress(string: addresses[0]))
            }
        }
        
        guard let inputs = json["inputs"] as? [[String: AnyObject]] else {
            super.failureReason = "Missing 'inputs' property in response:\n\(json)"
            return
        }
        
        guard let firstInput = inputs.first else {
            super.failureReason = "Couldn't find the first 'input' key in inputs: \(inputs)"
            return
        }
        
        guard let addresses = firstInput["addresses"] as? [String] else {
            super.failureReason = "Couldn't find the 'addresses' key in inputs: \(inputs)"
            return
        }
        
        guard let signingPublicKeyValue = addresses.first else {
            super.failureReason = "Couldn't find the first signing public key inputs: \(inputs)"
            return
        }
        let signingPublicKey = BlockchainAddress(string: signingPublicKeyValue)

        guard let txDateString = json["received"] as? String else {
            super.failureReason = "Missing 'received' property in response:\n\(json)"
            return
        }
        
        let txDate = txDateString.toDate()
        super.transactionData = TransactionData(opReturnScript : opReturnScript, revokedAddresses: revoked, signingPublicKey: signingPublicKey, txDate: txDate)
    }
}
