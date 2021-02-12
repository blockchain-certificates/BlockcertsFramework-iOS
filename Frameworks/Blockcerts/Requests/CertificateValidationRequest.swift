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
//Step 4 of 5... Checking authenticity [PASS]
//Step 5 of 5... Checking not revoked by issuer [PASS]
//Success! The certificate has been verified.
public indirect enum ValidationState {
    case notStarted
    case assertingChain
    case computingLocalHash, fetchingRemoteHash, comparingHashes, checkingIssuerSignature, checkingRevokedStatus, checkingExpiration
    case success
    case failure(reason : String, state: ValidationState)
    // these are v1.2
    case checkingReceipt, checkingMerkleRoot
    // this is v2.0+
    case checkingAuthenticity
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
    var completionHandler : ((Bool, String?, ValidationState?) -> Void)?
    public weak var delegate : CertificateValidationRequestDelegate?
    let chain : BitcoinChain

    public var state = ValidationState.notStarted {
        didSet {
            // Notify the delegate
            delegate?.certificateValidationStateChanged(from: oldValue, to: state)

            // Perform the action associated with the new state
            switch state {
            case .notStarted:
                break
            case .success:
                completionHandler?(true, nil, nil)
            case .failure(let reason, let state):
                completionHandler?(false, reason, state)
            case .assertingChain:
                assertChain()
            case .computingLocalHash:
                computeLocalHash()
            case .fetchingRemoteHash:
                fetchRemoteHash()
            case .comparingHashes:
                compareHashes()
            case .checkingIssuerSignature:
                checkIssuerSignature()
            case .checkingRevokedStatus:
                checkRevokedStatus()
            case .checkingMerkleRoot:
                checkMerkleRoot()
            case .checkingReceipt:
                checkReceipt()
            case .checkingAuthenticity:
                checkAuthenticity()
            case .checkingExpiration:
                checkExpiration()
            }
        }
    }

    // Private state built up over the validation sequence
    var localHash : String?
    var remoteHash : String?
    private var revocationKey : BlockchainAddress?
    private var revokedAddresses : Set<BlockchainAddress>?
    var normalizedCertificate : String?
    var txDate : Date?
    var signingPublicKey : BlockchainAddress?
    var expiresDate : Date?

    public init(for certificate: Certificate,
         with transactionId: String,
         bitcoinManager: BitcoinManager,
         chain: BitcoinChain = .mainnet,
         starting : Bool = false,
         jsonld : JSONLDProcessor = JSONLD.shared,
         session : URLSessionProtocol = URLSession.shared,
         completionHandler: ((Bool, String?, ValidationState?) -> Void)? = nil) {
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
                     chain: BitcoinChain = .mainnet,
                     starting : Bool = false,
                     jsonld : JSONLDProcessor = JSONLD.shared,
                     session: URLSessionProtocol = URLSession.shared,
                     completionHandler: ((Bool, String?, ValidationState?) -> Void)? = nil) {
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

    private func fail(reason: String) {
        state = ValidationState.failure(reason: reason, state: state)
    }

    public func start() {
        state = .assertingChain
    }

    public func abort() {
        fail(reason: "Aborted")
    }


    internal func assertChain() {
        guard chain == .mainnet else {
            // We only need to assert mainnet if the chain is set to mainnet. If it's any other value, then we can't be held responsible for how you're validating.
            state = .computingLocalHash
            return
        }

        var targetChain : BitcoinChain? = nil

        if let chainForIssuer = getChainForIssuer(certificate) {
            targetChain = chainForIssuer
        } else if let chainForRecipient = getChainForRecipient(certificate) {
            targetChain = chainForRecipient
        }

        switch targetChain {
        case .some(.testnet):
            fail(reason: "This is a testnet certificate. It cannot be validated.")
        case .none:
            fail(reason: "This certificate is from an unknown blockchain and cannot be validated.")
        case .some(.mainnet):
            // This is successful. yaaay
            break;
        }

        state = .computingLocalHash
    }

    private func getChainForIssuer(_ certificate: Certificate) -> BitcoinChain? {
        guard let issuerAddress = certificate.verifyData.publicKey else {
            return nil
        }

        return chain(for: issuerAddress)
    }

    private func getChainForRecipient(_ certificate: Certificate) -> BitcoinChain? {
        return chain(for: certificate.recipient.publicAddress)
    }

    private func chain(for address: BlockchainAddress?) -> BitcoinChain? {
        if let address = address {
            // All mainnet addresses start with 1.
            if address.value.hasPrefix("1") {
                return .mainnet
            }

            if address.value.hasPrefix("m") || address.value.hasPrefix("n") {
                return .testnet
            }
        }

        return nil
    }

    internal func computeLocalHash() {
        if certificate.version == .oneDotOne {
            self.localHash = hexStringFrom(data: sha256(data: certificate.file))
            state = .fetchingRemoteHash
        } else if certificate.version == .oneDotTwo {
            let docData : Data!
            do {
                let json = try JSONSerialization.jsonObject(with: certificate.file, options: []) as! [String: Any]
                let document = json["document"] as! [String: Any]
                docData = try JSONSerialization.data(withJSONObject: document, options: [])
            } catch {
                fail(reason: "Failed to re-parse the document node out of the certificate's file.")
                return
            }

            jsonld.normalize(docData: docData, callback: { (error, resultString) in
                guard error == nil else {
                    self.fail(reason: "Failed JSON-LD compact with \(error!)")
                    return
                }
                guard let resultString = resultString else {
                    self.fail(reason: "There's no error, but the resultData is nil.")
                    return
                }
                guard let stringData = resultString.data(using: .utf8) else {
                    self.fail(reason: "Result could not be translated into raw data: \(resultString)")
                    return
                }

                self.localHash = hexStringFrom(data: sha256(data: stringData))

                self.state = .fetchingRemoteHash
            })
        } else {
            let docData : Data!
            do {
                var json = try JSONSerialization.jsonObject(with: certificate.file, options: []) as! [String: Any]
                json.removeValue(forKey: "signature")
                docData = try JSONSerialization.data(withJSONObject: json, options: [])
            } catch {
                fail(reason: "Failed to re-parse the document node out of the certificate's file.")
                return
            }

            jsonld.normalize(docData: docData, callback: { (error, resultString) in
                guard error == nil else {
                    self.fail(reason: "Failed JSON-LD compact with \(error!)")
                    return
                }
                guard let resultString = resultString else {
                    self.fail(reason: "There's no error, but the resultData is nil.")
                    return
                }
                guard let stringData = resultString.data(using: .utf8) else {
                    self.fail(reason: "Result could not be translated into raw data: \(resultString)")
                    return
                }

                self.normalizedCertificate = resultString

                self.localHash = hexStringFrom(data: sha256(data: stringData))

                self.state = .fetchingRemoteHash
            })

        }
    }

    internal func fetchRemoteHash() {
        let transactionDataHandler = TransactionDataHandler.create(chain: self.chain, transactionId: transactionId)

        guard let transactionUrl = URL(string: transactionDataHandler.transactionUrlAsString!) else {
            fail(reason: "Transaction ID (\(transactionId)) is invalid")
            return
        }
        let task = session.dataTask(with: transactionUrl) { [weak self] (data, response : URLResponse?, _) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                self?.fail(reason: "Got invalid response from \(transactionUrl)")
                return
            }
            guard let data = data else {
                self?.fail(reason: "Got a valid response, but no data from \(transactionUrl)")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject] else {
                self?.fail(reason: "Transaction didn't return valid JSON data from \(transactionUrl)")
                return
            }

            // Let's parse the OP_RETURN value out of the data.
            transactionDataHandler.parseResponse(json: json!)
            guard let transactionData = transactionDataHandler.transactionData else {
                self?.fail(reason: transactionDataHandler.failureReason ?? "Undeclared")
                return
            }

            var possibleRemoteHash = transactionData.opReturnScript

            // Some providers prepend
            let opReturnPrefix = "6a20"
            if let remoteHash = possibleRemoteHash,
                remoteHash.hasPrefix(opReturnPrefix) {
                let startIndex = remoteHash.index(remoteHash.startIndex, offsetBy: opReturnPrefix.count)
                possibleRemoteHash = String(remoteHash[startIndex...])
            }

            self?.remoteHash = possibleRemoteHash
            self?.revokedAddresses = transactionData.revokedAddresses
            self?.txDate = transactionData.txDate
            self?.signingPublicKey = transactionData.signingPublicKey

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
                fail(reason: "Can't compare hashes: one of the hashes is still nil")
                return
        }

        guard localHash == correctHashResult else {
            fail(reason: "Local hash doesn't match remote hash:\n Local:\(localHash)\nRemote:\(correctHashResult)")
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
                    self?.fail(reason: "Got invalid response from \(url)")
                    return
            }
            guard let data = data else {
                self?.fail(reason: "Got a valid response, but no data from \(url)")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as! [String: AnyObject] else {
                self?.fail(reason: "Certificate didn't return valid JSON data from \(url)")
                return
            }

            let chain = self?.chain ?? .mainnet
            guard let bitcoinManager = self?.bitcoinManager else {
                self?.fail(reason: "Incorrect configuration. ValidationRequest needs to have a bitcoin manager specified.")
                return
            }
            guard (self?.certificate) != nil else {
                self?.fail(reason: "Certificate is missing.")
                return
            }

            guard let signature = self?.certificate.signature else {
                self?.fail(reason: "Signature is missing")
                return
            }

            guard let issuerKeys = json["issuerKeys"] as? [[String : String]],
                let revocationKeys = json["revocationKeys"] as? [[String : String]] else {
                    self?.fail(reason: "Couldn't parse issuerKeys or revocationKeys from json: \n\(json)")
                    return
            }
            guard let revokeKey = revocationKeys.first?["key"] else {
                    self?.fail(reason: "Couldn't parse first revokeKey")
                    return
            }
            self?.revocationKey = BlockchainAddress(string: revokeKey)
            guard let issuerKey = issuerKeys.first?["key"] else {
                self?.fail(reason: "Couldn't parse issuerKey")
                return
            }
            guard let message = self?.certificate.assertion.uid else {
                self?.fail(reason: "Couldn't parse message")
                return
            }

            let address = bitcoinManager.address(for: message, with: signature, on: chain)

            guard address == issuerKey else {
                self?.fail(reason: "Issuer key doesn't match derived address:\n Address:\(address!)\n issuerKey:\(issuerKey)")
                return
            }


            self?.state = .checkingRevokedStatus
        }
        request.resume()
    }

    internal func checkRevokedStatus() {
        if certificate.version == .twoAlpha {
            guard let concreteIssuer = certificate.issuer as? IssuerV2Alpha,
                let url = concreteIssuer.revocationURL else {
                // Issuer does not revoke certificates
                // Success
                self.state = .checkingExpiration
                return
            }
            let request = session.dataTask(with: url) { [weak self] (data, response, error) in
                guard let response = response as? HTTPURLResponse,
                    response.statusCode == 200 else {
                        self?.fail(reason: "Got invalid response from \(url)")
                        return
                }
                guard let data = data else {
                    self?.fail(reason: "Got a valid response, but no data from \(url)")
                    return
                }
                guard let json = try? JSONSerialization.jsonObject(with: data) as! [String: AnyObject] else {
                    self?.fail(reason: "Certificate didn't return valid JSON data from \(url)")
                    return
                }

                guard let revokedAssertions = json["revokedAssertions"] as? Array<[String: String]> else {
                    self?.fail(reason: "Couldn't parse revoked assertions")
                    return
                }

                print("mathing \(String(describing: self?.certificate.id))?")
                for ra in revokedAssertions {
                    guard let id = ra["id"] else {
                        self?.fail(reason: "Couldn't parse revoked assertions")
                        return
                    }
                    let reason = ra["revocationReason"]
                    print("id: \(id), reason: \(String(describing:reason))")
                    if id == self?.certificate.id {
                        self?.fail(reason: "Certificate has been revoked by issuer. Revoked assertion id is \(id) and reason is \(reason!)")
                        return
                    }
                }

                // Success
                self?.state = .checkingExpiration
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
                self.fail(reason: "Certificate Batch has been revoked by issuer. Revocation key is \(revocationKey)")
                return
            }
            if let recipientRevocationAddress = self.certificate.recipient.revocationAddress {
                let certificateRevoked : Bool = (revokedAddresses?.contains(recipientRevocationAddress))!
                if certificateRevoked {
                    self.fail(reason: "Certificate has been revoked by issuer. Revocation key is \(self.certificate.recipient.revocationAddress!)")
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
            fail(reason: "Invalid state. Shouldn't need to check merkle root for this version of the cert format")
            return
        }

        // compare merkleRoot to blockchain
        guard let merkleRoot = certificate.receipt?.merkleRoot,
            let remoteHash = self.remoteHash else {
                fail(reason: "Can't compare hashes: at least one hash is still nil")
                return
        }

        guard merkleRoot == remoteHash else {
            fail(reason: "MerkleRoot does not match remote hash:\n Merkle:\(merkleRoot)\nRemote:\(remoteHash)")
            return
        }

        state = .checkingReceipt
    }

    func checkReceipt() {
        guard certificate.version > .oneDotOne else {
            fail(reason: "Invalid state. Shouldn't need to check receipt for this version of the cert format")
            return
        }

        let isReceiptValid = ReceiptVerifier().validate(receipt: certificate.receipt!, chain: chain)
        guard isReceiptValid else {
            fail(reason: "Invalid Merkle Receipt:\n Receipt\(certificate.receipt!)")
            return
        }
        if certificate.version == .oneDotTwo {
            state = .checkingIssuerSignature
        } else {
            state = .checkingAuthenticity
        }
    }

    internal func checkAuthenticity() {
        let url = certificate.issuer.id
        let request = session.dataTask(with: certificate.issuer.id) { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                    self?.fail(reason: "Got invalid response from \(url)")
                    return
            }
            guard let data = data else {
                self?.fail(reason: "Got a valid response, but no data from \(url)")
                return
            }
            guard let issuer = IssuerParser.decode(data: data) else {
                self?.fail(reason: "Issuer didn't return valid JSON data from \(url)")
                return
            }
            guard (self?.certificate) != nil else {
                self?.fail(reason: "Certificate is missing.")
                return
            }
            guard let signingKey = self?.signingPublicKey else {
                self?.fail(reason: "Couldn't parse determine transaction signing public key.")
                return
            }
            guard let txDate = self?.txDate else {
                self?.fail(reason: "Couldn't parse determine transaction date.")
                return
            }

            let matchingKeyInfo = issuer.publicKeys.first(where: { (keyRotation) -> Bool in
                keyRotation.key == signingKey
            })

            guard let keyInfo = matchingKeyInfo else {
                self?.fail(reason: "Couldn't find issuer public key.")
                return
            }

            if txDate < keyInfo.on {
                self?.fail(reason: "Transaction was issued before Issuer's created date for this key.")
                return
            }
            if let revoked = keyInfo.revoked {
                if txDate > revoked {
                    self?.fail(reason: "Transaction was issued after Issuer revoked the key.")
                    return
                }
            }

            // expiration will be checked later if date exists
            self?.expiresDate = keyInfo.expires

            self?.state = .checkingRevokedStatus
        }
        request.resume()
    }

    internal func checkExpiration() {
        guard let expiresDate = expiresDate else {
            state = .success
            return
        }
        guard let txDate = txDate else {
            fail(reason: "Couldn't parse determine transaction date.")
            return
        }
        if txDate > expiresDate {
            fail(reason: "Transaction was issued after the Issuer key expired.")
            return
        }
        if Date() > expiresDate {
            fail(reason: "The Issuer key has expired.")
            return
        }
        state = .success
    }
}


// MARK: helper functions
func sha256(data : Data) -> Data {
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0, CC_LONG(data.count), &hash)
    }
    return Data(bytes: hash)
}

func hexStringFrom(data: Data) -> String {
    var hexString = ""
    for byte in data {
        hexString += String(format: "%02x", byte)
    }

    return hexString
}

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}
