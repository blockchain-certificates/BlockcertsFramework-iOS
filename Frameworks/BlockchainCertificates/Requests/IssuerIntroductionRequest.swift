//
//  IssuerIntroductionRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/2/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

public enum IssuerIntroductionRequestError : Error {
    case aborted
    case issuerMissingIntroductionURL
    case cannotSerializePostData
    case genericErrorFromServer(error: Error?)
    case errorResponseFromServer(response: HTTPURLResponse)
}

public protocol IssuerIntroductionRequestDelegate : class {
    func introductionURL(for issuer: Issuer, introducing recipient: Recipient) -> URL?
    func postData(for issuer: Issuer, from recipient: Recipient) -> [String: Any]
}

public extension IssuerIntroductionRequestDelegate {
    func introductionURL(for issuer: Issuer, introducing recipient: Recipient) -> URL? {
        return issuer.introductionURL
    }
    
    public func postData(for issuer: Issuer, from recipient: Recipient) -> [String: Any] {
        var dataMap = [String: Any]()
        dataMap["email"] = recipient.identity
        dataMap["firstName"] = recipient.givenName
        dataMap["lastName"] = recipient.familyName
        return dataMap
    }
}

private class DefaultDelegate : IssuerIntroductionRequestDelegate {
    
}

public class IssuerIntroductionRequest : CommonRequest {
    public var callback : ((IssuerIntroductionRequestError?) -> Void)?
    public var delegate : IssuerIntroductionRequestDelegate
    
    private var recipient : Recipient
    private var session : URLSessionProtocol
    private var currentTask : URLSessionDataTaskProtocol?
    private var issuer : Issuer
    
    public init(introduce recipient: Recipient, to issuer: Issuer, session: URLSessionProtocol = URLSession.shared, callback: ((IssuerIntroductionRequestError?) -> Void)?) {
        self.callback = callback
        self.session = session
        self.recipient = recipient
        self.issuer = issuer
        
        delegate = DefaultDelegate()
    }
    
    public func start() {
        guard let url = delegate.introductionURL(for: issuer, introducing: recipient) else {
            reportFailure(.issuerMissingIntroductionURL)
            return
        }
        
        // Create JSON body. Start with the provided extra data parameters if they're present.
        var dataMap = delegate.postData(for: issuer, from: recipient)
        dataMap["bitcoinAddress"] = recipient.publicAddress
        
        guard let data = try? JSONSerialization.data(withJSONObject: dataMap, options: []) else {
            reportFailure(.cannotSerializePostData)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        currentTask = session.dataTask(with: request) { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                self?.reportFailure(.genericErrorFromServer(error: error))
                return
            }
            guard response.statusCode == 200 else {
                self?.reportFailure(.errorResponseFromServer(response: response))
                return
            }
            
            self?.reportSuccess()
        }
        currentTask?.resume()
    }
    
    public func abort() {
        currentTask?.cancel()
        reportFailure(.aborted)
    }
    
    private func reportFailure(_ reason: IssuerIntroductionRequestError) {
        callback?(reason)
        callback = nil
    }
    
    private func reportSuccess() {
        callback?(nil)
        callback = nil
    }
}
