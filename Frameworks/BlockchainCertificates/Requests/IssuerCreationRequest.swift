//
//  IssuerIntroductionRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/26/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

public enum IssuerIdentificationRequestError : Error {
    case aborted
    case unknownResponse
    case httpFailure(status: Int, response: HTTPURLResponse)
    case missingJSONData
    case jsonSerializationFailure(data : Data)
    case issuerParseFailure(error: IssuerError)
}

public class IssuerIdentificationRequest : CommonRequest {
    public var callback : ((Issuer?, IssuerIdentificationRequestError?) -> Void)?
    public let url : URL
    
    
    private var session : URLSessionProtocol
    private var currentTask : URLSessionDataTaskProtocol?
    
    public init(id: URL, session: URLSessionProtocol = URLSession.shared, callback: ((Issuer?, IssuerIdentificationRequestError?) -> Void)?) {
        self.callback = callback
        self.session = session
        url = id
    }
    
    public func start() {
        currentTask = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                self?.report(failure: .unknownResponse)
                return
            }
            guard response.statusCode == 200 else {
                self?.report(failure: .httpFailure(status: response.statusCode, response: response))
                return
            }
            guard let data = data else {
                self?.report(failure: .missingJSONData)
                return
            }

            guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonData as? [String: Any] else {
                self?.report(failure: .jsonSerializationFailure(data: data))
                return
            }
            
            do {
                let issuer = try Issuer(dictionary: json)
                self?.reportSuccess(with: issuer)
            } catch {
                if let issuerError = error as? IssuerError {
                    self?.report(failure: .issuerParseFailure(error: issuerError))
                } else {
                    self?.report(failure: .unknownResponse)
                }
            }
        }
        currentTask?.resume()
    }
    
    public func abort() {
        currentTask?.cancel()
        report(failure: .aborted)
    }
    
    private func report(failure: IssuerIdentificationRequestError) {
        callback?(nil, failure)
        callback = nil
    }
    
    private func reportSuccess(with issuer: Issuer) {
        callback?(issuer, nil)
        callback = nil
    }
}
