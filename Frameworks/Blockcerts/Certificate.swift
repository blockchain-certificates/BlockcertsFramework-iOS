//
//  Certificate.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

/// These are versions of the CertificateFormat that the CertificateParser understands. It will also be prsent on the resulting Certificate object
///
/// - oneDotOne: This is a v1.1 certificate
/// - oneDotTwo: This is a v1.2 certificate
/// - two: This is a v2 certificate
public enum CertificateVersion : Int {
    // Note, these should always be listed in increasing certificate version order
    case oneDotOne = 1
    case oneDotTwo
    case two
}

/// Make CertificateVersion support < or > comparisons
extension CertificateVersion : Comparable {}
public func <(lhs: CertificateVersion, rhs: CertificateVersion) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

/// These are the errors that can be thrown during parsing:

///
/// - notImplemented:      This particular version of the parser hasn't been implemented. It's possible you're using the protocol directly rather than a concrete subclass.
/// - genericError:        Something has gone wrong and I don't know exactly what
///
/// - notValidJSON:        We were expecting JSON data, but it didn't pass deserialization
/// - notSigned:           This certificate isn't signed, and this certificate format version only validates signed certificates.
/// - jsonLDError:         Problem in conforming to JSON LD format. http://json-ld.org
/// - missingData:         A particular property was missing in the JSON data.
/// - invalidData:         A property's value is invalid. For instance, a normal string when a URL should be present.
public enum CertificateParserError : Error {
    case notImplemented
    case genericError
    case notValidJSON
    case notSigned
    case jsonLDError(description: String)
    case missingData(description: String)
    case invalidData(description: String)
}

/// CertificateParser should never be instantiated. Call one of its `parse` methods to turn a Data object into a Certificate.
public enum CertificateParser {
    /// This is the most general parse function. Pass it a data object representing the certificate, and it will
    /// auto-detect which version of the Certificate format to use. It will always use the latest version that
    /// passes a valid parse
    ///
    /// - parameter data: A Data-representation of the Certificate. Usually, this is a JSON object.
    ///
    /// - returns: A certificate if the provided data passes any known version of the Certificate format. Nil otherwise.
    public static func parse(data: Data) throws -> Certificate {
        return try CertificateParser.parse(data: data, withMinimumVersion: .oneDotOne)
    }
    
    /// This parses a data object as a specific version of the certificate format. Useful if you're expecting a 1.2
    /// certificate, and you'd like the parse to fail if it only finds a v1.1 certificate
    ///
    /// - parameter data:    A Data-representation of the Certificate. Usually, this is a JSON object
    /// - parameter version: Which version to parse the `data` parameter as.
    ///
    /// - returns: A Certificate if `data` is a valid Certificate at the specified version. Nil otherwise.
    public static func parse(data: Data, asVersion version: CertificateVersion) throws -> Certificate {
        switch version {
        case .two:
            return try CertificateV2(data: data)
        case .oneDotTwo:
            return try CertificateV1_2(data: data)
        case .oneDotOne:
            return try CertificateV1_1(data: data)
        }
    }
    
    /// Parses a data object with a minimum certificate version. T his is the most future-compatible parse. If you
    /// want to rely on features introduced in a specific version fo the Certificate format, this is the best way
    /// to do that.
    ///
    /// - parameter data:    A Data-representation of the Certificate. Usually, this is a JSON object
    /// - parameter version: The minimum version to parse `data` parameter as.
    ///
    /// - returns: A Certificate if `data` is a valid Certificate at the specified version or later. Nil otherwise.
    static func parse(data: Data, withMinimumVersion version: CertificateVersion) throws -> Certificate {
        var cert : Certificate?
        var lastError : Error?
        switch version {
        case .oneDotOne:
            if cert == nil {
                do {
                    cert = try CertificateV1_1(data: data)
                } catch {
                    cert = nil
                    lastError = error
                }
            }
            fallthrough
        case .oneDotTwo:
            if cert == nil {
                do {
                    cert = try CertificateV1_2(data: data)
                } catch {
                    cert = nil
                    lastError = error
                }
            }
            fallthrough
        case .two:
            if cert == nil {
                do {
                    cert = try CertificateV2(data: data)
                } catch {
                    cert = nil
                    lastError = error
                }
            }
        }
        
        if cert != nil {
            return cert!
        } else if lastError != nil {
            throw lastError!
        } else {
            throw CertificateParserError.genericError
        }
    }
}

// MARK: - Certificate Protocol definition
//
/// An abstract definition of a Certificate. Private concrete subclasses will conform to this protocol.
public protocol Certificate {
    /// Which version of the Certificate format this was parsed as.
    var version : CertificateVersion { get }
    
    
    /// Title of the certificate
    var title : String { get }
    
    /// Subtitle of the certificate. May be nil.
    var subtitle : String? { get }
    
    /// Description of what the certificate represents or certifies.
    var description: String { get }
    
    /// A base64-encoded png image of the issuer's logo. This is featured prominently in the display of the certifiate.
    var image : Data { get }
    
    /// Represents the IETF language and IETF country codes.
    var language : String { get }
    
    /// A string that uniquely identifies the certificate. May be a GUID (matching `universalIdentifier`) or a URL matching `shareUrl`.
    var id : String { get }
    
    /// A GUID that uniquely identifies the certificate.
    var universalIdentifier : String { get }
    
    /// The raw, unedited file representation of the certificate.
    var file : Data { get }
    
    /// String of signature created when the Bitcoin private key signs the value in the attribute-signed field.
    var signature : String? { get }

    /// Represents the entity that issued this certifiate. See `Issuer` for more details
    var issuer : Issuer { get }
    
    /// Represents the entity this certificate was issued to. See `Recipient` for more details
    var recipient : Recipient { get }
    
    /// Represents the assertion made by this certificate. See `Assertion` for more details
    var assertion : Assertion { get }
    
    /// Represents data needed to verify this certificate. See `Verify` for more details
    var verifyData : Verify { get }
    
    /// Represents any reciept data to help verify the certificate. See `Reciept` for more details
    var receipt : Receipt? { get }
    
    /// Contains all the metadata associated with the certificate. See `Metadata` for more details
    var metadata : Metadata { get }
    
    /// An optional display of this certificate in raw HTML.
    var htmlDisplay : String? { get }
    
    /// If present, the hosted URL that can be used to share this certificate.
    var shareUrl : URL? { get }
}


extension Certificate {
    /// Initialize from JSON object. This is an internal extension to the protocol, since we don't want folks
    /// initializing concrete instances of specific versions. They should use the CertificateParser instead.
    ///
    /// - Parameter data: A Data object that should deserialize as JSON
    /// - Throws: CertificateParserErrors
    init(data: Data) throws {
        throw CertificateParserError.notImplemented
    }
    
    var htmlDisplay : String? {
        return nil
    }
}

// These are useful parsing functions that are version-independent.
func imageData(from dataURI: String?) -> Data {
    guard let dataUri = dataURI, // Make sure dataURI isn't empty
        let imageUrl = URL(string: dataUri), // Make sure it's a valid URI. If this fails, it probably didn't start with `data:`
        let data = try? Data(contentsOf: imageUrl) else {
        return Data()
    }
    return data
}

