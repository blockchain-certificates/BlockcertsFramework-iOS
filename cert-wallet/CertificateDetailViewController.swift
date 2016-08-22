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
        // Details
        sections = [
            CertificateActions(),
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
    
}

