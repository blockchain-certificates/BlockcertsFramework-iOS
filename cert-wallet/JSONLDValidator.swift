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

protocol JSONLD {
    func compact(doc: [String: Any],
                 context: [String:Any]?,
                 callback: ((_ error: Error?, _ result: [String: Any]?) -> Void)?
        ) -> Void
    
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
    
//    func isValid(json: [String: Any]) -> Bool {
//        guard webView.superview != nil else {
//            print("Warning: JSONLDValidator used before being setup. AppDelegate should attach the web view to the root view controller.")
//            return false
//        }
//        return true
//        // TODO: Call the appropriate method in that context.
//    }
}

extension JSONLDValidator : JSONLD {
    func compact(doc: [String : Any], context: [String : Any]?, callback: ((Error?, [String : Any]?) -> Void)?) {
        let newID = uniqueId
        let jsResultHandler = "function (err, result) {"
            + "var response = {"
            + "  id: \(newID),"
            + "  err: err,"
            + "  result: result"
            + "};"
            + "window.webkit.messageHandlers.respond.postMessage(response);"
            + "}"

        let serializedData = try? JSONSerialization.data(withJSONObject: doc, options: [])
        let serializedDoc = String(data: serializedData!, encoding: .utf8)!
        
        let jsString : String!
        if let context = context {
            jsString = "jsonld.compact(\(serializedDoc), \(context), \(jsResultHandler))"
        } else {
            jsString = "jsonld.compact(\(serializedDoc), null, \(jsResultHandler))"
        }
        print()
        print(jsString)
        print()
        
        savedCallbacks[newID] = callback
        
//        webView.evaluateJavaScript(jsString, completionHandler: nil)
        webView.evaluateJavaScript(jsString) { (any, err) in
            print("SOmething happened yeapppp")
        }
    }
}


extension JSONLDValidator : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        drainQueue()
    }
}

// Demo -- delete this soon.
extension JSONLDValidator {
    
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
}


fileprivate class PongMessageHandler : NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("\(#function): got \(message.body)")
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
        
        let error = response["err"] as? Error // This will probably always be nil.
        let result = response["result"] as? [String : Any]
        callback(error, result)
    }
}
