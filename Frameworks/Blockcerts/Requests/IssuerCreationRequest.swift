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
    private let tag = String(describing: IssuerIdentificationRequest.self)

    public var callback : ((Issuer?, IssuerIdentificationRequestError?) -> Void)?
    public let url : URL
    
    
    private var session : URLSessionProtocol
    private var currentTask : URLSessionDataTaskProtocol?
    private var logger: LoggerProtocol
    
    public init(id: URL, logger: LoggerProtocol, session: URLSessionProtocol = URLSession.shared, callback: ((Issuer?, IssuerIdentificationRequestError?) -> Void)?) {
        self.callback = callback
        self.session = session
        self.logger = logger
        url = id

        logger.tag(tag).debug("init call with id/url: \(id)")
    }
    
    public func start() {
        logger.tag(tag).debug("HTTP_REQUEST: request to url: \(url)")
        currentTask = session.dataTask(with: url) { [weak self] (data, response, error) in
            self?.logger.tag(self?.tag).debug("HTTP_REQUEST: response")
            guard let response = response as? HTTPURLResponse else {
                if let e = error {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: failure unknownResponse it was nil error: \(e)")
                } else {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: failure unknownResponse it was nil")
                }
                self?.report(failure: .unknownResponse)
                return
            }
            self?.logger.tag(self?.tag).debug("HTTP_REQUEST: status code: \(response.statusCode)")
            guard response.statusCode == 200 else {
                self?.logger.tag(self?.tag).error("HTTP_REQUEST: status code was not 200, it was: \(response.statusCode) with response: \(response)")
                self?.report(failure: .httpFailure(status: response.statusCode, response: response))
                return
            }
            guard let data = data else {
                self?.logger.tag(self?.tag).error("HTTP_REQUEST: no data in the response")
                self?.report(failure: .missingJSONData)
                return
            }

            self?.logger.tag(self?.tag).info("decoding issuer with data: ")
            if let dataString = String(data: data, encoding: String.Encoding.utf8) {
                self?.logger.tag(self?.tag).debug("json_data: \(dataString)")
            } else {
                self?.logger.tag(self?.tag).error("failure trying to decode data as string with utf8")
            }

            guard let issuer = IssuerParser.decode(data: data, logger: self?.logger) else {
                if let dataString = String(data: data, encoding: String.Encoding.utf8) {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: failure trying to get issuer out of data: \(dataString)")
                } else {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: failure trying to get issuer out of data jsonSerializationFailure. Could not decode the data with utf8!")
                }
                self?.report(failure: .jsonSerializationFailure(data: data))
                return
            }

            self?.logger.tag(self?.tag).info("HTTP_REQUEST: SUCCESS")
            self?.reportSuccess(with: issuer)
        }
        currentTask?.resume()
        logger.tag(tag).info("HTTP_REQUEST: request created")
    }
    
    public func abort() {
        logger.tag(tag).info("aborting current task")
        currentTask?.cancel()
        report(failure: .aborted)
    }
    
    private func report(failure: IssuerIdentificationRequestError) {
        logger.tag(tag).debug("reporting failure: \(failure)")
        callback?(nil, failure)
        callback = nil
    }
    
    private func reportSuccess(with issuer: Issuer) {
        logger.tag(tag).debug("reporting success issuer: \(issuer)")
        callback?(issuer, nil)
        callback = nil
    }
}
