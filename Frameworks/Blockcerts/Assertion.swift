//
//  Assertion.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Digital Certificates Project.
//

import Foundation

public struct SignatureImage {
    public let image : Data
    public let title : String?
}

/// This represents the assertion made by the certificate. It may contain proof (see `evidence` below) and any signatures/titles of the issuing authority
public struct Assertion {
    /// Date the the certificate JSON was created.
    public let issuedOn : Date
    
    /// An array of base-64 encoded png images, paired with a title for each signature.
    public let signatureImages : [ SignatureImage ]
    
    /// Text, uri, etc. that shows evidence of the recipient's learning that the certificate represents. Can be left as an empty string if not used.
    public let evidence : String
    
    /// Unique identifier. By default it is created using the string of a BSON ObjectId(), yielding an identifier 24 characters long.
    public let uid : String
    
    /// URI that links to the certificate on the viewer. Default is https://[domain]/[uid]
    public let id : URL
    
    public let metadata : Metadata
    
    public let htmlDisplay : String?
    
    /// Public memberwise initializer. See above documentation for an explanation of each argument
    ///
    /// - returns: an initialized Assertion object.
    public init(issuedOn: Date, signatureImage: Data, evidence: String, uid: String, id: URL, metadata: Metadata = Metadata(json: [:]), htmlDisplay: String? = nil) {
        self.issuedOn = issuedOn
        self.evidence = evidence
        self.uid = uid
        self.id = id
        self.metadata = metadata
        signatureImages = [SignatureImage(image: signatureImage, title: nil)]
        self.htmlDisplay = htmlDisplay
    }
    
    /// Public memberwise initializer.
    ///
    /// - Parameters:
    ///   - issuedOn: Date the the certificate JSON was created.
    ///   - signatureImages: An array of base-64 encoded png images, paired with a title for each signature.
    ///   - evidence: Text, uri, etc. that shows evidence of the recipient's learning that the certificate represents. Can be left as an empty string if not used.
    ///   - uid: Unique identifier. By default it is created using the string of a BSON ObjectId(), yielding an identifier 24 characters long.
    ///   - id: URI that links to the certificate on the viewer. Default is https://[domain]/[uid]
    ///   - metadata: Metadata object that contains all anscillary data associated with this certificate.
    public init(issuedOn: Date, signatureImages: [SignatureImage], evidence: String, uid: String, id: URL, metadata: Metadata = Metadata(json: [:]), htmlDisplay: String? = nil) {
        self.issuedOn = issuedOn
        self.evidence = evidence
        self.uid = uid
        self.id = id
        self.signatureImages = signatureImages
        self.metadata = metadata
        self.htmlDisplay = htmlDisplay
    }
}
