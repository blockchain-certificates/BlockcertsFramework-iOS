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
    
    private var currentTask : URLSessionTask?
    
    init(withUrl issuerUrl: URL, callback: ((Issuer?) -> Void)?) {
        self.callback = callback
        url = issuerUrl
    }
    
    func start() {
        let requestUrl = url
        currentTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                    self?.reportFailure()
                    return
            }
            
            // TODO: Extract data out of the URL somehow
            let fakeIssuer = Issuer(name: "Fake Issuer Name",
                                    email: "Fake Issuer email",
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
