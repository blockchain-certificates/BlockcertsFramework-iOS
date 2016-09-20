//
//  JSONLDValidator.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/20/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation
import JavaScriptCore

class JSONLDValidator {
    static let shared = JSONLDValidator()

    let context : JSContext
    
    init() {
        guard let context = JSContext() else {
            fatalError("Couldn't create a Javascript execution context in \(#file)")
        }
        self.context = context
        
        guard let path = Bundle.main.path(forResource: "jsonld", ofType: "js") else {
            fatalError("Couldn't find `jsonld.js` file in \(#file)")
        }
        guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
            fatalError("Couldn't read contents of `jsonld.js` file in \(#file)")
        }

        _ = context.evaluateScript(source)
        
    }
    
    func isValid(json: [String: Any]) -> Bool {
        return true
        // TODO: Call the appropriate method in that context. 
    }
}
