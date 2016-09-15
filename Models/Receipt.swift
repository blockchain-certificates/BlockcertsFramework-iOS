//
//  Receipt.swift
//  cert-wallet
//
//  Created by Kim Duffy on 8/29/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation

struct Receipt {
    let merkleRoot : String
    let targetHash : String
    let proof : [[String : AnyObject]]?
    let transactionId : String
}
