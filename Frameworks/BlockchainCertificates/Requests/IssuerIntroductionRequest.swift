//
//  IssuerIntroductionRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/2/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

public class IssuerIntroductionRequest : CommonRequest {
    var callback : ((Bool, String?) -> Void)?
    let url : URL?
    
    private var extraJSONData : [String: Any]?
    private var recipient : Recipient
    private var session : URLSessionProtocol
    private var currentTask : URLSessionDataTaskProtocol?
    
    public init(introduce recipient: Recipient, to issuer: Issuer, with jsonData: [String : Any]? = nil, session: URLSessionProtocol = URLSession.shared, callback: ((Bool, String?) -> Void)?) {
        self.callback = callback
        self.session = session
        self.recipient = recipient
        self.extraJSONData = jsonData

        url = issuer.introductionURL
    }
    
    public func start() {
        guard let url = url else {
            reportFailure("Issuer does not have an introductionURL. Try refreshing the data.")
            return
        }
        
        // Create JSON body. Start with the provided extra data parameters if they're present.
        var dataMap = [String: Any]()
        if let extraJSONData = extraJSONData {
            dataMap = extraJSONData
        }
        
        // Required data. If this is passed in the extra data, then it's overwritten
        dataMap["bitcoinAddress"] = recipient.publicAddress
        dataMap["email"] = recipient.identity
        dataMap["firstName"] = recipient.givenName
        dataMap["lastName"] = recipient.familyName

        guard let data = try? JSONSerialization.data(withJSONObject: dataMap, options: []) else {
            reportFailure("Failed to create the body for the request.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        currentTask = session.dataTask(with: request) { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                    self?.reportFailure("Server responded with non-200 status.")
                    return
            }
            
            self?.reportSuccess()
        }
        currentTask?.resume()
    }
    
    public func abort() {
        currentTask?.cancel()
        reportFailure("Aborted")
    }
    
    private func reportFailure(_ reason: String) {
        callback?(false, reason)
        callback = nil
    }
    
    private func reportSuccess() {
        callback?(true, nil)
        callback = nil
    }
}
