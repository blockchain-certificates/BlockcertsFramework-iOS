//
//  SecondViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import UIKit

class CertificatesViewController: UITableViewController {
    var certificates = [Certificate]()
    let cellReuseIdentifier = "CertificateTableViewCell"
    let detailSegueIdentifier = "CertificateDetail"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadCertificates()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let controller = UIDocumentPickerViewController(documentTypes: ["public.content"], in: .import)
        controller.delegate = self
        controller.modalPresentationStyle = .formSheet
        
        present(controller, animated: true, completion: nil)
    }
    
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
            
            let documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let documentsDirectory = URL(fileURLWithPath: documentsDirectoryPath)
            let certificateFilename = self?.filenameFor(certificate: deletedCertificate) ?? ""
            let filePath = URL(fileURLWithPath: certificateFilename, relativeTo: documentsDirectory)
            do {
                try FileManager.default.removeItem(at: filePath)
                tableView.reloadData()
            } catch {
                self?.certificates.insert(deletedCertificate, at: indexPath.row)
                
                let alertController = UIAlertController(title: "Couldn't delete file", message: "Something went wrong deleting that certificate.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            }
            
        }
        return [ deleteAction ]
    }
    
    func loadCertificates() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard paths.count > 0 else {
            // TODO: How to handle being unable to find the document Directory
            return
        }
        let documentsDirectory = paths[0]
        let directoryUrl = URL(fileURLWithPath: documentsDirectory)
        let filenames = (try? FileManager.default.contentsOfDirectory(atPath: documentsDirectory)) ?? []
        
        filenames.forEach { (filename) in
            if let data = try? Data(contentsOf: URL(fileURLWithPath: filename, relativeTo: directoryUrl)),
                let certificate = CertificateParser.parse(data: data) {
                    certificates.append(certificate)
            } else {
                // TODO: What to do here?
                print("Existing file \(filename) is an invalid certificate.")
            }
        }
    }
    
    func filenameFor(certificate : Certificate) -> String {
        return "\(certificate.id)".replacingOccurrences(of: "/", with: "_")
    }
}

extension CertificatesViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let data = try? Data(contentsOf: url) else {
            let alertController = UIAlertController(title: "Couldn't read file", message: "Something went wrong trying to open the file.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] action in
                alertController?.dismiss(animated: true, completion: nil)
            }))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        guard let certificate = CertificateParser.parse(data: data) else {
            let alertController = UIAlertController(title: "Invalid Certificate", message: "That doesn't appear to be a valid Certificate file.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] action in
                alertController?.dismiss(animated: true, completion: nil)
            }))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        // At this point, data is totally a valid certificate. Let's save that to the documents directory.
        let filename = filenameFor(certificate: certificate)
        let didSave = save(certificateData: data, withFilename: filename)
        if didSave {
            print("Save worked")
        } else {
            print("Save failed")
        }

        // TODO: We should check and see if that cert is already in the array.

        certificates.append(certificate)
        
        // TODO: We should do an insert animation rather than a full table reload.
        tableView.reloadData()
    }
    
    func save(certificateData data: Data, withFilename filename: String) -> Bool {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard paths.count > 0 else {
            // TODO: How to handle being unable to find the document Directory
            return false
        }
        let documentsDirectory = paths[0]
        let filePath = "\(documentsDirectory)/\(filename)"
        if FileManager.default.fileExists(atPath: filePath) {
            print("File \(filename) already exists")
            // TODO: Should we make a copy? Check if it's equal?
            return false
        } else {
            // TODO: What file attributes would be useful here?
            return FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
        }
    }
}
