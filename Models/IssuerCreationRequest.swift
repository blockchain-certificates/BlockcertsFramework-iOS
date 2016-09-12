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
                let json = jsonData as? [String: AnyObject] else {
                self?.reportFailure()
                return
            }
            
            // Flat properties. This is basically everything but the keys.
            guard let name = json["name"] as? String,
                let email = json["email"] as? String,
                let imageString = json["image"] as? String,
                let imageStringURL = URL(string: imageString),
                let image = try? Data(contentsOf: imageStringURL),
                let idString = json["id"] as? String,
                let id = URL(string: idString),
                let urlString = json["url"] as? String,
                let url = URL(string: urlString),
                let introductionURLString = json["introductionURL"] as? String,
                let introductionURL = URL(string: introductionURLString) else {
                    self?.reportFailure()
                    return
            }
            
            // The keys
            guard let issuerKeyData = json["issuerKey"] as? [[String : String]],
                let revocationKeyData = json["revocationKey"] as? [[String : String]] else {
                    self?.reportFailure()
                    return
            }


            /// Creates an array of KeyRotation objects, given a dictionary.
            ///
            /// - parameter dictionary: This should have 2 keys. `date` is a date in the format of YYYY-MM-dd. `key` is the public key rotated in to active usage on that date.
            ///
            /// - returns: KeyRotation containing the two values, if valid. `nil` if either key doesn't exist, or if the `date` format doesn't match the expected.
            func keyRotationSchedule(from dictionary: [String : String]) -> KeyRotation? {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "YYYY-MM-dd"
                
                guard let dateString = dictionary["date"],
                    let date = dateFormatter.date(from: dateString),
                    let key = dictionary["key"] else {
                        return nil
                }
                
                return KeyRotation(on: date, key: key)
            }
            
            let issuerKeys = issuerKeyData.flatMap(keyRotationSchedule)
            let revocationKeys = revocationKeyData.flatMap(keyRotationSchedule)
            guard issuerKeys.count > 0, revocationKeys.count > 0 else {
                self?.reportFailure()
                return
            }
            
            let issuer = Issuer(name: name,
                                email: email,
                                image: image,
                                id: id,
                                url: url,
                                publicIssuerKeys: issuerKeys,
                                publicRevocationKeys: revocationKeys,
                                introductionURL: introductionURL)
            self?.reportSuccess(with: issuer)
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
