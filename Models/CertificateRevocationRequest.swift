//
//  CertificateRevocationRequest.swift
//  cert-wallet
//
//  Created by Chris Downie on 9/6/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

class CertificateRevocationRequest : CommonRequest {
    var callback : ((Bool, String?) -> Void)?
    
    private var certificate : Certificate
    
    init(revoking certificate: Certificate, callback: ((Bool, String?) -> Void)?) {
        self.certificate = certificate
        self.callback = callback
    }
    
    func start() {
        // TODO: This should actually do something
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.reportFailure("Not implemented")
        }
    }
    
    func abort() {
        reportFailure("Aborted")
    }
    
    private func reportSuccess() {
        callback?(true, nil)
        callback = nil
    }
    private func reportFailure(_ reason: String) {
        callback?(false, reason)
        callback = nil
    }
}
