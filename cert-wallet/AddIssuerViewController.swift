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
    
    @IBOutlet weak var publicKeyURLField: UITextField!
    @IBOutlet weak var firstNamefield: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailAddressField: UITextField!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        print("Save tapped")
    }
    @IBAction func fieldEditingDidEnd(_ sender: UITextField) {
        validate()
    }
    
    // MARK - Form validation functions
    private func validate() {
        saveButton.isEnabled = areAllFieldsValid()
    }
    
    private func areAllFieldsValid() -> Bool {
        guard isIssuerURLValid() else {
            return false
        }
        return true
    }
    
    private func isIssuerURLValid() -> Bool {
        guard let issuerURLString = publicKeyURLField.text else {
            return false
        }
        guard URL(string: issuerURLString) != nil else {
            return false
        }
        return true
    }
    
    private func isFirstNameValid() -> Bool {
        guard let nameString = firstNamefield.text else {
            return false
        }
        guard nameString.characters.count > 0 else {
            return false
        }
        return true
    }
    
    private func isLastNameValid() -> Bool {
        guard let nameString = lastNameField.text else {
            return false
        }
        guard nameString.characters.count > 0 else {
            return false
        }
        return true
    }
    
    private func isEmailAddressValid() -> Bool {
        guard let nameString = emailAddressField.text else {
            return false
        }
        guard nameString.characters.count > 0 else {
            return false
        }
        // TODO: Check that this is a valid email.
        return true
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
