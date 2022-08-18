//
//  DidDocument.swift
//  cert-wallet
//
//  Created by Matthieu Collé on 10/08/2022.
//  Copyright © 2022 Digital Certificates Project. All rights reserved.
//

import Foundation

struct DidDocumentService : Codable {
    let id: String
    let type: String
    let serviceEndpoint: String
}

struct DidDocumentVerificationMethod : Codable {
    let id: String
    let type: String
}

struct DidDocument: Codable {
    let id: String
    let service: [DidDocumentService]
    let verificationMethod: [DidDocumentVerificationMethod]
    let authentication: [String]
    
    public func getIssuerProfileUrl() -> String {
        var issuerProfileUrl : String = ""
        
        var serviceIterator = self.service.makeIterator()
        while let serviceEntry = serviceIterator.next() {
            if serviceEntry.type == "IssuerProfile" {
                issuerProfileUrl = serviceEntry.serviceEndpoint
            }
        }
        return issuerProfileUrl
    }
}

struct DidResponse : Codable {
    let didDocument: DidDocument
    
    public func getIssuerProfileUrl() -> String {
        return self.didDocument.getIssuerProfileUrl()
    }
}

public class DidMethods {
    static func resolveDidDocument(didUri: String) -> DidDocument? {
        let resolvableDidUrl = Constants.universalDidResolverURL + "/" + didUri
        
        do {
            let didJson : Data = try JsonLoader.loadJsonUrl(jsonUrl: resolvableDidUrl)!
            let res: DidResponse = try JSONDecoder().decode(DidResponse.self,
                                                            from: didJson)
            return res.didDocument
        } catch let error {
            print("resolveDidDocument :: could not resolve Did Document : ", error)
        }
        
        return nil
    }
}
