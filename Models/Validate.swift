//
//  Validate.swift
//  cert-wallet
//
//  Created by Kim Duffy on 8/17/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import Foundation


enum CertificateValidator {
    
    static func validate(transaction_id: String, certificate: Certificate) -> Bool {
        //let local_hash = computeHash(certificate)
        //let remote_hash = fetchHashFromChain(remote_json)
        //let signer_url = certificate.issuer.id
        //let keys = get_issuer_keys(signer_url)
        
        //let issuing_address = keys["issuer_key"][0]["key"]
        //let revocation_address = keys["revocation_key"][0]["key"]
        callUrl()
        return false
        
    }
    
    static func callUrl() {
        let requestURL: NSURL = NSURL(string: "http://www.learnswiftonline.com/Samples/subway.json")!

        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        let session = URLSession.shared
        let task : URLSessionDataTask = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Everyone is fine, file downloaded successfully.")
            }
        }
        
        task.resume()
        
    }

    /*
    r = requests.get("https://blockchain.info/rawtx/%s?cors=true" % transaction_id)
    verify_response = []
    verified = False
    if r.status_code != 200:
    logging.error(
    "Error looking up by transaction_id=%s, status_code=%d",transaction_id, r.status_code)
    verify_response.append(("Looking up by transaction_id", False))
    verify_response.append(("Verified", False))
    else:
    verify_response.append(
    ("Computing SHA256 diges/Users/kim/projects/cert-wallet/cert-walletTests/CertificateV1_1Tests.swiftt of local certificate", "DONE"))
    verify_response.append(("Fetching hash in OP_RETURN field", "DONE"))
    remote_json = r.json()
    
    # compare hashes

    compare_hash_result = compare_hashes(local_hash, remote_hash)
    verify_response.append(
    ("Comparing local and blockchain hashes", compare_hash_result))
    
    # check author

    

    verify_authors = check_author(issuing_address, signed_local_json)
    verify_response.append(("Checking signature", verify_authors))
    
    # check revocation

    not_revoked = check_revocation(remote_json, revocation_address)
    verify_response.append(("Checking not revoked by issuer", not_revoked))
    
    if compare_hash_result and verify_authors and not_revoked:
    verified = True
    verify_response.append(("Verified", verified))
    return verify_response
    
    func get_issuer_keys(signer_url: URL) {
        r = requests.get(signer_url)
        remote_json = None
        if r.status_code != 200 {
            //logging.error("Error looking up issuer keys at url=%s, status_code=%d",signer_url, r.status_code)
        } else {
            remote_json = r.json()
            //logging.info("Found issuer keys at url=%s", signer_url)
        }
        return remote_json
    
    
    func get_hash_from_bc_op(tx_json) {
        tx_outs = tx_json["out"]
        op_tx = None
        for o in tx_outs {
            if int(o.get("value", 1)) == 0 {
                op_tx = o
            }
        if not op_tx {
            raise InvalidTransactionError("transaction is missing op_return")
        }
        hashed_json = unhexlify(op_tx["script"])
        return hashed_json
    }
    
    
    func check_revocation(tx_json, revoke_address) {
        tx_outs = tx_json["out"]
        for o in tx_outs {
            if o.get("addr") == revoke_address and o.get("spent") is False {
                return True
            }
        }
        return False
    }
    
    
    func compute_hash(doc) {
        let doc_bytes = doc
        if not isinstance(doc, (bytes, bytearray)) {
            doc_bytes = doc.encode("utf-8")
        }
        return hashlib.sha256(doc_bytes).hexdigest()
    }
    
    
    func fetch_hash_from_chain(tx_json) {
        let hash_from_bc = hexlify(get_hash_from_bc_op(tx_json))
        return hash_from_bc
    }
    
    func compare_hashes(hash1, hash2) {
        if hash1 in hash2 or hash1 == hash2 {
            return True
        }
        return False
    }
    
    func check_author(address, signed_json) {
        let uid = signed_json["assertion"]["uid"]
        let message = BitcoinMessage(uid)
        if signed_json.get("signature", None) {
            signature = signed_json["signature"]
            logging.debug("Found signature for uid=%s; verifying message", uid)
            return VerifyMessage(address, message, signature)
        }
        logging.warning("Missing signature for uid=%s", uid)
        return False
    }*/

}
