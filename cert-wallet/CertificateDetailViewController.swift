//
//  CertificateDetailViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/17/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit
import BlockchainCertificates

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
    let actions = [ "Validate" ] // , "Revoke"
    var rows : Int { return actions.count }
}

struct CertificateDisplay : TableSection {
    var identifier = "RenderedCertificateTableViewCell"
    let title : String? = nil
    let rows = 1
}


class CertificateDetailViewController: UITableViewController {
    var sections = [TableSection]()
    var certificate: Certificate? {
        didSet {
            generateSectionData()
        }
    }
    var inProgressRequest : CommonRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 45
        tableView.rowHeight = UITableViewAutomaticDimension
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
            CertificateDisplay(),
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
                "Public Key": certificate.recipient.publicAddress
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
    
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        guard let certificate = certificate else {
            return
        }
        
        // Moving the file to a temporary directory. Sharing a file URL seems to be better than sharing the file's contents directly.
        let filePath = "\(NSTemporaryDirectory())/certificate.json"
        let url = URL(fileURLWithPath: filePath)
        do {
            try certificate.file.write(to: url)
        } catch {
            print("Failed to write temporary URL")
            
            let errorAlert = UIAlertController(title: "Couldn't share certificate.", message: "Something went wrong preparing that file for sharing. Try again later.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(errorAlert, animated: true, completion: nil)
            return
        }

        let items : [Any] = [ url ]

        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        self.present(shareController, animated: true, completion: nil)
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
        
        if section is CertificateDisplay {
            if let renderedViewCell = cell as? RenderedCertificateTableViewCell,
                let certificate = certificate {
                renderedViewCell.nameText = "\(certificate.recipient.givenName) \(certificate.recipient.familyName)"
                renderedViewCell.titleText = certificate.title
                renderedViewCell.subtitleText = certificate.subtitle
                renderedViewCell.certificateIcon = UIImage(data: certificate.image)
                renderedViewCell.descriptionText = certificate.description
                renderedViewCell.sealIcon = UIImage(data: certificate.issuer.image)
            }
        } else if let section = section as? CertificateActions {
            let action = section.actions[indexPath.row]
            cell.textLabel?.text = action
            if action == "Revoke" {
                cell.textLabel?.textColor = UIColor.red
            } else {
                cell.textLabel?.textColor = cell.tintColor
            }
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
        if let section = section as? CertificateActions {
            switch section.actions[indexPath.row] {
            case "Validate":
                // DEBUG HOOK
//                JSONLDProcessor.shared.compact(docData: certificate!.file, context: nil, callback: { (err, result) in
//                    print()
//                    print("err: \(err)")
//                    print()
//                    print("result: \(result)")
//                })
                
                switch certificate?.version {
                case .some(.oneDotOne):
                    promptForTransactionIDThenValidate()
                default:
                    validateCertificate()
                }
            case "Revoke":
                promptToRevokeCertificate()
            default:
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let section = sections[indexPath.section]
//        if section is CertificateDisplay {
//            return 220
//        } else {
//            return 44
//        }
//    }
    
    func promptForTransactionIDThenValidate() {
        let prompt = UIAlertController(title: "Transaction ID?", message: "What's the transaction ID for this certificate?", preferredStyle: .alert)
        prompt.addTextField(configurationHandler: nil)
        let action = UIAlertAction(title: "Validate", style: .default, handler: { [weak self, weak prompt] (action) in
            let transactionId = prompt?.textFields?.first?.text ?? ""
            self?.validateCertificate(with: transactionId)
        })
        prompt.addAction(action)
        
        present(prompt, animated: true, completion: nil)
    }
    
    func validateCertificate(with transactionId: String? = nil) {
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
        
        
        let completionHandler : (Bool, String?) -> Void = { [weak self] (success, errorMessage) in
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
            
            let showCompleteAlert : () -> Void = {
                self?.present(completeAlert, animated: false) { () in
                    if let selectedIndexPath = self?.tableView.indexPathForSelectedRow {
                        self?.tableView.deselectRow(at: selectedIndexPath, animated: true)
                    }
                }
            }
            if self?.presentedViewController != nil {
                self?.presentedViewController?.dismiss(animated: false, completion: showCompleteAlert)
            } else {
                showCompleteAlert()
            }
        }
        
        inProgressRequest?.abort()
        if let transactionId = transactionId {
            inProgressRequest = CertificateValidationRequest(for: certificate,
                                                             with: transactionId,
                                                             bitcoinManager: CoreBitcoinManager(),
                                                             completionHandler: completionHandler)
        } else {
            inProgressRequest = CertificateValidationRequest(for: certificate,
                                                             bitcoinManager: CoreBitcoinManager(),
                                                             completionHandler: completionHandler)
        }
        
        inProgressRequest?.start()
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
            self?.inProgressRequest?.abort()
            self?.inProgressRequest = nil
            
            if let selectedIndexPath = self?.tableView.indexPathForSelectedRow {
                self?.tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
        let validatingAlert = UIAlertController(title: nil, message: "Validating this certificate...", preferredStyle: .alert)
        validatingAlert.addAction(cancelAction)
        present(validatingAlert, animated: true, completion: nil)
    }
    
    func promptToRevokeCertificate() {
        let revokeConfirmation = UIAlertController(title: "Revoke Certificate?", message: "Revoking a certificate is permanent. Are you sure you want to revoke this certificate?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
            if let selectedRow = self?.tableView.indexPathForSelectedRow {
                self?.tableView.deselectRow(at: selectedRow, animated: true)
            }
        }
        let revokeAction = UIAlertAction(title: "Revoke", style: .destructive) { [weak self] (action) in
            self?.revokeCertificate()
        }

        revokeConfirmation.addAction(cancelAction)
        revokeConfirmation.addAction(revokeAction)
        
        present(revokeConfirmation, animated: true, completion: nil)
    }
    
    func revokeCertificate() {
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

        inProgressRequest?.abort()
        inProgressRequest = CertificateRevocationRequest(revoking: certificate) { [weak self] (success, error) in
            if success {
                completeAlert.title = "Success"
                completeAlert.message = "Certificate successfully revoked."
            } else {
                completeAlert.title = "Error"
                if let error = error {
                    completeAlert.message = "This certificate couldn't be revoked: \(error)"
                } else {
                    completeAlert.message = "This certificate couldn't be revoked."
                }
            }
            
            let showCompleteAlert : () -> Void = {
                self?.present(completeAlert, animated: false) { () in
                    if let selectedIndexPath = self?.tableView.indexPathForSelectedRow {
                        self?.tableView.deselectRow(at: selectedIndexPath, animated: true)
                    }
                }
            }
            if self?.presentedViewController != nil {
                self?.presentedViewController?.dismiss(animated: false, completion: showCompleteAlert)
            } else {
                showCompleteAlert()
            }
        }
        inProgressRequest?.start()
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
            self?.inProgressRequest?.abort()
            self?.inProgressRequest = nil
            
            if let selectedIndexPath = self?.tableView.indexPathForSelectedRow {
                self?.tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
        let validatingAlert = UIAlertController(title: nil, message: "Revoking this certificate...", preferredStyle: .alert)
        validatingAlert.addAction(cancelAction)
        present(validatingAlert, animated: true, completion: nil)
    }
    
}

