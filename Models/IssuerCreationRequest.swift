//
//  IssuerIntroductionRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/26/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

class IssuerCreationRequest : CommonRequest {
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
                let email = json["email"],
                let imageString = json["image"],
                let imageStringURL = URL(string: imageString),
                let image = try? Data(contentsOf: imageStringURL),
                let idString = json["id"],
                let id = URL(string: idString),
                let urlString = json["url"],
                let url = URL(string: urlString),
                let publicKeyString = json["publicKeyAddress"],
                let publicKeyURL = URL(string: publicKeyString),
                let introductionURLString = json["requestURL"],
                let introductionURL = URL(string: introductionURLString) else {
                    self?.reportFailure()
                    return
            }
            
            // TODO: Query the public key address to get the public key
            
            let fakeIssuer = Issuer(name: name,
                                    email: email,
                                    image: image,
                                    id: id,
                                    url: url,
                                    publicKey: "AbsolutelyFakePublicKey",
                                    publicKeyAddress: publicKeyURL,
                                    requestUrl: introductionURL)
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
