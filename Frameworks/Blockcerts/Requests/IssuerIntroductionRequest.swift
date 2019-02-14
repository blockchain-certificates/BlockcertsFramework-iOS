//
//  IssuerIntroductionRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/2/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation
import WebKit

public enum IssuerIntroductionRequestError : Error {
    case aborted
    case issuerMissingIntroductionURL
    case cannotSerializePostData
    case genericErrorFromServer(error: Error?, data: Data?)
    case errorResponseFromServer(response: HTTPURLResponse, data: Data?)
    case invalidNonce
    case introductionMethodNotSupported
    case authenticationFailed
    case webAuthenticationFailed
    case webAuthenticationMisconfigured
}

public protocol IssuerIntroductionRequestDelegate : class {
    func introductionData(for issuer: Issuer, from recipient: Recipient) -> [String: Any]
    func presentWebView(at url:URL, with navigationDelegate:WKNavigationDelegate) throws
    func dismissWebView()
}

private struct ErrorMessage : Codable {
    let message : String
}

public extension IssuerIntroductionRequestDelegate {
    public func introductionData(for issuer: Issuer, from recipient: Recipient) -> [String: Any] {
        var dataMap = [String: Any]()
        dataMap["email"] = recipient.identity
        dataMap["name"] = recipient.name
        return dataMap
    }
    
    public func presentWebView(at url:URL, with navigationDelegate:WKNavigationDelegate) throws {
        throw IssuerIntroductionRequestError.introductionMethodNotSupported
    }
    public func dismissWebView() {
    }
}

private class DefaultDelegate : IssuerIntroductionRequestDelegate {
    
}

public class IssuerIntroductionRequest : NSObject, CommonRequest {
    private let tag = String(describing: IssuerIntroductionRequest.self)

    public var callback : ((IssuerIntroductionRequestError?) -> Void)?
    public var delegate : IssuerIntroductionRequestDelegate

    var recipient : Recipient
    var session : URLSessionProtocol
    var currentTask : URLSessionDataTaskProtocol?
    var issuer : Issuer
    private var logger: LoggerProtocol
    
    public init(introduce recipient: Recipient, to issuer: Issuer, loggingTo logger: LoggerProtocol, session: URLSessionProtocol = URLSession.shared, callback: ((IssuerIntroductionRequestError?) -> Void)?) {
        self.callback = callback
        self.session = session
        self.recipient = recipient
        self.issuer = issuer
        self.logger = logger
        
        delegate = DefaultDelegate()
        logger.tag(tag).debug("init call with recipient: \(recipient), issuer: \(issuer)")
    }
    
    public func start() {
        logger.tag(tag).info("start")

        switch issuer.introductionMethod {
        case .basic(let introductionURL):
            startBasicIntroduction(at: introductionURL)
        case .webAuthentication(let introductionURL, _, _):
            startWebIntroduction(at: introductionURL)
        case .unknown:
            reportFailure(.issuerMissingIntroductionURL)
        }
    }
    
