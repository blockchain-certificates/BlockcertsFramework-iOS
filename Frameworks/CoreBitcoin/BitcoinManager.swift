//
//  BitcoinManager.swift
//  cert-wallet
//
//  Created by Chris Downie on 10/7/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

public protocol BitcoinManager {
    /// Derives the address for a certificate on a specific chain.
    ///
    /// - parameter message:    The message to verify
    /// - parameter signature:  The signature
    /// - parameter chain:      Which chain this certificate was issued on.
    ///
    /// - returns: A string representing the address if it exists, nil otherwise.
    func address(for message: String, for signature: String, on chain: String) -> String?
}
