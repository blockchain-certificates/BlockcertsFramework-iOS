//
//  DocumentPickerViewController.swift
//  ImportAction
//
//  Created by Chris Downie on 9/15/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit
import Blockcerts

class DocumentPickerViewController: UIDocumentPickerExtensionViewController {
    var certificates = [(URL, Certificate)]()
    var incomingCertificate : Certificate?
    
    var fileCoordinator : NSFileCoordinator {
        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.purposeIdentifier = self.providerIdentifier
        return fileCoordinator
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var exportView: UIView!
    @IBOutlet weak var successEmojiLabel: UILabel!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!

    override func prepareForPresentation(in mode: UIDocumentPickerMode) {
        // We may not need to do this every time.
        
        switch mode {
        case .exportToService, .moveToService:
            successEmojiLabel.text = "⌛️"
            explanationLabel.text = "Validating file..."
            confirmButton.isHidden = true
            validateCertificate(at: originalURL)
        case .open, .import:
            loadCertificates()
            exportView.isHidden = true
        }
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        guard let sourceURL = originalURL,
            let certificate = incomingCertificate else {
            return
        }
        
        switch documentPickerMode {
        case .moveToService, .exportToService:
            let fileName = "\(certificate)".replacingOccurrences(of: "/", with: "_")
            let certificateDirectory = URL(string: Paths.certificateDirectory)
            let destinationURL = URL(fileURLWithPath: fileName, relativeTo: certificateDirectory)
            fileCoordinator.coordinate(readingItemAt: sourceURL, options: .withoutChanges, error: nil, byAccessor: { (newURL) in
                do {
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                    self.dismissGrantingAccess(to: destinationURL)
                } catch {
                    print("Error copying \(sourceURL) to \(destinationURL)")
                }
            })

        default:
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func loadCertificates() {
        let documentsDirectory = Paths.certificateDirectory
        let directoryUrl = URL(fileURLWithPath: documentsDirectory)
        let filenames = (try? FileManager.default.contentsOfDirectory(atPath: documentsDirectory)) ?? []
        
        certificates = filenames.compactMap { (filename) in
            let fileURL = URL(fileURLWithPath: filename, relativeTo: directoryUrl)
            guard let data = try? Data(contentsOf: fileURL),
                let certificate = try? CertificateParser.parse(data: data) else {
                    // Certificate is invalid. Don't load it.
                    return nil
            }
            return (fileURL, certificate)
        }
        
        tableView.reloadData()

    }
    
    private func validateCertificate(at url: URL?) {
        guard let url = url else {
            successEmojiLabel.text = "⛔"
            explanationLabel.text = "No document provided."
            return
        }
        
        // TODO: Use the fileCoordinator before this access of the url here.
        
        var certificate : Certificate?
        do {
            let data = try Data(contentsOf: url)
            certificate = try CertificateParser.parse(data: data)
        } catch {
            certificate = nil
        }

        if certificate != nil {
            successEmojiLabel.text = "✅"
            explanationLabel.text = "This is a valid Certificate!"
            confirmButton.isHidden = false
            
            incomingCertificate = certificate
        } else {
            successEmojiLabel.text = "⛔"
            explanationLabel.text = "That file is not a valid certificate."
        }

    }
}

extension DocumentPickerViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certificates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CertificateTableViewCell")!
        let (_, certificate) = certificates[indexPath.row]
        
        cell.textLabel?.text = certificate.title
        cell.detailTextLabel?.text = certificate.subtitle
        cell.imageView?.image = UIImage(data: certificate.image)
        
        return cell
    }
}

extension DocumentPickerViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let (fileURL, _) = certificates[indexPath.row]
        self.dismissGrantingAccess(to: fileURL)
    }
}
