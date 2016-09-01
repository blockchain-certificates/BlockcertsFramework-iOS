//
//  IssuerIntroductionRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/26/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

class IssuerCreationRequest {
    var callback : ((Issuer?) -> Void)?
    let url : URL
    
    private var session : URLSessionProtocol
    private var currentTask : URLSessionDataTaskProtocol?
    
    init(withUrl issuerUrl: URL, session: URLSessionProtocol = URLSession.shared, callback: ((Issuer?) -> Void)?) {
        self.callback = callback
        self.session = session
        url = issuerUrl
    }
    
    func start() {
        let requestUrl = url
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
                let json = jsonData as? [String: String] else {
                self?.reportFailure()
                return
            }
            
            guard let name = json["name"],
                let email = json["email"] else {
                    self?.reportFailure()
                    return
            }
            
            // TODO: Extract data out of the URL somehow
            let fakeIssuer = Issuer(name: name,
                                    email: email,
                                    image: Data(),
                                    id: requestUrl,
                                    url: requestUrl,
                                    publicKey: "AbsolutelyFakePublicKey",
                                    publicKeyAddress: requestUrl,
                                    requestUrl: requestUrl)
            self?.reportSuccess(with: fakeIssuer)
        }
        currentTask?.resume()
    }
    
    func abort() {
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
