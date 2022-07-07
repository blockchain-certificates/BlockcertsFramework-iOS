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
/// - three: This is a v3 certificate
public enum CertificateVersion : Int {
    // Note, these should always be listed in increasing certificate version order
    case oneDotOne = 1
    case oneDotTwo
    case twoAlpha
    case two
    case three
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
    
    /// This function retrieves the Blockcerts version from the JSON-LD @context value
    public static func getBlockcertsVersion (data: Data) throws -> String {
        let jsonObject = try deserializeJson(from: data)
        
        if (CertificateParser.isV1_1(json: jsonObject)) {
            return "v1.1"
        }
        
        let context = jsonObject["@context"]
        var contextArray: [String] = []
        
        if context is Array<Any> {
            contextArray = context as! [String]
        } else {
            contextArray.append(context as! String)
        }
        
        let blockcertsContextURL = filterBlockcertsContext(contextArray: contextArray)
        
        if let blockcertsVersion = try getBlockcertsVersionNumber(url: blockcertsContextURL) as String? {
            return "v" + blockcertsVersion
        }
        
        return "invalid Blockcerts version"
    }
    
    /// This function returns whether or not a Blockcerts document is of version 1.1
    private static func isV1_1 (json: [String: AnyObject]) -> Bool {
        return json["certificate"] != nil
            && json["assertion"] != nil
            && json["verify"] != nil
            && json["recipient"] != nil
            && json["signature"] != nil
            && json["@context"] == nil
    }
    
    /// This is the most general parse function. Pass it a data object representing the certificate, and it will
    /// auto-detect which version of the Certificate format to use. It will always use the latest version that
    /// passes a valid parse
    ///
    /// - parameter data: A Data-representation of the Certificate. Usually, this is a JSON object.
    ///
    /// - returns: A certificate if the provided data passes any known version of the Certificate format. Nil otherwise.
    public static func parse(data: Data) throws -> Certificate? {
        let certificateVersion: String = try getBlockcertsVersion(data: data)
        switch certificateVersion {
        case "v1.1":
            return try CertificateV1_1(data: data)
        case "v1", "v1.2":
            return try CertificateV1_2(data: data)
        case "v2", "v2.0", "v2.1":
            return try CertificateV2(data: data)
        case "v2.0-alpha":
            return try CertificateV2Alpha(data: data)
        case "v3", "v3.0":
            return try CertificateV3(data: data)
        default:
            return nil
        }
        
        // return try CertificateParser.parse(data: data, withMinimumVersion: .oneDotOne)
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
        case .three:
            return try CertificateV3(data: data)
        case .two:
            return try CertificateV2(data: data)
        case .twoAlpha:
            return try CertificateV2Alpha(data: data)
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
            fallthrough
        case .three:
            if cert == nil {
                do {
                    cert = try CertificateV3(data: data)
                } catch {
                    cert = nil
                    lastError = error
                }
            }
            fallthrough
            
        // After testing all final versions, Try some alpha versions.
        case .twoAlpha:
            if cert == nil {
                do {
                    cert = try CertificateV2Alpha(data: data)
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
    
    /// Link to a JSON that details the issuer's issuing and recovation keys.
    var id : String { get }
    
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

    public func getDebugDescription() -> String {
        return "version: \(version) " +
                "title: \(title) " +
                "subtitle: \(subtitle) " +
                "description: \(description) " +
                "language: \(language) " +
                "id: \(id) " +
                "signature: \(signature) " +
                "issuer: \(issuer) " +
                "recipient: \(recipient) " +
                "verifyData: \(verifyData) " +
                "receipt: \(receipt) " +
                "metadata: \(metadata) " +
                "shareUrl: \(shareUrl)"
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

func deserializeJson(from data: Data) throws -> [String: AnyObject] {
    do {
        return try JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
    } catch {
        throw CertificateParserError.notValidJSON
    }
}

func stringContainsBlockcerts (string string: String) -> Bool {
    return string.range(of: "blockcerts") != nil
}

func filterBlockcertsContext(contextArray contextArray: [String]) -> String {
    if let blockcertsMatches = contextArray.filter({ (item: String) -> Bool in
        return stringContainsBlockcerts(string: item)
    }) as? [String] {
        return blockcertsMatches[0]
    }
    
    return ""
}

func getBlockcertsVersionNumber(url blockcertsUrl: String) throws -> String {
    let regex = try NSRegularExpression(pattern: "(?:blockcerts)/(?:schema)?/?v?([1-9]+.?[0-9]*(-alpha)?)", options: NSRegularExpression.Options.caseInsensitive)
    if let version = regex.firstMatch(in: blockcertsUrl, options: [], range: NSRange(location: 0, length: blockcertsUrl.utf16.count)) {
        return String(blockcertsUrl[Range(version.range(at: 1), in: blockcertsUrl)!])
    }
    
    return ""
}
