//
//  Assertion.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/9/16.
//  Copyright © 2016 Learning Machine. All rights reserved.
//

import Foundation

struct Assertion {
    let issuedOn : Date
    let signatureImage : Data
    let evidence : String
    let uid : String
    let id : URL
}
