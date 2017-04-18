//
//  MetadataTests.swift
//  cert-wallet
//
//  Created by Chris Downie on 4/5/17.
//  Copyright © 2017 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import BlockchainCertificates

class MetadataTests: XCTestCase {
    
    func testNoData() {
        let data = Metadata(json: [:])
        
        XCTAssert(data.groups.isEmpty)
        XCTAssert(data.visibleMetadata.isEmpty)
        
        XCTAssert(data.metadataFor(group: "anything").isEmpty)
        XCTAssertNil(data.metadatumFor(dotPath: "anything.else"))
    }
    
    func testMetadataForSingleGroup() {
        let group = "group1"
        let key = "key1"
        let value = "value1"
        let json : [String: Any] = [
            group: [
                key: value
            ]
        ]
        let data = Metadata(json: json)
        
        let groupMetadata = data.metadataFor(group: group)
        XCTAssertFalse(groupMetadata.isEmpty)
        XCTAssertEqual(groupMetadata.count, 1)
        
        XCTAssertEqual(groupMetadata.first?.value, value)
        XCTAssertEqual(groupMetadata.first?.label, key)
    }
    
    func testMetadatumForSingleDotPath() {
        let group = "group1"
        let key = "key1"
        let value = "value1"
        let json : [String: Any] = [
            group: [
                key: value
            ]
        ]
        let data = Metadata(json: json)
        
        let metadataum = data.metadatumFor(dotPath: "\(group).\(key)")
        XCTAssertNotNil(metadataum)
        XCTAssertEqual(metadataum?.value, value)
    }
    
    func testMultipleGroupsWithNoVisibleData() {
        let json : [String: Any] = [
            "group1": [
                "key1": "value1"
            ],
            "group2": [
                "key2": "value2",
                "key3": "value3"
            ]
        ]
        let data = Metadata(json: json)
        
        XCTAssertEqual(data.metadataFor(group: "group1").count, 1)
        XCTAssertEqual(data.metadataFor(group: "group2").count, 2)
        
        var existingDatum = data.metadatumFor(dotPath: "group1.key1")
        XCTAssertNotNil(existingDatum)
        XCTAssertEqual(existingDatum?.value, "value1")
        
        existingDatum = data.metadatumFor(dotPath: "group2.key3")
        XCTAssertNotNil(existingDatum)
        XCTAssertEqual(existingDatum?.value, "value3")
        
        let nonexistentDatum = data.metadatumFor(dotPath: "group2.key1")
        XCTAssertNil(nonexistentDatum)
        
        XCTAssert(data.visibleMetadata.isEmpty)
    }
    
    func testSingleGroupWithVisibleData() {
        let json : [String: Any] = [
            "group1": [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3",
            ],
            Metadata.visiblePathsKey : [
                "group1.key3", "group1.key1"
            ]
        ]
        let data = Metadata(json: json)

        XCTAssertEqual(data.visibleMetadata.count, 2)
        
        let firstDatum = data.visibleMetadata.first
        XCTAssertNotNil(firstDatum)
        XCTAssertEqual(firstDatum?.value, "value3")
        
        let lastDatum = data.visibleMetadata.last
        XCTAssertNotNil(lastDatum)
        XCTAssertEqual(lastDatum?.value, "value1")
    }
    
    func testMultipleGroupsWithVisibleData() {
        let json : [String: Any] = [
            "group1": [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3",
            ],
            "group2": [
                "key4": "value4",
                "key5": "value5"
            ],
            "group3": [
                "key6": "value6",
                "key7": "value7"
            ],
            Metadata.visiblePathsKey : [
                "group1.key3", "group2.key4", "group3.key7"
            ]
        ]
        let data = Metadata(json: json)
        
        XCTAssertEqual(data.visibleMetadata.count, 3)
        
        data.visibleMetadata.enumerated().forEach { (offset: Int, datum: Metadatum) in
            switch(offset) {
            case 0:
                XCTAssertEqual(datum.value, "value3")
            case 1:
                XCTAssertEqual(datum.value, "value4")
            case 2:
                XCTAssertEqual(datum.value, "value7")
            default:
                XCTFail("Test called with invalid offset: \(offset)")
            }
        }
    }
    
