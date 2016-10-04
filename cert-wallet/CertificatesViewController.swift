//
//  SecondViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import UIKit
import BlockchainCertificates

class CertificatesViewController: UITableViewController {
    var certificates = [Certificate]()
    let cellReuseIdentifier = "CertificateTableViewCell"
    let detailSegueIdentifier = "CertificateDetail"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadCertificates()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadCertificates), name: NotificationNames.allDataReset, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleImportNotification(_:)), name: NotificationNames.importCertificate, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == detailSegueIdentifier {
            let destination = segue.destination as? CertificateDetailViewController
            if let selectedIndex = tableView.indexPathForSelectedRow?.row {
                destination?.certificate = certificates[selectedIndex]
            } else {
                destination?.certificate = nil
            }
        }
    }


    @IBAction func importTapped(_ sender: UIBarButtonItem) {
        let whichImport = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        whichImport.addAction(UIAlertAction(title: "Import File", style: .default, handler: { (action) in
            let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
            controller.delegate = self
            controller.modalPresentationStyle = .formSheet
            
            self.present(controller, animated: true, completion: nil)
        }))
        
        whichImport.addAction(UIAlertAction(title: "Import from URL", style: .default, handler: { (action) in
            let urlPrompt = UIAlertController(title: nil, message: "Enter the URL to import from below", preferredStyle: .alert)
            urlPrompt.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "URL"
            })
            
            urlPrompt.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in
                guard let urlField = urlPrompt.textFields?.first,
                    let trimmedText = urlField.text?.trimmingCharacters(in: CharacterSet.whitespaces),
                    let url = URL(string: trimmedText) else {
                    return
                }

                self.importCertificate(at: url)
            }))

            self.present(urlPrompt, animated: true, completion: nil)
        }))
        
        whichImport.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(whichImport, animated: true, completion: nil)
    }
}

// UITableViewDelegate
extension CertificatesViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certificates.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        let certificate = certificates[indexPath.row]
        
        cell.textLabel?.text = certificate.title
        cell.detailTextLabel?.text = certificate.subtitle
        cell.imageView?.image = UIImage(data: certificate.image)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (action, indexPath) in
            let deletedCertificate : Certificate! = self?.certificates.remove(at: indexPath.row)
            
            let documentsDirectory = URL(fileURLWithPath: Paths.certificateDirectory)
            let certificateFilename = deletedCertificate.assertion.uid
            let filePath = URL(fileURLWithPath: certificateFilename, relativeTo: documentsDirectory)
            
            let coordinator = NSFileCoordinator()
            var coordinationError : NSError?
            coordinator.coordinate(writingItemAt: filePath, options: [.forDeleting], error: &coordinationError, byAccessor: { (file) in
                
                do {
                    try FileManager.default.removeItem(at: filePath)
                    tableView.reloadData()
                } catch {
                    print(error)
                    self?.certificates.insert(deletedCertificate, at: indexPath.row)
                    
                    let alertController = UIAlertController(title: "Couldn't delete file", message: "Something went wrong deleting that certificate.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alertController, animated: true, completion: nil)
                }
            })
            
            if let error = coordinationError {
                print("Coordination failed with \(error)")
            } else {
                print("Coordinatoin went fine.")
            }
            
        }
        return [ deleteAction ]
    }
    
}

