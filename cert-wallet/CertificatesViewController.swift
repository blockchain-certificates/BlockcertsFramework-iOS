//
//  SecondViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import UIKit

class CertificatesViewController: UITableViewController {
    let cellReuseIdentifier = "CertificateTableViewCell"
    let detailSegueIdentifier = "CertificateDetail"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func importTapped(_ sender: UIBarButtonItem) {
        let controller = UIDocumentPickerViewController(documentTypes: ["public.content"], in: .import)
        controller.delegate = self
        controller.modalPresentationStyle = .formSheet
        
        present(controller, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!

        cell.textLabel?.text = "Title \(indexPath.row)"
        cell.detailTextLabel?.text = "Subtitle \(indexPath.row)"

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.performSegue(withIdentifier: detailSegueIdentifier, sender: self)
    }
}

extension CertificatesViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("Got document at url: \(url)")
    }
}
