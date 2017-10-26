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
    public var callback : ((IssuerIntroductionRequestError?) -> Void)?
    public var delegate : IssuerIntroductionRequestDelegate
    
    var recipient : Recipient
    var session : URLSessionProtocol
    var currentTask : URLSessionDataTaskProtocol?
    var issuer : Issuer
    
    public init(introduce recipient: Recipient, to issuer: Issuer, session: URLSessionProtocol = URLSession.shared, callback: ((IssuerIntroductionRequestError?) -> Void)?) {
        self.callback = callback
        self.session = session
        self.recipient = recipient
        self.issuer = issuer
        
        delegate = DefaultDelegate()
    }
    
    public func start() {
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
        // Create JSON body. Start with the provided extra data parameters if they're present.
        var dataMap = delegate.introductionData(for: issuer, from: recipient)
        dataMap["bitcoinAddress"] = recipient.publicAddress.scopedValue
        
        guard let data = try? JSONSerialization.data(withJSONObject: dataMap, options: []) else {
            reportFailure(.cannotSerializePostData)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        currentTask = session.dataTask(with: request) { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                self?.reportFailure(.genericErrorFromServer(error: error, data: data))
                return
            }
            guard response.statusCode == 200 else {
                var message = ""
                if let errorData = data,
                    let errorMessage = try? JSONDecoder().decode(ErrorMessage.self, from: errorData) {
                    message = errorMessage.message
                }

                if message == "Invalid nonce" {
                    self?.reportFailure(.authenticationFailed)
                } else {
                    self?.reportFailure(.errorResponseFromServer(response: response, data: data))
                }
                return
            }
            
            self?.reportSuccess()
        }
        currentTask?.resume()
    }
    
    func startWebIntroduction(at url: URL) {
        var dataMap = delegate.introductionData(for: issuer, from: recipient)
        dataMap["bitcoinAddress"] = recipient.publicAddress

        // Translate the key/values in `dataMap` into query string parameters
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            reportFailure(.issuerMissingIntroductionURL)
            return
        }
        components.queryItems = dataMap.map { (key: String, value: Any) -> URLQueryItem in
            return URLQueryItem(name: key, value: "\(value)")
        }
        guard let queryURL = components.url else {
            reportFailure(.cannotSerializePostData)
            return
        }
        
        // Call our delegate to present the UI
        do {
            try delegate.presentWebView(at: queryURL, with: self)
        } catch {
            reportFailure(.introductionMethodNotSupported)
        }
    }
    
    public func abort() {
        currentTask?.cancel()
        reportFailure(.aborted)
    }
    
    func reportFailure(_ reason: IssuerIntroductionRequestError) {
        callback?(reason)
        resetState()
    }
    
    func reportSuccess() {
        callback?(nil)
        resetState()
    }
    
    private func resetState() {
        OperationQueue.main.addOperation { [weak self] in
            self?.delegate.dismissWebView()
        }
        callback = nil
    }
}

extension IssuerIntroductionRequest : WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard case IssuerIntroductionMethod.webAuthentication(_, let successURL, let errorURL) = issuer.introductionMethod else {
            return
        }
        guard let webURL = webView.url else {
            return
        }

        if var webComponents = URLComponents(url: webURL, resolvingAgainstBaseURL: false) {
            // Remove any additional query items before comparison
            webComponents.queryItems = nil
            let compareToUrl = webComponents.url
            
            if compareToUrl == successURL {
                webView.stopLoading()
                reportSuccess()
            } else if compareToUrl == errorURL {
                webView.stopLoading()
                reportFailure(.webAuthenticationFailed)
            }
        } else {
            webView.stopLoading()
            reportFailure(.webAuthenticationFailed)
        }
    }
}


