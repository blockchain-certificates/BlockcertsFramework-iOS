//
//  CommonRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/6/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

/// Represents a request for data or processing that might take some time. Classes that implement this protocol are expected to also implement some means of conveying progress or completion -- either a delegate or a completion handler.
public protocol CommonRequest {
    /// Begin executing the request.
    func start()
    
    /// Stop executing the request. Usually, this will call whatever completion handler/delegate with an "aborted" message.
    func abort()
}
