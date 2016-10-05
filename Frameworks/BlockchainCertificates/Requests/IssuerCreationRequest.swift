//
//  IssuerIntroductionRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/26/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

public class IssuerCreationRequest : CommonRequest {
    public var callback : ((Issuer?) -> Void)?
    public let url : URL
    
    private var session : URLSessionProtocol
    private var currentTask : URLSessionDataTaskProtocol?
    
    public init(id: URL, session: URLSessionProtocol = URLSession.shared, callback: ((Issuer?) -> Void)?) {
        self.callback = callback
        self.session = session
        url = id
    }
    
    public func start() {
        currentTask = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                    self?.reportFailure()
                    return
            }
            guard let data = data else {
                self?.reportFailure()
                return
            }
            
            guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonData as? [String: Any] else {
                self?.reportFailure()
                return
            }
            
            guard let issuer = Issuer(dictionary: json) else {
                self?.reportFailure()
                return
            }
            
            self?.reportSuccess(with: issuer)
        }
        currentTask?.resume()
    }
    
    public func abort() {
        currentTask?.cancel()
        reportFailure()
    }
    
    private func reportFailure() {
        callback?(nil)
        callback = nil
    }
    
    private func reportSuccess(with issuer: Issuer) {
        callback?(issuer)
        callback = nil
    }
}
