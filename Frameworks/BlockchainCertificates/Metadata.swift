//
//  Metadata.swift
//  cert-wallet
//
//  Created by Chris Downie on 4/5/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import Foundation


public struct Metadata {
    public static let visiblePathsKey = "displayOrder"
    
    var groups : [String] {
        return Array(groupedMetadata.keys)
    }
    private let groupedMetadata : [String: [Metadatum]]
    private let visiblePaths : [String]

    
    init(json : [String: Any]) {
        var groupedMetadata = [String : [Metadatum]]()
        
        json.forEach { (key: String, value: Any) in
            guard key != Metadata.visiblePathsKey else {
                // If the visiblePathsKey is here, just skip it for now
                return
            }
            guard let pairedValues = value as? [String: Any] else {
                // This is an error condition, but let's hide the error for now.
                return
            }
            
            groupedMetadata[key] = pairedValues.map(Metadata.parseMetadatum)
        }
        
        visiblePaths = json[Metadata.visiblePathsKey] as? [String] ?? []

        self.groupedMetadata = groupedMetadata
    }
    
    private static func parseMetadatum(key: String, value: Any) -> Metadatum {
        var type = MetadatumType.unknown
        var stringValue : String = ""
        
        switch (value) {
        case let typedValue as Bool:
            type = .boolean
            stringValue = typedValue ? "true" : "false"
            
        case is Int:
            fallthrough
        case is Double:
            type = .number
            stringValue = "\(value)"
            
        case let typedValue as String:
            type = Metadata.getType(from: typedValue)
            stringValue = typedValue
        default:
            stringValue = "\(value)"
            break;
        }
        
        return Metadatum(type: type, label: key, value: stringValue)
    }
    
    private static func getType(from string: String) -> MetadatumType {
        var type = MetadatumType.string
        let emailRegex = "\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\b"
        
        if string.toDate() != nil {
            type = .date
        } else if string.range(of: emailRegex, options: [.regularExpression, .caseInsensitive], range: nil, locale: nil) != nil {
            type = .email
        } else if let url = URL(string: string), url.host != nil {
            type = .uri
        }
        return type
    }
    
    func metadataFor(group: String) -> [Metadatum] {
        return groupedMetadata[group] ?? []
    }
    
    func metadatumFor(dotPath: String) -> Metadatum? {
        let components = dotPath.components(separatedBy: ".")
        guard components.count == 2 else {
            print("\(#function) called without a 2-part dotpath: \(dotPath)")
            return nil
        }
        
        let groupName = components.first!
        let key = components.last!
        
        let group = groupedMetadata[groupName]
        return group?.first(where: { (datum) -> Bool in
            datum.label == key
        })
    }
    
    var visibleMetadata : [Metadatum] {
        return visiblePaths.flatMap(metadatumFor)
    }
}

public enum MetadatumType {
    // Error type
    case unknown
    
    // Basic types
    case number, string, date, boolean
    
    // String-ish types
    case email, uri, phoneNumber
}

public struct Metadatum {
    let type : MetadatumType
    let label : String
    let value : String
}