    func startBasicIntroduction(at url: URL) {
        logger.tag(tag).debug("HTTP_REQUEST: start_basic_introduction with url \(url)")

        // Create JSON body. Start with the provided extra data parameters if they're present.
        var dataMap = delegate.introductionData(for: issuer, from: recipient)
        dataMap["bitcoinAddress"] = recipient.publicAddress.scopedValue
        
        guard let data = try? JSONSerialization.data(withJSONObject: dataMap, options: []) else {
            logger.tag(tag).error("HTTP_REQUEST: can not serialize \(dataMap)")
            reportFailure(.cannotSerializePostData)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        logger.tag(tag).debug("HTTP_REQUEST: request: \(url) with httpBody: \(data), httpMethod: POST")
        
        currentTask = session.dataTask(with: request) { [weak self] (data, response, error) in
            self?.logger.tag(self?.tag).debug("HTTP_REQUEST: response from request: \(url)")
            guard let response = response as? HTTPURLResponse else {
                if let e = error {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: generic error from server for request: \(url) error: \(e)")
                } else {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: generic error from server for request: \(url)")
                }

                self?.reportFailure(.genericErrorFromServer(error: error, data: data))
                return
            }
            self?.logger.tag(self?.tag).debug("HTTP_REQUEST: status code: \(response.statusCode)")
            guard response.statusCode == 200 else {
                self?.logger.tag(self?.tag).warning("status code was not 200")
                var message = ""
                if let errorData = data,
                    let errorMessage = try? JSONDecoder().decode(ErrorMessage.self, from: errorData) {

                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: error data \(errorData)")
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: error message\(errorMessage)")
                    message = errorMessage.message
                } else {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: error data was nil")
                }

                if message == "Invalid nonce" {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: error authenticationFailed")
                    self?.reportFailure(.authenticationFailed)
                } else {
                    self?.logger.tag(self?.tag).error("HTTP_REQUEST: error errorResponseFromServer")
                    self?.reportFailure(.errorResponseFromServer(response: response, data: data))
                }
                return
            }

            self?.logger.tag(self?.tag).info("HTTP_REQUEST: request: \(url) SUCCESS")
            self?.reportSuccess()
        }
        currentTask?.resume()
        logger.tag(tag).info("HTTP_REQUEST: request created")
    }
    
    func startWebIntroduction(at url: URL) {
        logger.tag(tag).debug("start_web_introduction with url \(url)")
        var dataMap = delegate.introductionData(for: issuer, from: recipient)
        dataMap["bitcoinAddress"] = recipient.publicAddress

        logger.tag(tag).debug("start_web_introduction with data \(dataMap)")

        // Translate the key/values in `dataMap` into query string parameters
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            logger.tag(tag).error("error creating url component issuerMissingIntroductionURL")
            reportFailure(.issuerMissingIntroductionURL)
            return
        }
        components.queryItems = dataMap.map { (key: String, value: Any) -> URLQueryItem in
            let urlQueryItems = URLQueryItem(name: key, value: "\(value)")
            logger.tag(tag).debug("query items created: \(urlQueryItems)")
            return urlQueryItems
        }
        guard let queryURL = components.url else {
            logger.tag(tag).error("unable to serialize postData")
            reportFailure(.cannotSerializePostData)
            return
        }
        logger.tag(tag).debug("queryURL ready: \(queryURL)")

        logger.tag(tag).info("presenting webview")
        // Call our delegate to present the UI
        do {
            try delegate.presentWebView(at: queryURL, with: self)
        } catch {
            logger.tag(tag).error("error presenting webview introductionMethodNotSupported")
            reportFailure(.introductionMethodNotSupported)
        }
    }
    
    public func abort() {
        logger.tag(tag).info("aborting current task")
        currentTask?.cancel()
        reportFailure(.aborted)
    }
    
    func reportFailure(_ reason: IssuerIntroductionRequestError) {
        logger.tag(tag).debug("reporting failure \(reason)")
        callback?(reason)
        resetState()
    }
    
    func reportSuccess() {
        logger.tag(tag).debug("reporting success")
        callback?(nil)
        resetState()
    }
    
    private func resetState() {
        logger.tag(tag).debug("resetting state")
        OperationQueue.main.addOperation { [weak self] in
            self?.delegate.dismissWebView()
        }
        callback = nil
    }
}

extension IssuerIntroductionRequest : WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard case IssuerIntroductionMethod.webAuthentication(_, _, let errorURL) = issuer.introductionMethod else {
            return
        }
        guard let webURL = webView.url else {
            return
        }

        if var webComponents = URLComponents(url: webURL, resolvingAgainstBaseURL: false) {
            // Remove any additional query items before comparison
            webComponents.queryItems = nil
            let compareToUrl = webComponents.url

            if compareToUrl == errorURL {
                logger.tag(tag).error("WKNavigationDelegate url: \(compareToUrl) equals errorURL \(errorURL) webAuthenticationFailed")
                logger.tag(tag).info("stopping loading")
                webView.stopLoading()
                reportFailure(.webAuthenticationFailed)
            }
        } else {
            logger.tag(tag).error("WKNavigationDelegate")
            logger.tag(tag).info("stopping loading")
            webView.stopLoading()
            reportFailure(.webAuthenticationFailed)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard case IssuerIntroductionMethod.webAuthentication(_, let successURL, _) = issuer.introductionMethod else {
            return
        }
        
        if navigationAction.request.url == successURL {
            logger.tag(tag).info("WKNavigationDelegate success")
            logger.tag(tag).info("stopping loading")
            webView.stopLoading()
            reportSuccess()
        }
        
        decisionHandler(.allow)
    }
}