    func testTypeInference() {
        let json : [String: Any] = [
            "group": [
                "boolean": true,
                "number": 2,
                "date": "2017-03-13T08:57:03.811+00:00",
                "string": "value3",
                "uri": "https://learningmachine.com",
                "phone1": "(223)456-7890",
                "phone2": "2234567890",
                "email": "cdownie@learningmachine.com"
            ]
        ]
        let data = Metadata(json: json)
        
        XCTAssertEqual(data.metadatumFor(dotPath: "group.boolean")?.type, MetadatumType.boolean)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.number")?.type, MetadatumType.number)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.date")?.type, MetadatumType.date)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.string")?.type, MetadatumType.string)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.uri")?.type, MetadatumType.uri)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.phone1")?.type, MetadatumType.phoneNumber)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.phone2")?.type, MetadatumType.phoneNumber)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.email")?.type, MetadatumType.email)
    }
    
    func testSchemaWithStringValue() {
        let label = "This is the First Key"
        let value = "value1"
        let json : [String: Any] = [
            "$schema": [
                "$schema": "http://json-schema.org/draft-04/schema#",
                "type": "object",
                "properties": [
                    "group": [
                        "order": ["key1"],
                        "type": "object",
                        "properties": [
                            "key1": [
                                "title": label,
                                "type": "string"
                            ]
                        ]
                    ],
                ]
            ],
            "group": [
                "key1": value,
            ]
        ]
        let data = Metadata(json: json)
        
        let datum = data.metadatumFor(dotPath: "group.key1")
        XCTAssertNotNil(datum)
        XCTAssertEqual(datum?.type, MetadatumType.string)
        XCTAssertEqual(datum?.value, value)
        XCTAssertEqual(datum?.label, label)
    }
    
    
    func testSchemaTypesOverrideComputedTypes() {
        // This is a weird corner case, but useful for testing my parsing.
        // In this case, I'm going to have a URL value, but force it to be a string.
        
        let label = "This is the First Key"
        let value = "https://blockcerts.org"
        let json : [String: Any] = [
            "$schema": [
                "$schema": "http://json-schema.org/draft-04/schema#",
                "type": "object",
                "properties": [
                    "group": [
                        "order": ["key1"],
                        "type": "object",
                        "properties": [
                            "key1": [
                                "title": label,
                                "type": "string"
                            ]
                        ]
                    ],
                ]
            ],
            "group": [
                "key1": value,
            ]
        ]
        let data = Metadata(json: json)
        
        let datum = data.metadatumFor(dotPath: "group.key1")
        XCTAssertNotNil(datum)
        XCTAssertEqual(datum?.type, MetadatumType.string)
        XCTAssertEqual(datum?.value, value)
        XCTAssertEqual(datum?.label, label)
    }
    
    func testTypeInferenceWithASchema() {
        let json : [String: Any] = [
            "$schema": [
                "$schema": "http://json-schema.org/draft-04/schema#",
                "type": "object",
                "properties": [
                    "group": [
                        "order": ["text", "date", "email", "uri", "number", "wholeNumber", "singleEnum", "multipleEnum"],
                        "type": "object",
                        "properties": [
                            "text": [
                                "title": "Text title",
                                "type": "string",
                                "description": "What is this used for"
                            ],
                            "date": [
                                "type": "string",
                                "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",
                                "title": "Last Login",
                                "description": "The time the user last logged in."
                            ],
                            "email": [
                                "type": "string",
                                "format": "email",
                                "title": "Work Email",
                                "description": "The issuer contact's work email address."
                            ],
                            "uri": [
                                "type": "string",
                                "format": "uri",
                                "title": "homepage"
                            ],
                            "number": [
                                "type": "number",
                                "title": "GPA"
                            ],
                            "wholeNumber": [
                                "type": "integer",
                                "title": "Friend Count",
                                "description": "OK, not a perfect example..."
                            ],
                            "isBoolean": [
                                "type": "boolean",
                                "title": "is this a boolean?",
                                "description": "This is the first step towards computers being self aware."
                            ],
                            "singleEnum": [
                                "type": "string",
                                "enum": ["red", "blue", "orange"],
                                "title": "Favorite Color",
                                "description": "Don't say blue if it's really yellow."
                            ],
                            "multipleEnum": [
                                "type": "array",
                                "uniqueItems": true,
                                "items": [
                                    "type": "string",
                                    "enum": ["red", "orange", "yellow", "green", "blue", "violet"]
                                ],
                                "title": "Favorite Colors"
                            ]
                        ]
                    ],
                ]
            ],
            "group": [
                "text": "string",
                "date": "2017-01-01",
                "email": "cdownie@learningmachine.com",
                "uri": "https://blockcerts.org",
                "number": 3.7,
                "wholeNumber": 12,
                "isBoolean": true,
                "singleEnum": "blue",
                "multipleEnum": ["red", "blue"]
            ]
        ]
        let data = Metadata(json: json)
        
        XCTAssertNotNil(data)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.text")?.type, MetadatumType.string)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.date")?.type, MetadatumType.date)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.email")?.type, MetadatumType.email)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.uri")?.type, MetadatumType.uri)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.number")?.type, MetadatumType.number)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.wholeNumber")?.type, MetadatumType.number)
        XCTAssertEqual(data.metadatumFor(dotPath: "group.isBoolean")?.type, MetadatumType.boolean)
//        XCTAssertEqual(data.metadatumFor(dotPath: "group.singleEnum")?.type, MetadatumType.singleEnum)
//        XCTAssertEqual(data.metadatumFor(dotPath: "group.multipleEnum")?.type, MetadatumType.multipleEnum)
    }
}
