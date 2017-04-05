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
    
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//    
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
    
    func testNoData() {
        let data = Metadata(json: [:])
        
        XCTAssert(data.groups.isEmpty)
        XCTAssert(data.visibleMetadata.isEmpty)
        
        XCTAssert(data.metadataFor(group: "anything").isEmpty)
        XCTAssertNil(data.metadatumFor(dotPath: "anything.else"))
    }
    
    func testSingleGroupWithNoVisibleData() {
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
        
        let metadataum = data.metadatumFor(dotPath: "\(group).\(key)")
        XCTAssertNotNil(metadataum)
        XCTAssertEqual(metadataum?.value, value)
        
        XCTAssert(data.visibleMetadata.isEmpty)
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
}
