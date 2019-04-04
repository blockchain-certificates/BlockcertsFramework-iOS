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
        let adjustedString = self.count % 2 == 1 ? "0" + self : self
        
        let (pairs, _) = adjustedString.reduce((Array<String>(), nil)) { (partialResult, char) -> (Array<String>, Character?) in
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
        for number in numberSequence.compactMap({ $0 }) {
            data.append(number)
        }
        
        return data
    }
}

fileprivate let isoFormats = [
    "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
    "yyyy-MM-dd'T'HH:mm:ss.SSS",
    "yyyy-MM-dd"
]

extension String {
    public func toDate() -> Date? {
        var date : Date?
        let dateString = self
        
        // ISO8601 Format
        if #available(iOSApplicationExtension 10.0, *) {
            let isoFormatter = ISO8601DateFormatter()
            date = isoFormatter.date(from: dateString)
        }
        
        if date == nil {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            for format in isoFormats {
                formatter.dateFormat = format
                date = formatter.date(from: dateString)
                
                if date != nil {
                    break
                }
            }
        }
        
        // Unix Timestamp
        if date == nil, let milliseconds = Double(dateString) {
            date = Date(timeIntervalSince1970: milliseconds)
        }
        
        return date
    }
}

extension Date {
    public func toString() -> String {
        if #available(iOSApplicationExtension 10.0, *) {
            let isoFormatter = ISO8601DateFormatter()
            return isoFormatter.string(from: self)
        }
        
        let isoFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd"
        ]
        let formatter = DateFormatter()
        formatter.dateFormat = isoFormats.first!
        
        return formatter.string(from: self)
    }
}
