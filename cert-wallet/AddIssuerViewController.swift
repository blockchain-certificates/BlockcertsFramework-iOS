//
//  AddIssuerViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/25/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

class AddIssuerViewController: UIViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var publicKeyURLField: UITextField!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        print("Save tapped")
    }
    @IBAction func fieldEditingDidEnd(_ sender: UITextField) {
        validate()
    }
    
    func validate() {
        let nameCharacterCount = nameField.text?.characters.count ?? 0
        let publicKeyCharacterCount = publicKeyURLField.text?.characters.count ?? 0
        if nameCharacterCount > 0,
            publicKeyCharacterCount > 0,
            URL(string: publicKeyURLField.text!) != nil {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
