//
//  JSONLDValidator.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/20/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation
//import JavaScriptCore
import WebKit

class JSONLDValidator : NSObject {
    static let shared = JSONLDValidator()

    // JSContext is not sufficient. We need web access 
    let webView : WKWebView
    let userContentController : WKUserContentController
    
    var queuedCalls = [() -> Void]()
    
    override init() {

        userContentController = WKUserContentController()
        userContentController.add(PongMessageHandler(), name: "pong")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)

        // Load our JSON-LD/index.html file for calling jsonld.js functions
        guard let path = Bundle.main.path(forResource: "index", ofType: "html") else {
            fatalError("Couldn't find `index.html` file in \(#file)")
        }
        let pathURL = URL(fileURLWithPath: path)
        webView.loadFileURL(pathURL, allowingReadAccessTo: pathURL)
        
        super.init()
        webView.navigationDelegate = self
    }
    
    func ping1() {
        func execute() {
            webView.evaluateJavaScript("ping1()") { (result, error) in
                print("result: \(result), error: \(error)")
            }
        }
        
        if webView.isLoading {
            queuedCalls.append(execute)
        } else {
            execute()
        }
    }
    
    func ping2() {
        func execute() {
            webView.evaluateJavaScript("ping2()") { (result, error) in
                print("result: \(result), error: \(error)")
            }
        }
        
        if webView.isLoading {
            queuedCalls.append(execute)
        } else {
            execute()
        }
    }
    
    fileprivate func drainQueue() {
        guard !webView.isLoading else {
            return
        }
        
        for method in queuedCalls {
            method()
        }
        queuedCalls = []
    }
    
    func isValid(json: [String: Any]) -> Bool {
        guard webView.superview != nil else {
            print("Warning: JSONLDValidator used before being setup. AppDelegate should attach the web view to the root view controller.")
            return false
        }
        return true
        // TODO: Call the appropriate method in that context.
    }
}

extension JSONLDValidator : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        drainQueue()
    }
}


fileprivate class PongMessageHandler : NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("\(#function): got \(message.body)")
    }
}
