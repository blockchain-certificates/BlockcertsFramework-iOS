//
//  FirstViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/8/16.
//  Copyright © 2016 Digital Certificates Project.
//

import UIKit

class IssuersViewController: UITableViewController {
    let cellReuseIdentifier = "IssuerTableViewCell"
    var issuers = Array(repeating: 17, count: 5)

//    @IBOutlet weak var keyPhraseLabel: UILabel!
    var keychain : Keychain?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let seedPhrase = Keychain.generateSeedPhrase()
        keychain = Keychain(seedPhrase: seedPhrase)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func addIssuerTapped(_ sender: UIBarButtonItem) {
        issuers.append(0)
        tableView.reloadData()
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

