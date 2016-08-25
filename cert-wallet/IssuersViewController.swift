//
//  FirstViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import UIKit

class IssuersViewController: UITableViewController {
    private let archiveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Issuers")
    
    let cellReuseIdentifier = "IssuerTableViewCell"
    let segueToAddIssuerIdentifier = "AddIssuer"
    var issuers = [Issuer]()

//    @IBOutlet weak var keyPhraseLabel: UILabel!
    var keychain : Keychain?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadIssuers()
        
        let seedPhrase = Keychain.generateSeedPhrase()
        keychain = Keychain(seedPhrase: seedPhrase)
    }
    
    func saveIssuers() {
        let issuersCodingList: [[String : String]] = issuers.map({ $0.toDictionary() })
        NSKeyedArchiver.archiveRootObject(issuersCodingList, toFile: archiveURL.path)
    }
    
    func loadIssuers() {
        let codedIssuers : [[String : String]] = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? [[String: String]] ?? []
        issuers = codedIssuers.flatMap({ Issuer(dictionary: $0) })
    }
}

extension IssuersViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return issuers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        
        cell.textLabel?.text = "Issuer #\(indexPath.row): \(issuers[indexPath.row])"
        
        return cell
    }
}

extension IssuersViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueToAddIssuerIdentifier {
            let target = segue.destination as! AddIssuerViewController
            target.delegate = self
            target.keychain = keychain!
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
