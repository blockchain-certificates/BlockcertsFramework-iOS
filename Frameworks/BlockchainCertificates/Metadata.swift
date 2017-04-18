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
    public static let schemaKey = "$schema"
    
    var groups : [String] {
        return Array(groupedMetadata.keys)
    }
    private let groupedMetadata : [String: [Metadatum]]
    private let visiblePaths : [String]

    
    init(json inputJson: [String: Any]) {
        var json = inputJson
        var groupedMetadata = [String : [Metadatum]]()
        
        visiblePaths = json[Metadata.visiblePathsKey] as? [String] ?? []
        json.removeValue(forKey: Metadata.visiblePathsKey)
        
        let schema = MetadataSchema(json:json[Metadata.schemaKey] as? [String: Any])
        json.removeValue(forKey: Metadata.schemaKey)
        
        json.forEach { (key: String, value: Any) in
            guard let pairedValues = value as? [String: Any] else {
                // This is an error condition, but let's hide the error for now.
                return
            }
            
            groupedMetadata[key] = pairedValues.map { (key: String, value: Any) -> Metadatum in
                return schema.metadatumFor(key: key, value: value)
            }
        }

        self.groupedMetadata = groupedMetadata
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
    
    public var visibleMetadata : [Metadatum] {
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
    public let type : MetadatumType
    public let label : String
    public let value : String
}

// Mark: Private MetadataSchema to help parse the metadata.
private struct MetadataSchema {
    init(json: [String: Any]?) {
        guard let json = json else {
            return
        }
        print(json)
    }
    
    func metadatumFor(key: String, value: Any) -> Metadatum {
        let type = typeFor(key: key, value: value)
        let label = self.label(for: key)
        let displayValue = self.displayValue(for: value, type: type)
        
        return Metadatum(type: type, label: label, value: displayValue)
    }
    
    private func typeFor(key: String, value: Any) -> MetadatumType {
        if let schemaType = schemaType(for: key) {
            return schemaType
        }
        
        var type = MetadatumType.unknown
        
        switch (value) {
        case is Int:
            fallthrough
        case is Double:
            type = .number
        case is Bool:
            type = .boolean
        case let typedValue as String:
            type = getType(from: typedValue)
        default:
            break;
        }
        
        return type
    }
    
    private func schemaType(for key: String) -> MetadatumType? {
        return nil
    }
    
    private func label(for key: String) -> String {
        // todo: check schema type for the label
        return key
    }
    
    private func displayValue(for value: Any, type: MetadatumType) -> String{
        var stringValue = ""
        
        switch(type) {
        case .boolean:
            stringValue = value as! Bool ? "true" : "false"
        default:
            stringValue = "\(value)"
        }
        
        return stringValue
    }
    
    
    private func getType(from string: String) -> MetadatumType {
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
}

