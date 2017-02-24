//
//  FirstViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import UIKit
import BlockchainCertificates

class IssuersViewController: UITableViewController {
    private let archiveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Issuers")
    
    let cellReuseIdentifier = "IssuerTableViewCell"
    let segueToAddIssuerIdentifier = "AddIssuer"
    var issuers = [Issuer]()

//    @IBOutlet weak var keyPhraseLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadIssuers()
        NotificationCenter.default.addObserver(self, selector: #selector(loadIssuers), name: NotificationNames.allDataReset, object: nil)
    }
    
    func saveIssuers() {
        let issuersCodingList: [[String : Any]] = issuers.map({ $0.toDictionary() })
        NSKeyedArchiver.archiveRootObject(issuersCodingList, toFile: archiveURL.path)
    }
    
    func loadIssuers() {
        let codedIssuers = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? [[String: Any]] ?? []
        issuers = codedIssuers.flatMap({ try? Issuer(dictionary: $0) })
        tableView.reloadData()
    }
}

extension IssuersViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return issuers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        let issuer = issuers[indexPath.row]
        
        cell.textLabel?.text = issuer.name
        cell.imageView?.image = UIImage(data: issuer.image)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (action, indexPath) in
            self?.issuers.remove(at: indexPath.row)
            self?.saveIssuers()
            self?.tableView.reloadData()
        }
        return [ deleteAction ]
    }
}

extension IssuersViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueToAddIssuerIdentifier {
            let target = segue.destination as! AddIssuerViewController
            target.delegate = self
        }
    }
}

extension IssuersViewController : AddIssuerViewControllerDelegate {
    func created(issuer: Issuer) {
        issuers.append(issuer)
        
        saveIssuers()
        // TODO: Possibly make this an add animation rather than simply reloading the data.
        tableView.reloadData()
    }
}
