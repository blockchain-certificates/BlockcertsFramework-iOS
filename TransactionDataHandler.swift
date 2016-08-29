//
//  TransactionDataRequest.swift
//  cert-wallet
//
//  Created by Kim Duffy on 8/28/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation


struct TransactionData {
    let opReturnScript : String?
    let revokedAddresses : Set<String>?
}

class TransactionDataHandler {
    let transactionId : String?
    let transactionUrlAsString : String?
    var failureReason : String?
    var transactionData : TransactionData?
    
    init(transactionId: String, transactionUrlAsString: String) {
        self.transactionId = transactionId
        self.transactionUrlAsString = transactionUrlAsString
    }
}

class BlockchainInfoHandler : TransactionDataHandler {
    init(transactionId: String) {
        super.init(transactionId: transactionId, transactionUrlAsString: "https://blockchain.info/rawtx/\(transactionId)?cors=true")
    }
    
    func parseResponse(json: [String : AnyObject]) {
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
        
        super.transactionData = TransactionData(opReturnScript : opReturnScript, revokedAddresses: nil)
    }
}

class BlockcypherConnector : TransactionDataHandler {
    init(transactionId: String) {
        super.init(transactionId: transactionId, transactionUrlAsString: "http://api.blockcypher.com/v1/btc/test3/txs/\(transactionId)")
    }
    func parseResponse(json: [String : AnyObject]) {
        guard let outputs = json["outputs"] as? [[String: AnyObject]] else {
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
        
        super.transactionData = TransactionData(opReturnScript : opReturnScript, revokedAddresses: nil)
    }
}
