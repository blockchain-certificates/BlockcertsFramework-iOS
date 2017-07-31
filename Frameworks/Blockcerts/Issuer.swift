//
//  Issuer.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation


/// Basic protocol, common to all Issuers
public protocol IssuerProtocol {
    /// What Issuer data version this issuer is using.
    var version : IssuerVersion { get }
    // MARK: - Properties
    // MARK: Required properties
    /// The name of the issuer.
    var name : String { get }
    
    /// The email address where you can contact the issuer
    var email : String { get }
    
    /// Image data for the issuer. This can be used to populate a UIImage object
    var image : Data { get }
    
    /// Unique identifier for an Issuer. Also, the URL where you can re-request data. This is useful if an instance of this struct only has partial data, or if you want to see that the keys are still valid.
    var id : URL { get }
    
    /// This defines how the recipient shoudl introduce to the issuer. It replaces `introductionURL`
    var introductionMethod : IssuerIntroductionMethod { get }
}

/// Issuer version. Used for parsing; data model is the same
/// - one: This is a v1 issuer
/// - twoAlpha: This is a pre-relase v2 issuer
/// - two: This is a v2 issuer
public enum IssuerVersion : Int {
    // Note, these should always be listed in increasing issuer version order
    case one = 1
    case twoAlpha
    case two
}

public enum IssuerIntroductionMethod {
    case unknown
    case basic(introductionURL: URL)
    case webAuthentication(introductionURL: URL, successURL: URL, errorURL: URL)
}
