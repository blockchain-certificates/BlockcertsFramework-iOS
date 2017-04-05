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
        XCTFail("Not implemented")
    }
    
    func testMultipleGroupsWithNoVisibleData() {
        XCTFail("Not implemented")
    }
    
    func testSingleGroupWithVisibleData() {
        XCTFail("Not implemented")
    }
    
    func testMultipleGroupsWithVisibleData() {
        XCTFail("Not implemented")
    }
    
    func testTypeInference() {
        XCTFail("Not implemented")
    }
}
