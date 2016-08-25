//
//  AddIssuerViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/25/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit
protocol AddIssuerViewControllerDelegate : class {
    func created(issuer: Issuer)
}

class AddIssuerViewController: UIViewController {

    weak var delegate : AddIssuerViewControllerDelegate?
    var keychain : Keychain!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var publicKeyURLField: UITextField!
    @IBOutlet weak var firstNamefield: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailAddressField: UITextField!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        guard let givenName = firstNamefield.text,
            let familyName = lastNameField.text,
            let email = emailAddressField.text,
            let issuerURLString = publicKeyURLField.text,
            let issuerURL = URL(string: issuerURLString) else {
                print("Something went wrong with validation. SaveTapped shouldn't be tappable until all of these fields pass valdidation")
                return
        }
        
        let newPublicKey = keychain.nextPublicKey()
        
        let recipient = Recipient(givenName: givenName, familyName: familyName, identity: email, identityType: "email", isHashed: false, publicKey: newPublicKey)

        createIssuer(from: issuerURL, for: recipient) { [weak self] (possibleIssuer) in
            if let issuer = possibleIssuer {
                self?.delegate?.created(issuer: issuer)
                self?.dismiss(animated: true, completion: nil)
            } else {
                let alertController = UIAlertController(title: "Failed to create the issuer", message: "Looks like there isn't a Blockchain Certificates issuer at this URL. Check the URL and try again", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func fieldEditingDidEnd(_ sender: UITextField) {
        validate()
    }

    // MARK - Form validation functions
    private func validate() {
        saveButton.isEnabled = areAllFieldsValid()
    }
    
    private func areAllFieldsValid() -> Bool {
        return isIssuerURLValid()
            && isFirstNameValid()
            && isLastNameValid()
            && isEmailAddressValid()
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
    
    // MARK: - Contacting the issuer
    func createIssuer(from issuerUrl: URL, for recipient: Recipient, callback: ((Issuer?) -> Void)?) {
        
        // TODO: Actually make URL requests and the like here. For now, just adding a 700ms timeout to simulate network traffic then returning dummy values.
        let sevenHundredMilliseconds = DispatchTime(uptimeNanoseconds: 7_000_000)
        DispatchQueue.main.asyncAfter(deadline: sevenHundredMilliseconds) {
            let issuer = Issuer(name: "Fake Issuer Name",
                                email: "Fake Issuer email",
                                image: Data(),
                                id: URL(string:"http://google.com")!,
                                url: URL(string:"http://google.com")!,
                                publicKey: "AbsolutelyFakePublicKey",
                                publicKeyAddress: issuerUrl,
                                requestUrl: issuerUrl)
            callback?(issuer)
//            print(issuer)
//            callback?(nil)
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
