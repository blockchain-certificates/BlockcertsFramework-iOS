//
//  ReceiptTests.swift
//  cert-wallet
//
//  Created by Kim Duffy on 8/29/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest
@testable import BlockchainCertificates

class ReceiptTests: XCTestCase {
    
    let v1_2signedValidFilename = "sample_signed_cert-valid-1.2.0"
    
    func testExpectingV1_2SignedCertificate() {
        // TODO: should test just the receipt part
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_2signedValidFilename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let certificate = try? CertificateParser.parse(data: file)
        XCTAssertNotNil(certificate)
        XCTAssertEqual(certificate?.version, .oneDotTwo)
        
        
        let receipt = certificate?.receipt
        
        let verifier = ReceiptVerifier()
        let valid : Bool = verifier.validate(receipt: receipt!, chain: .testnet)
        XCTAssertTrue(valid)
        
    }

    
}
