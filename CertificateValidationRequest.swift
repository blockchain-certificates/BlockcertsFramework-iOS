//
//  CertificateValidationRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/19/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

// From the example web verifier here:
//
//Step 1 of 5... Computing SHA256 digest of local certificate [DONE]
//Step 2 of 5... Fetching hash in OP_RETURN field [DONE]
//Step 3 of 5... Comparing local and blockchain hashes [PASS]
//Step 4 of 5... Checking Media Lab signature [PASS]
//Step 5 of 5... Checking not revoked by issuer [PASS]
//Success! The certificate has been verified.
enum ValidationState {
    case notStarted
    case computingLocalHash, fetchingRemoteHash, comparingHashes, checkingIssuerSignature, checkingRevokedStatus
    case success
    case failure(reason : String)
}

protocol CertificateValidationRequestDelegate : class {
    func certificateValidationStateChanged(from: ValidationState, to: ValidationState)
}

extension CertificateValidationRequestDelegate {
    func certificateValidationStateChanged(from: ValidationState, to: ValidationState) {
        // By default, do nothing.
    }
}

class CertificateValidationRequest {
    let certificate : Certificate
    let transactionId : String
    var completionHandler : ((Bool, String?) -> Void)?
    weak var delegate : CertificateValidationRequestDelegate?

    var state = ValidationState.notStarted {
        didSet {
            // Notify the delegate
            delegate?.certificateValidationStateChanged(from: oldValue, to: state)
            
            // Perform the action associated with the new state
            switch state {
            case .notStarted:
                break
            case .success:
                completionHandler?(true, nil)
            case .failure(let reason):
                completionHandler?(false, reason)
            case .computingLocalHash:
                self.computeLocalHash()
            case .fetchingRemoteHash:
                self.fetchRemoteHash()
            case .comparingHashes:
                self.compareHashes()
            case .checkingIssuerSignature:
                self.checkIssuerSignature()
            case .checkingRevokedStatus:
                self.checkRevokedStatus()
            }
        }
    }
    
    // Private state built up over the validation sequence
    var localHash : Data? // or String?
    var remoteHash : String? // or String?
    
    init(for certificate: Certificate, with transactionId: String, starting : Bool = false, completionHandler: ((Bool, String?) -> Void)? = nil) {
        self.certificate = certificate
        self.transactionId = transactionId
        self.completionHandler = completionHandler
        
        if (starting) {
            self.start()
        }
    }
    
    func start() {
        state = .computingLocalHash
    }
    
    func abort() {
        state = .failure(reason: "Aborted")
    }
    
    private func computeLocalHash() {
        localHash = sha256(data: certificate.file)
        state = .fetchingRemoteHash
    }
    private func fetchRemoteHash() {
        guard let transactionUrl = URL(string: "https://blockchain.info/rawtx/\(transactionId)?cors=true") else {
            state = .failure(reason: "Transaction ID (\(transactionId)) is invalid")
            return
        }
        let task = URLSession.shared.dataTask(with: transactionUrl) { [weak self] (data, response : URLResponse?, _) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                self?.state = .failure(reason: "Got invalid response from \(transactionUrl)")
                return
            }
            guard let data = data else {
                self?.state = .failure(reason: "Got a valid response, but no data from \(transactionUrl)")
                return
            }

            // Let's parse the OP_RETURN value out of the data.
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject] else {
                self?.state = .failure(reason: "Transaction didn't return valid JSON data from \(transactionUrl)")
                return
            }
            guard let outputs = json?["out"] as? [[String: AnyObject]] else {
                self?.state = .failure(reason: "Missing 'out' property in response:\n\(json)")
                return
            }
            guard let lastOutput = outputs.last else {
                self?.state = .failure(reason: "Couldn't find the last 'value' key in outputs: \(outputs)")
                return
            }
            guard let value = lastOutput["value"] as? Int,
                let hash = lastOutput["script"] as? String else {
                self?.state = .failure(reason: "Invalid types for 'value' or 'string' in output: \(lastOutput)")
                return
            }
            guard value == 0 else {
                self?.state = .failure(reason: "No output values were 0: \(outputs)")
                return
            }
            self?.remoteHash = hash
            
            self?.state = .comparingHashes
        }
        task.resume()
    }
    private func compareHashes() {
        state = .failure(reason: "\(#function) not implemented")
        // Success
//        state = .checkingIssuerSignature
    }
    private func checkIssuerSignature() {
        state = .failure(reason: "\(#function) not implemented")
        // Success
//        state = .checkingRevokedStatus
    }
    private func checkRevokedStatus() {
        state = .failure(reason: "\(#function) not implemented")
        // Success
//        state = .success
    }
    
    // MARK: helper functions
    func sha256(data : Data) -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &hash)
        }
        return Data(bytes: hash)
    }
}
