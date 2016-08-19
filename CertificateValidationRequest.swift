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
    
    @discardableResult init(for certificate: Certificate, starting : Bool = false, completionHandler: ((Bool, String?) -> Void)? = nil) {
        self.certificate = certificate
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
        state = .failure(reason: "\(#function) not implemented")
        // Success
//        state = .fetchingRemoteHash
    }
    private func fetchRemoteHash() {
        state = .failure(reason: "\(#function) not implemented")
        // Success
//        state = .comparingHashes
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
}
