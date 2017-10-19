//
//  IssuerIssuingEstimateRequest.swift
//  Blockcerts
//
//  Created by Chris Downie on 10/19/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

public enum IssuerIssuingEstimateRequestError : Error {
    case aborted
}

public class IssuerIssuingEstimateRequest : CommonRequest {
    
    public func start() {
        fatalError("Not Implemented")
    }
    
    public func abort() {
        fatalError("Not Implemented")
    }
}
