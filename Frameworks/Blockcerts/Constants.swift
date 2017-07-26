//
//  Constants.swift
//  cert-wallet
//
//  Created by Chris Downie on 5/10/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation

struct Constants {
    
    // GUID regex
    static let guidRegexp = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
}

enum SchemaURLs {
    static let v2Alpha = "https://w3id.org/blockcerts/schema/2.0-alpha/context.json"
    static let v2 = "https://w3id.org/blockcerts/v2"
}