// MARK - Import handling code.
extension CertificatesViewController {
    func handleImportNotification(_ note: Notification) {
        guard let fileURL = note.object as? URL else {
            // This is a developer failure. It means we sent the notification without a URL paylaod. No need to inform the user. 
            return
        }
        let existingCertificateCount = certificates.count
        let data = try? Data(contentsOf: fileURL)
        
        importCertificate(from: data)
        
        if certificates.count > existingCertificateCount {
            let lastRow = IndexPath(row: certificates.count - 1, section: 0)
            tableView.selectRow(at: lastRow, animated: true, scrollPosition: .none)
            performSegue(withIdentifier: detailSegueIdentifier, sender: nil)
        } else {
            let alertController = UIAlertController(title: "Import failed", message: "It doesn't look like that's a valid certificate", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    /// Import from a URL. This may or may not be a known certificate, and we might need to send special query params in order to get it in the right JSON format.
    ///
    /// - parameter url: A URL where you hope a certificate resides.
    func importCertificate(at url: URL) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let formatQueryItem = URLQueryItem(name: "format", value: "json")
        
        if components?.queryItems == nil {
            components?.queryItems = [
                formatQueryItem
            ]
        } else {
            components?.queryItems?.append(formatQueryItem)
        }
        
        var data: Data? = nil
        if let dataURL = components?.url {
            data = try? Data(contentsOf: dataURL)
        }
        
        importCertificate(from: data)
    }
    
    /// This should be called when you're reasonably certain that `data` is a JSON file with Certificate data.
    ///
    /// - parameter data: JSON data representing the Certificate.
    func importCertificate(from data: Data?) {
        guard let data = data else {
            let alertController = UIAlertController(title: "Couldn't read file", message: "Something went wrong trying to open the file.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] action in
                alertController?.dismiss(animated: true, completion: nil)
                }))
            present(alertController, animated: true, completion: nil)
            return
        }
        guard let certificate = try? CertificateParser.parse(data: data) else {
            let alertController = UIAlertController(title: "Invalid Certificate", message: "That doesn't appear to be a valid Certificate file.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] action in
                alertController?.dismiss(animated: true, completion: nil)
                }))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        // At this point, data is totally a valid certificate. Let's save that to the documents directory.
        let filename = certificate.assertion.uid
        let success = save(certificateData: data, withFilename: filename)
        let isCertificateInList = certificates.contains(where: { $0.assertion.uid == certificate.assertion.uid })
            
        if isCertificateInList {
            let alertController = UIAlertController(title: "File already imported", message: "You've already imported that file.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else if !success {
            let alertController = UIAlertController(title: "Failed to save file", message: "Try importing the file again. ", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            certificates.append(certificate)
            
            // Issue #20: We should do an insert animation rather than a full table reload.
            // https://github.com/blockchain-certificates/cert-wallet/issues/20
            tableView.reloadData()
        }
    }

    func loadCertificates() {
        let documentsDirectory = Paths.certificateDirectory
        let directoryUrl = URL(fileURLWithPath: documentsDirectory)
        let filenames = (try? FileManager.default.contentsOfDirectory(atPath: documentsDirectory)) ?? []
        
        certificates = filenames.flatMap { (filename) in
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: filename, relativeTo: directoryUrl)),
                let certificate = try? CertificateParser.parse(data: data) else {
                    // Certificate is invalid. Don't load it.
                    return nil
            }
            return certificate
        }
        
        tableView.reloadData()
    }
    
    /// Saves the certificate data to the specified file name. If the file already exists, then data is not overwritten. In theory, since all certificates have unique IDs, then writing data to disk that's already there.
    ///
    /// - parameter data:     Data to write to disk. This *should* be the JSON-encoded data for a certificate
    /// - parameter filename: The filename to write the data to.
    ///
    /// - returns: True if the write succeeds. False otherwise.
    @discardableResult func save(certificateData data: Data, withFilename filename: String) -> Bool {
        let documentsDirectory = Paths.certificateDirectory
        let filePath = "\(documentsDirectory)/\(filename)"
        if FileManager.default.fileExists(atPath: filePath) {
            print("File \(filename) already exists")
            return false
        } else {
            let url = URL(fileURLWithPath: filePath)
            var success = true
            do {
                try data.write(to: url)
            } catch {
                print("Failed to save file with error : \(error)")
                success = false
            }
            
            return success
        }
    }
}

extension CertificatesViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let data = try? Data(contentsOf: url)
        
        importCertificate(from: data)
    }
}
