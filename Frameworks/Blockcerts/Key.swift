//
//  Key.swift
//  Blockcerts
//
//  Created by Chris Downie on 10/24/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

public struct Key {
    public let scope : String?
    public let value : String

    public init(value: String, scope : String? = nil) {
        self.scope = scope
        self.value = value
    }
    
    public init(string value: String) {
        if value.contains(":") {
            let components = value.components(separatedBy: ":")
            if components.count > 1 {
                self.init(value: components[components.startIndex.advanced(by: 1)], scope: components.first)
            } else {
                self.init(value: components.first ?? "")
            }
        } else {
            self.init(value: value)
        }
    }
    
    public var scopedValue : String {
        if let scope = scope {
            return "\(scope):\(value)"
        }
        return value
    }
    
    public var unscoped : Key {
        return Key(value: value)
    }
}

extension Key : Equatable {
    public static func ==(lhs: Key, rhs: Key) -> Bool {
        let areBothScoped = (lhs.scope != nil && rhs.scope != nil)
        let doScopesMatch = (lhs.scope == rhs.scope)
        let doKeysMatch = (lhs.value == rhs.value)
        
        return doKeysMatch && (!areBothScoped || doScopesMatch)
    }
}

extension Key : Hashable {
    public var hashValue: Int {
        return scopedValue.hashValue
    }
}

extension Key {
    
}

