//
//  String.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/12/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

extension String {
    func asHexData() -> Data? {
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
//    func asHexData() -> Data? {
//        var data = Data(capacity: characters.count / 2)
//        let validHexCharacters = Set<Character>(["0"])
//        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
//
//        var array : Array<String> = []
//        for index in stride(from: 0, to: characters.count, by: 2) {
//            array.append(self.substring(with: String.Index(index)...String.Index(index+1)))
//        }
//        
////        
////        regex.matches(in: self, options: [], range: NSMakeRange(0, characters.count)).forEach { (result) in
////            result.range.location
////        }
////        
////        data.append(UInt8(byteString))
////        
////        
////        let data = NSMutableData(capacity: characters.count / 2)
////        
////        
////        let nsString
////        regex.enumerateMatches(in: "ab12", options: [], range: <#T##NSRange#>, using: <#T##(NSTextCheckingResult?, NSRegularExpression.MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void#>)
////        
//////        regex.enumerateMatches(in: <#T##String#>, options: <#T##NSRegularExpression.MatchingOptions#>, range: <#T##NSRange#>)
////        regex.enumerateMatches(in: self as NSString, options: [], range: NSMakeRange(0, characters.count) as NSRange)  { (match, flags, stop) in
////            let byteString = self.substring(with: match!.range)
////            var num = UInt8(byteString, radix: 16)
////            data?.append(&num, length: 1)
////        }
//        
////        regex.enumerateMatches(in: <#T##String#>, options: <#T##NSRegularExpression.MatchingOptions#>, range: <#T##NSRange#>, using: <#T##(NSTextCheckingResult?, NSRegularExpression.MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void#>)
//    }
}
