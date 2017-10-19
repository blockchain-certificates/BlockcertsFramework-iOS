//
//  IssuerIssuingEstimateRequest.swift
//  Blockcerts
//
//  Created by Chris Downie on 10/19/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

public enum IssuerIssuingEstimateResult : Error {
    case aborted
    case errored(message : String)
    case success(estimates: [CertificateIssuingEstimate])
}

public struct CertificateIssuingEstimate : Codable {
    let title : String
    let willIssueOn: Date
}

public class IssuerIssuingEstimateRequest : CommonRequest {
    let recipientKey : String
    let callback : ((IssuerIssuingEstimateResult) -> Void)
    let session : URLSessionProtocol
    let issuer: IssuingEstimateSupport
    
    public init(from issuer: IssuingEstimateSupport, with key: String, session: URLSessionProtocol = URLSession.shared, callback: @escaping (IssuerIssuingEstimateResult) -> Void) {
        recipientKey = key
        self.callback = callback
        self.session = session
        self.issuer = issuer
    }
    
    public func start() {
        fatalError("Not Implemented")
    }
    
    public func abort() {
        fatalError("Not Implemented")
    }
}
