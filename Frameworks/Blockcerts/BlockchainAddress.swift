//
//  BlockchainAddress.swift
//  Blockcerts
//
//  Created by Chris Downie on 10/24/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

public struct BlockchainAddress : Codable {
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
    
    public var unscoped : BlockchainAddress {
        return BlockchainAddress(value: value)
    }
    
    // Mark - Codable conformance
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(string: string)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(scopedValue)
    }
}

extension BlockchainAddress : Equatable {
    public static func ==(lhs: BlockchainAddress, rhs: BlockchainAddress) -> Bool {
        let areBothScoped = (lhs.scope != nil && rhs.scope != nil)
        let doScopesMatch = (lhs.scope == rhs.scope)
        let doKeysMatch = (lhs.value == rhs.value)
        
        return doKeysMatch && (!areBothScoped || doScopesMatch)
    }
}

extension BlockchainAddress : Hashable {
    public var hashValue: Int {
        return scopedValue.hashValue
    }
}

extension BlockchainAddress : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value)
    }
}

extension BlockchainAddress : CustomStringConvertible {
    public var description: String {
        return scopedValue
    }
}

