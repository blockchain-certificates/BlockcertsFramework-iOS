//
//  CertificateValidationRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/19/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation
import JSONLD
import CommonCrypto

// From the example web verifier here:
//
//Step 1 of 5... Computing SHA256 digest of local certificate [DONE]
//Step 2 of 5... Fetching hash in OP_RETURN field [DONE]
//Step 3 of 5... Comparing local and blockchain hashes [PASS]
//Step 4 of 5... Checking Media Lab signature [PASS]
//Step 5 of 5... Checking not revoked by issuer [PASS]
//Success! The certificate has been verified.
public enum ValidationState {
    case notStarted
    case assertingChain
    case computingLocalHash, fetchingRemoteHash, comparingHashes, checkingIssuerSignature, checkingRevokedStatus
    case success
    case failure(reason : String)
    // these are v1.2
    case checkingReceipt, checkingMerkleRoot
}

public protocol CertificateValidationRequestDelegate : class {
    func certificateValidationStateChanged(from: ValidationState, to: ValidationState)
}

extension CertificateValidationRequestDelegate {
    func certificateValidationStateChanged(from: ValidationState, to: ValidationState) {
        // By default, do nothing.
    }
}

public class CertificateValidationRequest : CommonRequest {
    let session : URLSessionProtocol
    let jsonld : JSONLDProcessor
    let bitcoinManager : BitcoinManager
    let certificate : Certificate
    let transactionId : String
    var completionHandler : ((Bool, String?) -> Void)?
    public weak var delegate : CertificateValidationRequestDelegate?
    let chain : String

