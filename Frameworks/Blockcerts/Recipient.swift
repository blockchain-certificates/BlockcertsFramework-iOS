//
//  Recipient.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// This represents who a certificate is issued to. It also more abstractly represents the user, but they may choose to use different names with differing institutions.
public struct Recipient {
    
    /// The recipient's name.
    public let name : String
    
    /// A unique string identifying the recipient. Currently, only an email address is supported
    public let identity : String
    
    /// Signifies what type of data exists in the `identity` property. Currently, `"email"` is the only valid value.
    public let identityType : String
    
    /// Describes if the value in the identity field is hashed or not. Default is false, indicating that the identity is not hashed.
    public let isHashed : Bool
    
    /// Bitcoin address (compressed public key, usually 24 characters) of the recipient.
    public let publicAddress : BlockchainAddress
    
    /// Issuer's recipient-specific revocation Bitcoin address (compressed public key, usually 24 characters).
    public let revocationAddress : BlockchainAddress?
    
    public init(name: String, identity: String, identityType: String, isHashed: Bool, publicAddress: BlockchainAddress, revocationAddress: BlockchainAddress? = nil) {
        self.name = name
        self.identity = identity
        self.identityType = identityType
        self.isHashed = isHashed
        self.publicAddress = publicAddress
        self.revocationAddress = revocationAddress
        
        // Backcompat to allow givenName and familyName to be non-null
        let fullNameArr = name.components(separatedBy: " ")
        let componentCount = fullNameArr.count
        if componentCount == 0 {
            // This shouldn't happen, but do something sane
            self.givenName = name
            self.familyName = "" // backcompat: must be non-null
        } else {
            self.givenName = fullNameArr[0]
            if componentCount == 1 {
                self.familyName = "" // backcompat: must be non-null
            } else if fullNameArr.count == 2 {
                self.familyName = fullNameArr[1]
            } else {
                // This could happen, so take a sane guess. But we've deprecated givenName and familyName.
                let subarray = fullNameArr[1...fullNameArr.count-1]
                self.familyName = subarray.joined(separator: " ")
            }
        }
    }
    
    
    
    //
    // MARK: - Old properties & initializers for pre-v2.0 certificates
    //

    private var deprecatedGivenName : String?
    public var givenName : String {
        set {
            debugPrint("Warning: `Recipient.givenName` is deprecated. Use `Recipient.name instead")
            deprecatedGivenName = newValue
        }
        get {
            debugPrint("Warning: `Recipient.givenName` is deprecated. Use `Recipient.name instead")
            return deprecatedGivenName ?? ""
        }
    }
    
    private var deprecatedFamilyName : String?
    public var familyName : String {
        set {
            debugPrint("Warning: `Recipient.familyName` is deprecated. Use `Recipient.name instead")
            deprecatedFamilyName = newValue
        }
        get {
            debugPrint("Warning: `Recipient.familyName` is deprecated. Use `Recipient.name instead")
            return deprecatedFamilyName ?? ""
        }
    }

    public init(name: String, identity: String, identityType: String, isHashed: Bool, publicAddress: String, revocationAddress: String? = nil) {
        var revokeKey : BlockchainAddress? = nil
        if let address = revocationAddress {
            revokeKey = BlockchainAddress(string: address)
        }
        self.init(name: name, identity: identity, identityType: identityType, isHashed: isHashed, publicAddress: BlockchainAddress(string: publicAddress), revocationAddress: revokeKey)
    }
    
    public init(givenName: String, familyName: String, identity: String, identityType: String, isHashed: Bool, publicAddress: String, revocationAddress: String? = nil) {
        self.deprecatedGivenName = givenName
        self.deprecatedFamilyName = familyName
        self.identity = identity
        self.identityType = identityType
        self.isHashed = isHashed
        self.publicAddress = BlockchainAddress(string: publicAddress)
        if let address = revocationAddress {
            self.revocationAddress = BlockchainAddress(string: address)
        } else {
            self.revocationAddress = nil
        }
        self.name = "\(givenName) \(familyName)"
    }
}
