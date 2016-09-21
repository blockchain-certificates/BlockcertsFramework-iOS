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

class JSONLDValidator {
    static let shared = JSONLDValidator()

    // JSContext is not sufficient. We need web access 
    let webView : WKWebView
//    let context : JSContext
    
    init() {
        webView = WKWebView(frame: .zero)
        
        // To conserve power, the WKWebView won't execute unless it's in the currently displayed view heirarchy.
//        UIApplication.shared.keyWindow?.addSubview(webView)
        
        
        guard let path = Bundle.main.path(forResource: "jsonld", ofType: "js") else {
            fatalError("Couldn't find `jsonld.js` file in \(#file)")
        }
        guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
            fatalError("Couldn't read contents of `jsonld.js` file in \(#file)")
        }

        webView.evaluateJavaScript(source) { (result, error) in
            if let error = error {
                print("Error: \(error)")
            }
        }
        
        let demoTest = "jsonld.compact({  \"http://schema.org/name\": \"Manu Sporny\",  \"http://schema.org/url\": {\"@id\": \"http://manu.sporny.org/\"},  \"http://schema.org/image\": {\"@id\": \"http://manu.sporny.org/images/manu.png\"}}, {  \"name\": \"http://schema.org/name\",  \"homepage\": {\"@id\": \"http://schema.org/url\", \"@type\": \"@id\"},  \"image\": {\"@id\": \"http://schema.org/image\", \"@type\": \"@id\"}}, function(err, compacted) { console.log(err, compacted) })"
        
        webView.evaluateJavaScript(demoTest) { (result, error) in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    func isValid(json: [String: Any]) -> Bool {
        return true
        // TODO: Call the appropriate method in that context.
    }
}
