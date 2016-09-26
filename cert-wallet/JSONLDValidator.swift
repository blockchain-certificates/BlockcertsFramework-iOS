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

// This protocol will let us test any dependent components is isolation by mocking out the JSONLDValidator.
// It will also mean we can switch from this awkward WKWebKit bridge to a Swift-native JSONLD validator
// once it's built.
enum JSONLDError : Error {
    case javascriptError(message: String)
}

protocol JSONLD {
    func compact(docData: Data, context: [String : Any]?, callback: ((Error?, [String : Any]?) -> Void)?)

    // As time allows, it may make sense to add:
    // * expand
    // * flatten
    // * frame
    // * normalize
    // * toRDF
    // * fromRDF
    // ...and whatever else to make this a full JSONLD client.
}

class JSONLDValidator : NSObject {
    static let shared = JSONLDValidator()

    // JSContext is not sufficient. We need web access 
    let webView : WKWebView
    let userContentController : WKUserContentController
    
    var queuedCalls = [() -> Void]()
    
    private var lastUsedId = 0
    var uniqueId : Int  {
        lastUsedId += 1
        return lastUsedId
    }
    
    var savedCallbacks = [Int: ((Error?, [String: Any]?) -> Void)]()
    
    override init() {
        userContentController = WKUserContentController()
        
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
        
        // Add self
        webView.navigationDelegate = self
        userContentController.add(self, name: "respond")
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
}

extension JSONLDValidator : JSONLD {
    func compact(doc: [String : Any], context: [String : Any]? = nil, callback: ((Error?, [String : Any]?) -> Void)?) {
        let serializedData = try? JSONSerialization.data(withJSONObject: doc, options: [])

        return compact(docData: serializedData!, context: context, callback: callback)
    }
    
    func compact(docData: Data, context: [String : Any]? = nil, callback: ((Error?, [String : Any]?) -> Void)?) {
        let serializedDoc = String(data: docData, encoding: .utf8)!
        let newID = uniqueId
        let jsResultHandler = "function (err, result) {"
            + "var response = {"
            + "  id: \(newID),"
            + "  err: err,"
            + "  result: result"
            + "};"
            + "window.webkit.messageHandlers.respond.postMessage(response);"
            + "}"
        
        
        let jsString : String!
        if let context = context {
            jsString = "jsonld.compact(\(serializedDoc), \(context), \(jsResultHandler))"
        } else {
            jsString = "jsonld.compact(\(serializedDoc), {}, \(jsResultHandler))"
        }
        
        savedCallbacks[newID] = callback
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
}


extension JSONLDValidator : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        drainQueue()
    }
}

extension JSONLDValidator : WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let response = message.body as? [String: Any] else {
            print("Something went wrong, the response wasn't what I expected in \(#function)")
            return
        }
        
        guard let responseForID = response["id"] as? Int else {
            print("There wasn't an ID in the response")
            return
        }
        guard let callback = savedCallbacks[responseForID] else {
            print("Something went wrong. We don't have a callback for that ID: \(responseForID)")
            return
        }
        let errorObject = response["err"] as? [String : Any] ?? [:]
        
        var error : Error? = nil
        if let errorMessage = errorObject["message"] as? String {
            error = JSONLDError.javascriptError(message: errorMessage)
        }
        
        let result = response["result"] as? [String : Any]
        callback(error, result)
    }
}
