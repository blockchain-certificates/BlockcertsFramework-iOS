//
//  CertificateDetailViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/17/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

class CertificateDetailViewController: UITableViewController {
    let cellReuseIdentifier = "CertificateDetailTableViewCell"
    var certificate: Certificate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = certificate?.title ?? "CertiFicate"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: Table View Controller overrides
extension CertificateDetailViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        
        cell.textLabel?.text = "Title \(indexPath.row)"
        cell.detailTextLabel?.text = "Subtitle \(indexPath.row)"
        
        return cell
    }
    
}

