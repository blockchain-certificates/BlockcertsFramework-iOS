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

        // note that we need transactionOutputs for later; we need to determine if the revocation output is unspent...
        let transactionOutputs : Array<???> = parseTransactionOutputs(data: transactionData)
        // ...so parseOpReturn could just look for the transactionOutput with 0 output instead of re-parsing the json output
        let remoteHash : String = parseOpReturn(data: transactionData)
        let issuerKeys : IssuerKeys = parseIssuerKeys(data: issuerKeyData)
        
        print(remoteHash)
        print(issuerKeys.issuerKey)
        
        // compare local and remote hashes
        let localHash : String = computeHash(certificate)
        let compareHashResult : Bool = compareHashes(localHash, remoteHash)


        // verify author signature
        let authorSigned : Bool = checkAuthor(issuerKey: issuerKeys.issuerKey, certificate: certificate)
        
        let notRevoked = checkRevocation(revocationAddress: issuerKeys.revokeKey, transactionOutputs : )
        return compareHashResult && authorSigned && notRevoked
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
 
    static func parseTransactionOutputs(data:Data) -> String {
        do {
            let json  = try JSONSerialization.jsonObject(with: data) as! [String: AnyObject]
            if let outputs = json["out"] as? [[String: AnyObject]] {
                return outputs
            }
        } catch {
            print("error serializing JSON: \(error)")
        }
    }
    
    static func parseOpReturn(data:Data) -> String {
        do {
            let json  = try JSONSerialization.jsonObject(with: data) as! [String: AnyObject]
            if let outputs = json["out"] as? [[String: AnyObject]] {
                for output in outputs {
                    if output["value"] as? Int == 0 {
                        print(output["script"])
                        return output["script"]
                        // TODO convert this value to a hex string (python's hexlify) and return
                    }
                }
            }
        } catch {
            print("error serializing JSON: \(error)")
            return nil  // TODO
        }
    }
    
    
    static func parseIssuerKeys(data:Data) -> IssuerKeys {
        do {
            let json  = try JSONSerialization.jsonObject(with: data) as! [String: AnyObject]
            let issuing_address : String = json["issuer_key"][0]["key"] as? [[String: AnyObject]]
            let revocation_address : String = json["revocation_key"][0]["key"] as? [[String: AnyObject]]
            let issuerKeys : IssuerKeys = IssuerKeys(issuerKey: issuing_address, revokeKey: revocation_address)
            return issuerKeys
        } catch {
            print("error serializing JSON: \(error)")
            return nil  // TODO
        }
    }
    
    
    static func checkRevocation(revocationAddress : String, transactionOutputs : Array) {
        for o in transactionOutputs {
            if o.get("addr") == revocationAddress && !o.get("spent") {
                return True
            }
        }
        return False
     }
     
     
     static func computeHash(certificate) {
        // this takes a SHA256 hash of the raw certificate (file)
        let doc_bytes = certificate
        if not isinstance(doc, (bytes, bytearray)) {
            doc_bytes = doc.encode("utf-8")
        }
        return hashlib.sha256(doc_bytes).hexdigest()
        }
     
     
     static func compareHashes(hash1, hash2) {
        // we pass the local and remote hash (remote is what we got from the transaction lookup) and see if they match
        return hash1 in hash2 or hash1 == hash2
     }
     
     static func checkAuthor(issuerKey : String, certificate : Certificate) -> Bool {
        // verify that the certificate was signed by the issuer's issuerKey
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

struct IssuerKeys {
    let issuerKey : String
    let revokeKey : String
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
