//
//  DocumentPickerViewController.swift
//  ImportAction
//
//  Created by Chris Downie on 9/15/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

class DocumentPickerViewController: UIDocumentPickerExtensionViewController {
    let certificates = [Certificate]()
    
    @IBOutlet weak var tableView: UITableView!

    @IBAction func openDocument(_ sender: AnyObject?) {
        let documentURL = self.documentStorageURL!.appendingPathComponent("Untitled.txt")
        
        // TODO: if you do not have a corresponding file provider, you must ensure that the URL returned here is backed by a file
        self.dismissGrantingAccess(to: documentURL)
    }
    
    override func prepareForPresentation(in mode: UIDocumentPickerMode) {
        // TODO: present a view controller appropriate for picker mode here
    }

}

extension DocumentPickerViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certificates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CertificateTableViewCell")!
        let certificate = certificates[indexPath.row]
        
        cell.textLabel?.text = certificate.title
        cell.detailTextLabel?.text = certificate.subtitle
        cell.imageView?.image = UIImage(data: certificate.image)
        
        return cell
    }
}

extension DocumentPickerViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let certificate = certificates[indexPath.row]
        
        print("Selected cert \(certificate)")
    }
}
