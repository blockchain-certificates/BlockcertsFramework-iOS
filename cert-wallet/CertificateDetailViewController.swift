//
//  CertificateDetailViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/17/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

struct CertificateProperty {
    let title : String
    let values : [String : String]
}


class CertificateDetailViewController: UITableViewController {
    let cellReuseIdentifier = "CertificateDetailTableViewCell"
    var sections = [CertificateProperty]()
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
        // Details
        sections = [
            CertificateProperty(title: "Details", values: [
                "Title": certificate?.title ?? "",
                "Subtitle": certificate?.subtitle ?? "",
                "Description": certificate?.description ?? "",
                "Language": certificate?.language ?? "",
//                "Id": "\(certificateId)"
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
        let values = sections[section].values
        return values.keys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        
        let values = sections[indexPath.section].values
        let sortedKeys = values.keys.sorted(by: <)
        let thisKey = sortedKeys[indexPath.row]
        let thisValue = values[thisKey]
        
        cell.textLabel?.text = thisKey
        cell.detailTextLabel?.text = thisValue
        
        return cell
    }
    
}

