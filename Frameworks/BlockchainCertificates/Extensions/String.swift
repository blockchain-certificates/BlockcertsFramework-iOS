//
//  String.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/12/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

extension String {
    /// Turns a string of hexidecimal characters into a Data representation with the same value.
    ///
    /// - returns: Data representing that hexidecimal sequence if the string is valid. Nil otherwise.
    public func asHexData() -> Data? {
        let adjustedString = self.characters.count % 2 == 1 ? "0" + self : self
        
        let (pairs, _) = adjustedString.characters.reduce((Array<String>(), nil)) { (partialResult, char) -> (Array<String>, Character?) in
            var (pairs, lastCharacter) = partialResult
            
            if let previousCharacter = lastCharacter {
                let newPair = "\(previousCharacter)\(char)"
                pairs.append(newPair)
                return (pairs, nil)
            } else {
                return (pairs, char)
            }
        }
        
        let numberSequence = pairs.map { (numberString) -> UInt8? in
            return UInt8(numberString, radix: 16)
        }
        
        let hasNil = numberSequence.contains { $0 == nil }
        
        if hasNil {
            return nil
        }
        
        var data = Data()
        for number in numberSequence.flatMap({ $0 }) {
            data.append(number)
        }
        
        return data
    }
}

extension Data {
    public func asHexString() -> String {
        var hexString = ""
        for byte in self {
            hexString += String(format: "%02X", byte)
        }
        
        return hexString
    }
}
