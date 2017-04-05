//
//  Metadata.swift
//  cert-wallet
//
//  Created by Chris Downie on 4/5/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation


public struct Metadata {
    let groups : [String]
    
    
    init(json : [String: Any]) {
        groups = [];
        
        // Go through all the keys
        // `displayOrder` is special -- save that for last
        // Everything else:
        //   1. Add it to the 'groups' list.
        //   2. Create a Metadatum object for each child
        
        // Now go through `displayOrder`:
    }
    
    func metadataFor(group: String) -> [Metadatum] {
        return []
    }
    
    func metadatumFor(dotPath: String) -> Metadatum? {
        return nil
    }
    
    var visibleMetadata : [Metadatum] {
        return []
    }
}

public enum MetadatumType {
    // Basic types
    case number, string, date
    
    // String-ish types
    case email, uri, phoneNumber
}

public struct Metadatum {
    let type : MetadatumType
    let value : String
}
