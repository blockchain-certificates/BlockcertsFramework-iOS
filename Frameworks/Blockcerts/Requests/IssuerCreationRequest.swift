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
    case issuerMissing(property: String)
    case issuerInvalid(property: String)
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
            
            // TODO: Handle more nuanced responses with IssuerParser
            if let issuer = IssuerParser.parse(dictionary: json) {
                self?.reportSuccess(with: issuer)
            } else {
                self?.report(failure: .unknownResponse)
            }
            
//            do {
//                let issuer = try Issuer(dictionary: json)
//                self?.reportSuccess(with: issuer)
//            } catch IssuerError.missing(let property) {
//                self?.report(failure: .issuerMissing(property: property))
//            } catch IssuerError.invalid(let property) {
//                self?.report(failure: .issuerInvalid(property: property))
//            } catch {
//                self?.report(failure: .unknownResponse)
//            }
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
