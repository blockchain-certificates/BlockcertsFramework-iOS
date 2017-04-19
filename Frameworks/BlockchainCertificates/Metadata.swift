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
        
        json.forEach { (group: String, value: Any) in
            guard let pairedValues = value as? [String: Any] else {
                // This is an error condition, but let's hide the error for now.
                return
            }
            
            groupedMetadata[group] = pairedValues.map { (key: String, value: Any) -> Metadatum in
                return schema.metadatumFor(group: group, key: key, value: value)
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
            datum.key == key
        })
    }
    
    public var visibleMetadata : [Metadatum] {
        return visiblePaths.flatMap(metadatumFor)
    }
}

// This represents the type of the associated data.
// For types that aren't natively encoded as strings, or have multiple bits of data, the associated value is stored in the enum as `rawValue`
public enum MetadatumType {
    // Error type
    case unknown
    
    // Basic types
    case integer, number, string, date, boolean
    
    // String-ish types
    case email, uri, phoneNumber
    
    // Enum types
    case enumSingleOption(from: [String])
    case enumMultipleOptions(from: [String])
}

extension MetadatumType : Equatable {}
public func ==(lhs: MetadatumType, rhs: MetadatumType) -> Bool {
    var areEqual = false
    
    switch (lhs, rhs) {
    case (.unknown, .unknown),
         (.integer, .integer),
         (.number, .number),
         (.string, .string),
         (.date, .date),
         (.boolean, .boolean),
         (.email, .email),
         (.uri, .uri),
         (.phoneNumber, .phoneNumber):
        areEqual = true
    case (.enumSingleOption(from: let leftOptions), .enumSingleOption(from: let rightOptions)),
         (.enumMultipleOptions(from: let leftOptions), .enumMultipleOptions(from: let rightOptions)):
        areEqual = leftOptions == rightOptions
    default:
        break;
    }
    
    return areEqual
}

public struct Metadatum {
    public let type : MetadatumType
    public let key : String
    public let label : String
    public let value : String
}

// Mark: Private MetadataSchema to help parse the metadata.
private let titleKey = "title"
private let patternKey = "pattern"
private let formatKey = "format"
private let typeKey = "type"
private let enumKey = "enum"

private struct MetadataSchema {
    let propertyMap : [String : [String: (label: String?, type: MetadatumType)]]
    
    init(json: [String: Any]?) {
        guard let json = json else {
            propertyMap = [:]
            return
        }
        guard let properties = json["properties"] as? [String: Any] else {
            propertyMap = [:]
            return
        }
        
        var map : [String: [String: (label: String?, type: MetadatumType)]] = [:]
        
        properties.forEach { (group: String, value: Any) in
            guard let valueJson = value as? [String: Any],
                let keys = valueJson["properties"] as? [String: Any] else {
                    return
            }
            
            keys.forEach { (property: String, value: Any) in
                guard let value = value as? [String: Any] else {
                    return
                }
                
                if map[group] == nil {
                    map[group] = [:]
                }
                map[group]?[property] = MetadataSchema.createTupleForSchema(json: value)
            }
        }
        
        propertyMap = map
        dump(propertyMap)
    }
    
    static func createTupleForSchema(json:[String: Any]) -> (label: String?, type: MetadatumType) {
        let label = json["title"] as? String
        var type = MetadatumType.unknown
        
        if let stringType = json[typeKey] as? String {
            switch stringType {
            case "string":
                if json[patternKey] as? String == "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" {
                    type = .date
                } else if json[formatKey] as? String == "email" {
                    type = .email
                } else if json[formatKey] as? String == "uri" {
                    type = .uri
                } else if let options = json[enumKey] as? [String] {
                    type = .enumSingleOption(from:options)
                } else {
                    type = .string
                }
            case "array":
                if let items = json["items"] as? [String : Any],
                    let options = items[enumKey] as? [String] {
                    type = .enumMultipleOptions(from: options)
                }
            case "number":
                type = .number
            case "integer":
                type = .integer
            case "boolean":
                type = .boolean
            default:
                break
            }
        }
        
        return (label: label, type: type)
    }
    
    func metadatumFor(group: String, key: String, value: Any) -> Metadatum {
        let type = self.type(for: group, withKey: key, value: value)
        let label = self.label(for: group, with: key)
        let displayValue = self.displayValue(for: value, type: type)
        
        return Metadatum(type: type, key: key, label: label, value: displayValue)
    }
    
    private func type(for group: String, withKey key: String, value: Any) -> MetadatumType {
        if let schemaType = schemaType(for: group, with: key) {
            return schemaType
        }
        
        var type = MetadatumType.unknown
        
        switch (value) {
        case is Int:
            type = .integer
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
    
    private func schemaType(for group: String, with key: String) -> MetadatumType? {
        return propertyMap[group]?[key]?.type
    }
    
    private func label(for group: String, with key: String) -> String {
        guard let groupSchema = propertyMap[group],
            let propertySchema = groupSchema[key] else {
                return key
        }
        return propertySchema.label ?? key
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
        let phoneRegex = "^\\(?[0-9]{3}\\)?-?[0-9]{3}-?[0-9]{4}"
        
        if string.range(of: emailRegex, options: [.regularExpression, .caseInsensitive], range: nil, locale: nil) != nil {
            type = .email
        } else if string.range(of: phoneRegex, options: [.regularExpression, .caseInsensitive], range: nil, locale: nil) != nil {
            type = .phoneNumber
        } else if string.toDate() != nil {
            type = .date
        } else if let url = URL(string: string), url.host != nil {
            type = .uri
        }
        return type
    }
}

