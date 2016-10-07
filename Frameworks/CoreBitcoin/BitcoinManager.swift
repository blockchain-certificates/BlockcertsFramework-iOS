//
//  BitcoinManager.swift
//  cert-wallet
//
//  Created by Chris Downie on 10/7/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

public protocol BitcoinManager {
    func address(for certificate: Certificate, on chain: String) -> String?
}
