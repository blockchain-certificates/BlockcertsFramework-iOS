//
//  CertificateDetailViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/17/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

protocol TableSection {
    var identifier: String { get }
    var title: String? { get }
    var rows: Int { get }
}

struct CertificateProperty : TableSection {
    let identifier = "CertificateDetailTableViewCell"
    let title : String?
    let values : [String : String]
    var rows : Int { return values.keys.count }
}

struct CertificateActions : TableSection {
    let identifier = "CertificateActionsTableViewCell"
    let title : String? = "Actions"
    let rows = 1
}


class CertificateDetailViewController: UITableViewController {
    
    var sections = [TableSection]()
    var certificate: Certificate? {
        didSet {
            generateSectionData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = certificate?.title ?? "CertiFicate"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func generateSectionData() {
        guard let certificate = certificate else {
            sections = []
            return
        }

        // Details
        sections = [
            CertificateActions(),
            CertificateProperty(title: "Details", values: [
                "Title": certificate.title,
                "Subtitle": certificate.subtitle ?? "",
                "Description": certificate.description,
                "Language": certificate.language,
                "ID": "\(certificate.id)"
            ]),
            CertificateProperty(title: "Issuer", values: [
                "Name": certificate.issuer.name,
                "Email": certificate.issuer.email,
                "ID": "\(certificate.issuer.id)",
                "URL": "\(certificate.issuer.url)"
            ]),
            CertificateProperty(title: "Recipient", values: [
                "Given Name": certificate.recipient.givenName,
                "Family Name": certificate.recipient.familyName,
                "Identity": certificate.recipient.identity,
                "Identity Type": certificate.recipient.identityType,
                "Hashed?": "\(certificate.recipient.isHashed)",
                "Public Key": certificate.recipient.publicKey
            ]),
            CertificateProperty(title: "Assertion", values: [
                "Issued On": "\(certificate.assertion.issuedOn)",
                "Evidence": certificate.assertion.evidence,
                "UID": certificate.assertion.uid,
                "ID": "\(certificate.assertion.id)"
            ]),
            CertificateProperty(title: "Verify", values: [
                "Signer": "\(certificate.verifyData.signer)",
                "Signed Attribute": certificate.verifyData.signedAttribute,
                "Type": certificate.verifyData.type
            ])
        ]
    }
}

// MARK: Table View Controller overrides
extension CertificateDetailViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: section.identifier)!
        
        if section is CertificateActions {
            cell.textLabel?.text = "Validate"
        } else if let section = section as? CertificateProperty {
            let values = section.values
            let sortedKeys = values.keys.sorted(by: <)
            let thisKey = sortedKeys[indexPath.row]
            let thisValue = values[thisKey]
            
            cell.textLabel?.text = thisKey
            cell.detailTextLabel?.text = thisValue
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if section is CertificateActions {
            let prompt = UIAlertController(title: "Transaction ID?", message: "What's the transaction ID for this certificate?", preferredStyle: .alert)
            prompt.addTextField(configurationHandler: nil)
            
            prompt.addAction(UIAlertAction(title: "Validate", style: .default, handler: { [weak self, weak prompt] (action) in
                let transactionId = prompt?.textFields?.first?.text ?? ""
                self?.validateCertificate(with: transactionId)
            }))
                
            present(prompt, animated: true, completion: nil)
            
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func validateCertificate(with transactionId: String) {
        let dismissAction = UIAlertAction(title: "OK", style: .default) { [weak self] (action) in
            if let selectedIndexPath = self?.tableView.indexPathForSelectedRow {
                self?.tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
        let completeAlert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        completeAlert.addAction(dismissAction)
        
        guard let certificate = certificate else {
            completeAlert.title = "Error"
            completeAlert.message = "Certificate is missing. Try again?"
            present(completeAlert, animated: true, completion: nil)
            return
        }
        
        let validationRequest = CertificateValidationRequest(for: certificate, with: transactionId, starting: false) { [weak self] (success, errorMessage) in
            if success {
                completeAlert.title = "Success"
                completeAlert.message = "This is a valid certificate!"
            } else {
                completeAlert.title = "Invalid"
                if let error = errorMessage {
                    completeAlert.message = "This certificate isn't valid: \(error)"
                } else {
                    completeAlert.message = "This certificate isn't valid."
                }
            }
            
            self?.present(completeAlert, animated: true) { () in
                if let selectedIndexPath = self?.tableView.indexPathForSelectedRow {
                    self?.tableView.deselectRow(at: selectedIndexPath, animated: true)
                }
            }
        }
        
        validationRequest.start()
    }
    
}

