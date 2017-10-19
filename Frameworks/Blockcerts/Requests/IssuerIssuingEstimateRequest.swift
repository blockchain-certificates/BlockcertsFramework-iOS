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
    public let recipientKey : String
    public let callback : ((IssuerIssuingEstimateResult) -> Void)
    public let issuer: IssuingEstimateSupport
    
    private let session : URLSessionProtocol
    private var currentTask : URLSessionDataTaskProtocol?
    
    public init(from issuer: IssuingEstimateSupport, with key: String, session: URLSessionProtocol = URLSession.shared, callback: @escaping (IssuerIssuingEstimateResult) -> Void) {
        recipientKey = key
        self.callback = callback
        self.session = session
        self.issuer = issuer
    }
    
    public func start() {
        guard let baseURL = issuer.issuingEstimateURL else {
            callback(.errored(message: "Couldn't make the request -- the issuer is missing an issuingEstimateURL."))
            return
        }
        
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            callback(.errored(message: "Failed to convert the issuingEstimateURL into its base components."))
            return
        }
        components.queryItems = [ URLQueryItem(name: "key", value: recipientKey) ]
        guard let queryURL = components.url else {
            callback(.errored(message: "Failed to convert the query string parameters back into a URL to query."))
            return
        }
        
        currentTask = session.dataTask(with: queryURL) { [weak self] (data, response, error) in
            guard error == nil else {
                self?.callback(.errored(message: "Server responded with an error: \(error.debugDescription)"))
                return
            }
            guard let data = data else {
                self?.callback(.errored(message: "Server didn't respond with any data."))
                return
            }
            
            let decoder = JSONDecoder()
            var estimates : [CertificateIssuingEstimate] = []
            do {
                estimates = try decoder.decode(Array.self, from: data)
            } catch {
                self?.callback(.errored(message: "Failed to parse estimates out of the server response"))
                return
            }
            
            self?.callback(.success(estimates: estimates))
        }
        currentTask?.resume()
    }
    
    public func abort() {
        currentTask?.cancel()
        callback(.aborted)
    }
}
