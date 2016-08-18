//
//  CertificateValidatorTests.swift
//  cert-wallet
//
//  Created by Kim Duffy on 8/16/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import XCTest


enum CertificateValidator {
    //
    static func validate(transactionId: String, certificate: Certificate) -> Bool {
        
        
        let transactionUrl: URL = URL(string: String("https://blockchain.info/rawtx/" + transactionId + "?cors=true"))!
        let issuerUrl : URL = certificate.issuer.id
        
        let transactionData : Data = doRequest(theUrl : transactionUrl)
        let issuerKeyData : Data = doRequest(theUrl: issuerUrl)

        let remoteHash : String = parseOpReturn(data: transactionData)
        let issuerKeys : JSON = parseIssuerKeys(data: issuerKeyData)

        let issuing_address = issuerKeys["issuer_key"][0]["key"]
        let revocation_address = issuerKeys["revocation_key"][0]["key"]
        
        // compare local and remote hashes
        let local_hash = computeHash(certificate)
        let compare_hash_result = compare_hashes(local_hash, remoteHash)


        // verify author signature
        let verify_authors = checkAuthor(issuing_address, signed_local_json)
        
        not_revoked = checkRevocation(remote_json, revocation_address)
        return false
    }
    
    

    static func doRequest(theUrl : URL) -> Data {
        
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: theUrl as URL)
        let session = URLSession.shared
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var returnData : Data
        
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Everything is fine")
            }
            
            returnData = data!
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        return returnData
    }
    
    
    static func parseOpReturn(data:Data) -> String {
        do {
            let json  = try JSONSerialization.jsonObject(with: data) as! [String: AnyObject]
            if let outputs = json["out"] as? [[String: AnyObject]] {
                for output in outputs {
                    if output["value"] as? Int == 0 {
                        print(output["script"])
                    }
                }
            }
        } catch {
            print("error serializing JSON: \(error)")
        }
    }
    
    static func parseIssuerKeys(data:Data) -> JSON {
        do {
            let json  = try JSONSerialization.jsonObject(with: data) as! [String: AnyObject]
            return json
        } catch {
            print("error serializing JSON: \(error)")
        }
    }
    
     
     
     static func check_revocation(tx_json, revoke_address) {
        tx_outs = tx_json["out"]
        for o in tx_outs {
            if o.get("addr") == revoke_address and o.get("spent") is False {
                return True
            }
        }
        return False
     }
     
     
     static func computeHash(certificate) {
        let doc_bytes = certificate
        if not isinstance(doc, (bytes, bytearray)) {
            doc_bytes = doc.encode("utf-8")
        }
        return hashlib.sha256(doc_bytes).hexdigest()
        }
     
     
     static func fetch_hash_from_chain(tx_json) {
        let hash_from_bc = hexlify(get_hash_from_bc_op(tx_json))
        return hash_from_bc
     }
     
     static func compare_hashes(hash1, hash2) {
        return hash1 in hash2 or hash1 == hash2
     }
     
     static func check_author(address, signed_json) -> Bool {
        let uid = signed_json["assertion"]["uid"]
        let message = BitcoinMessage(uid)
        if signed_json.get("signature", None) {
            signature = signed_json["signature"]
            //logging.debug("Found signature for uid=%s; verifying message", uid)
            return VerifyMessage(address, message, signature)
        }
        logging.warning("Missing signature for uid=%s", uid)
        return false
     }
    
}


class CertificateValidatorTests: XCTestCase {
    let v1_1filename = "sample_signed_cert-1.1.0"
    let v1_1transactionId = "d5df311055bf0fe656b9d6fa19aad15c915b47303e06677b812773c37050e35d"
    
    // MARK: - Simple parse(data:) calls
    func testExpectingV1_1Certificate() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: v1_1filename, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
            return
        }
        
        let certificate = CertificateParser.parse(data: file)
        let result = CertificateValidator.validate(transactionId: v1_1transactionId, certificate: certificate!)
        print(result)
        
        XCTAssertNotNil(certificate)
        XCTAssert(result)
    }
    

}