    public var state = ValidationState.notStarted {
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
            case .assertingChain:
                self.assertChain()
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
            case .checkingMerkleRoot:
                self.checkMerkleRoot()
            case .checkingReceipt:
                self.checkReceipt()
            }
        }
    }
    
    // Private state built up over the validation sequence
    var localHash : String?
    var remoteHash : String?
    private var revocationKey : String?
    private var revokedAddresses : Set<String>?
    var normalizedCertificate : String?
    
    public init(for certificate: Certificate,
         with transactionId: String,
         bitcoinManager: BitcoinManager,
         chain: String = "mainnet",
         starting : Bool = false,
         jsonld : JSONLDProcessor = JSONLD.shared,
         session : URLSessionProtocol = URLSession.shared,
         completionHandler: ((Bool, String?) -> Void)? = nil) {
        self.session = session
        self.jsonld = jsonld
        self.certificate = certificate
        self.transactionId = transactionId
        self.completionHandler = completionHandler
        self.chain = chain
        self.bitcoinManager = bitcoinManager
        
        if (starting) {
            self.start()
        }
    }
    
    public convenience init?(for certificate: Certificate,
                      bitcoinManager: BitcoinManager,
                     chain: String = "mainnet",
                     starting : Bool = false,
                     jsonld : JSONLDProcessor = JSONLD.shared,
                     session: URLSessionProtocol = URLSession.shared,
                     completionHandler: ((Bool, String?) -> Void)? = nil) {
        guard let transactionId = certificate.receipt?.transactionId else {
            // To use this init function
            return nil
        }
        
        self.init(for: certificate,
                  with: transactionId,
                  bitcoinManager: bitcoinManager,
                  chain: chain,
                  starting: starting,
                  jsonld: jsonld,
                  session: session,
                  completionHandler: completionHandler)
    }
    
    public func start() {
        state = .assertingChain
    }
    
    public func abort() {
        state = .failure(reason: "Aborted")
    }
    
    internal func assertChain() {
        guard chain == "mainnet" else {
            // We only need to assert mainnet if the chain is set to mainnet. If it's any other value, then we can't be held responsible for how you're validating.
            state = .computingLocalHash
            return
        }
        
        var targetAddress = certificate.recipient.publicAddress
        let addressPrefixSeparator = ":"
        if let separatorRange = targetAddress.range(of: addressPrefixSeparator) {
            targetAddress = targetAddress.substring(from: separatorRange.upperBound)
        }
        
        // All mainnet addresses start with 1.
        guard targetAddress.hasPrefix("1") else {
            if targetAddress.hasPrefix("m") || targetAddress.hasPrefix("n") {
                state = .failure(reason: "This is a testnet certificate. It cannot be validated.")
            } else {
                state = .failure(reason: "This certificate is from an unknown blockchain and cannot be validated.")
            }
            return
        }
        
        state = .computingLocalHash
    }
    
    internal func computeLocalHash() {
        if certificate.version == .oneDotOne {
            self.localHash = sha256(data: certificate.file).asHexString()
            state = .fetchingRemoteHash
        } else if certificate.version == .oneDotTwo {
            let docData : Data!
            do {
                let json = try JSONSerialization.jsonObject(with: certificate.file, options: []) as! [String: Any]
                let document = json["document"] as! [String: Any]
                docData = try JSONSerialization.data(withJSONObject: document, options: [])
            } catch {
                state = .failure(reason: "Failed to re-parse the document node out of the certificate's file.")
                return
            }
            
            jsonld.normalize(docData: docData, callback: { (error, resultString) in
                guard error == nil else {
                    self.state = .failure(reason: "Failed JSON-LD compact with \(error!)")
                    return
                }
                guard let resultString = resultString else {
                    self.state = .failure(reason: "There's no error, but the resultData is nil.")
                    return
                }
                guard let stringData = resultString.data(using: .utf8) else {
                    self.state = .failure(reason: "Result could not be translated into raw data: \(resultString)")
                    return
                }
                
                self.localHash = sha256(data: stringData).asHexString()

                self.state = .fetchingRemoteHash
            })
        } else {
            let docData : Data!
            do {
                var json = try JSONSerialization.jsonObject(with: certificate.file, options: []) as! [String: Any]
                json.removeValue(forKey: "signature")
                docData = try JSONSerialization.data(withJSONObject: json, options: [])
            } catch {
                state = .failure(reason: "Failed to re-parse the document node out of the certificate's file.")
                return
            }

            jsonld.normalize(docData: docData, callback: { (error, resultString) in
                guard error == nil else {
                    self.state = .failure(reason: "Failed JSON-LD compact with \(error!)")
                    return
                }
                guard let resultString = resultString else {
                    self.state = .failure(reason: "There's no error, but the resultData is nil.")
                    return
                }
                guard let stringData = resultString.data(using: .utf8) else {
                    self.state = .failure(reason: "Result could not be translated into raw data: \(resultString)")
                    return
                }
                
                self.normalizedCertificate = resultString
                
                self.localHash = sha256(data: stringData).asHexString()
                
                self.state = .fetchingRemoteHash
            })
            
        }
    }
    
    internal func fetchRemoteHash() {
        let transactionDataHandler = TransactionDataHandler.create(chain: self.chain, transactionId: transactionId)
        
        guard let transactionUrl = URL(string: transactionDataHandler.transactionUrlAsString!) else {
            state = .failure(reason: "Transaction ID (\(transactionId)) is invalid")
            return
        }
        let task = session.dataTask(with: transactionUrl) { [weak self] (data, response : URLResponse?, _) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                self?.state = .failure(reason: "Got invalid response from \(transactionUrl)")
                return
            }
            guard let data = data else {
                self?.state = .failure(reason: "Got a valid response, but no data from \(transactionUrl)")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject] else {
                self?.state = .failure(reason: "Transaction didn't return valid JSON data from \(transactionUrl)")
                return
            }
            
            // Let's parse the OP_RETURN value out of the data.
            transactionDataHandler.parseResponse(json: json!)
            guard let transactionData = transactionDataHandler.transactionData else {
                self?.state = .failure(reason: transactionDataHandler.failureReason!)
                return
            }
            
            var possibleRemoteHash = transactionData.opReturnScript
            
            // Some providers prepend
            let opReturnPrefix = "6a20"
            if let remoteHash = possibleRemoteHash,
                remoteHash.hasPrefix(opReturnPrefix) {
                let startIndex = remoteHash.index(remoteHash.startIndex, offsetBy: opReturnPrefix.characters.count)
                possibleRemoteHash = remoteHash.substring(from: startIndex)
            }
            
            self?.remoteHash = possibleRemoteHash
            self?.revokedAddresses = transactionData.revokedAddresses
            
            self?.state = .comparingHashes
        }
        task.resume()
    }
    
    internal func compareHashes() {
        let compareToHash : String?
        if certificate.version == .oneDotOne,
            let remoteHash = self.remoteHash {
            compareToHash = remoteHash
        } else {
            compareToHash = self.certificate.receipt?.targetHash
        }
        
        guard let localHash = self.localHash,
            let correctHashResult = compareToHash else {
                state = .failure(reason: "Can't compare hashes: one of the hashes is still nil")
                return
        }
        
        guard localHash == correctHashResult else {
            state = .failure(reason: "Local hash doesn't match remote hash:\n Local:\(localHash)\nRemote:\(correctHashResult)")
            return
        }
        
        if certificate.version == .oneDotOne {
            state = .checkingIssuerSignature
        } else {
            state = .checkingMerkleRoot
        }
    }
    internal func checkIssuerSignature() {
        let url = certificate.issuer.id
        let request = session.dataTask(with: certificate.issuer.id) { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                    self?.state = .failure(reason: "Got invalid response from \(url)")
                    return
            }
            guard let data = data else {
                self?.state = .failure(reason: "Got a valid response, but no data from \(url)")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as! [String: AnyObject] else {
                self?.state = .failure(reason: "Certificate didn't return valid JSON data from \(url)")
                return
            }
            
            let chain = self?.chain ?? "mainnet"
            guard let bitcoinManager = self?.bitcoinManager else {
                self?.state = .failure(reason: "Incorrect configuration. ValidationRequest needs to have a bitcoin manager specified.")
                return
            }
            guard (self?.certificate) != nil else {
                self?.state = .failure(reason: "Certificate is missing.")
                return
            }
            
            guard let signature = self?.certificate.signature?.value else {
                self?.state = .failure(reason: "Signature is missing")
                return
            }
            
            if self?.certificate.version == .two {
                guard let issuerKey = json["publicKey"] as? String else {
                    self?.state = .failure(reason: "Couldn't parse issuerKey")
                    return
                }
                guard let normalizedCertificate = self?.normalizedCertificate else {
                    self?.state = .failure(reason: "Missing normalized certificate")
                    return
                }
                // TODO: date is hard-coded
                guard let created = self?.certificate.signature?.created else {
                    self?.state = .failure(reason: "Missing signature date")
                    return
                }
                let messageTemp : String? = getDataToHash(input: normalizedCertificate, date: created)
                guard let message = messageTemp else {
                    self?.state = .failure(reason: "Couldn't parse message")
                    return
                }
                
                let address = bitcoinManager.address(for: message, with: signature, on: chain)
                
                guard address == issuerKey else {
                    self?.state = .failure(reason: "Issuer key doesn't match derived address:\n Address:\(address!)\n issuerKey:\(issuerKey)")
                    return
                }
                
            } else {
                guard let issuerKeys = json["issuerKeys"] as? [[String : String]],
                    let revocationKeys = json["revocationKeys"] as? [[String : String]] else {
                        self?.state = .failure(reason: "Couldn't parse issuerKeys or revocationKeys from json: \n\(json)")
                        return
                }
                guard let revokeKey = revocationKeys.first?["key"] else {
                        self?.state = .failure(reason: "Couldn't parse first revokeKey")
                        return
                }
                self?.revocationKey = revokeKey
                guard let issuerKey = issuerKeys.first?["key"] else {
                    self?.state = .failure(reason: "Couldn't parse issuerKey")
                    return
                }
                guard let message = self?.certificate.assertion.uid else {
                    self?.state = .failure(reason: "Couldn't parse message")
                    return
                }
                
                let address = bitcoinManager.address(for: message, with: signature, on: chain)
                
                guard address == issuerKey else {
                    self?.state = .failure(reason: "Issuer key doesn't match derived address:\n Address:\(address!)\n issuerKey:\(issuerKey)")
                    return
                }
            }
            
            self?.state = .checkingRevokedStatus
        }
        request.resume()
    }
    
    internal func checkRevokedStatus() {
        if certificate.version == .two {
            guard let url = certificate.issuer.revocationURL else {
                // Issuer does not revoke certificates
                // Success
                self.state = .success
                return
            }
            let request = session.dataTask(with: url) { [weak self] (data, response, error) in
                guard let response = response as? HTTPURLResponse,
                    response.statusCode == 200 else {
                        self?.state = .failure(reason: "Got invalid response from \(url)")
                        return
                }
                guard let data = data else {
                    self?.state = .failure(reason: "Got a valid response, but no data from \(url)")
                    return
                }
                guard let json = try? JSONSerialization.jsonObject(with: data) as! [String: AnyObject] else {
                    self?.state = .failure(reason: "Certificate didn't return valid JSON data from \(url)")
                    return
                }
                
                guard let revokedAssertions = json["revokedAssertions"] as? Array<[String: String]> else {
                    self?.state = .failure(reason: "Couldn't parse revoked assertions")
                    return
                }
                
                for ra in revokedAssertions {
                    let id = ra["id"]
                    let reason = ra["revocationReason"]
                    if id == self?.certificate.assertion.uid {
                        self?.state = .failure(reason: "Certificate has been revoked by issuer. Revoked assertion uid is \(id!) and reason is \(reason!)")
                        return
                    }
                }
            
                // Success
                self?.state = .success
            }
            request.resume()
        } else {
            guard let revocationKey = self.revocationKey else {
                // We don't have a revocation key, so this certifiate can't be revoked. Succeed and move on.
                state = .success
                return
            }
            let batchRevoked : Bool = revokedAddresses?.contains(revocationKey) ?? false
            if batchRevoked {
                self.state = .failure(reason: "Certificate Batch has been revoked by issuer. Revocation key is \(revocationKey)")
                return
            }
            if self.certificate.recipient.revocationAddress != nil {
                let certificateRevoked : Bool = (revokedAddresses?.contains(self.certificate.recipient.revocationAddress!))!
                if certificateRevoked {
                    self.state = .failure(reason: "Certificate has been revoked by issuer. Revocation key is \(self.certificate.recipient.revocationAddress!)")
                    return
                }
            }
            // Success
            state = .success
        }
    }
    
    func checkMerkleRoot() {
        // TODO: here and everywhere affected
        // Would like "version is after 1.1". Perhaps via comparator support on the version enum
        guard certificate.version > .oneDotOne else {
            state = .failure(reason: "Invalid state. Shouldn't need to check merkle root for this version of the cert format")
            return
        }
        
        // compare merkleRoot to blockchain
        guard let merkleRoot = certificate.receipt?.merkleRoot,
            let remoteHash = self.remoteHash else {
                state = .failure(reason: "Can't compare hashes: at least one hash is still nil")
                return
        }
        
        guard merkleRoot == remoteHash else {
            state = .failure(reason: "MerkleRoot does not match remote hash:\n Merkle:\(merkleRoot)\nRemote:\(remoteHash)")
            return
        }
        
        state = .checkingReceipt
    }
    
    func checkReceipt() {
        guard certificate.version > .oneDotOne else {
            state = .failure(reason: "Invalid state. Shouldn't need to check receipt for this version of the cert format")
            return
        }
        
        let isReceiptValid = ReceiptVerifier().validate(receipt: certificate.receipt!, chain: chain)
        guard isReceiptValid else {
            state = .failure(reason: "Invalid Merkle Receipt:\n Receipt\(certificate.receipt!)")
            return
        }
        state = .checkingIssuerSignature
    }
}

/// This is a simplified adaptation of the getDataToHash function from
/// https://github.com/digitalbazaar/jsonld-signatures. 
/// This function prefixes the normalized json-ld with optional headers. Blockcerts only uses the 
/// created date header for now.
private func getDataToHash(input: String, date: String) -> String {
    let toHash = "http://purl.org/dc/elements/1.1/created: " + date + "\n" + input
    return toHash
}

// MARK: helper functions
func sha256(data : Data) -> Data {
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0, CC_LONG(data.count), &hash)
    }
    return Data(bytes: hash)
}
