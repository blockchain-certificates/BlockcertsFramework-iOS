//
//  AddIssuerViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/25/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit
import Blockcerts

protocol AddIssuerViewControllerDelegate : class {
    func created(issuer: Issuer)
}

class AddIssuerViewController: UIViewController {

    weak var delegate : AddIssuerViewControllerDelegate?
    var inFlightRequest : CommonRequest?
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var publicKeyURLField: UITextField!
    @IBOutlet weak var firstNamefield: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailAddressField: UITextField!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        captureDataAndCreateIssuer()
    }
    
    func captureDataAndCreateIssuer() {
        guard let givenName = firstNamefield.text,
            let familyName = lastNameField.text,
            let email = emailAddressField.text,
            let issuerURLString = publicKeyURLField.text,
            let issuerURL = URL(string: issuerURLString) else {
                print("Something went wrong with validation. SaveTapped shouldn't be tappable until all of these fields pass valdidation")
                return
        }
        
        let newPublicAddress = Keychain.shared.nextPublicAddress()
        let name : String = givenName + " " + familyName
        
        let recipient = Recipient(name: name, identity: email, identityType: "email", isHashed: false, publicAddress: newPublicAddress, revocationAddress: nil)

        
        let alert = UIAlertController(title: "Adding issuer", message: "Contacting the Issuer at that URL...", preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
        
        createIssuer(from: issuerURL, for: recipient) { [weak self] (possibleIssuer) in
            if let issuer = possibleIssuer {
                self?.delegate?.created(issuer: issuer)
                alert.dismiss(animated: true, completion: { 
                    self?.dismiss(animated: true, completion: nil)
                })
            } else {
                alert.title = "Failed to create the issuer"
                alert.message = "Failed to introduce you to the issuer. Check the URL and try again"
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            }
        }

    }
    
    @IBAction func fieldChanged(_ sender: UITextField) {
        validate()
    }

    // MARK - Form validation functions
    private func validate() {
        saveButton.isEnabled = areAllFieldsValid()
    }
    
    public func areAllFieldsValid() -> Bool {
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
        guard nameString.count > 0 else {
            return false
        }
        return true
    }
    
    private func isLastNameValid() -> Bool {
        guard var nameString = lastNameField.text else {
            return false
        }
        nameString = nameString.trimmingCharacters(in: .whitespaces)
        guard nameString.count > 0 else {
            return false
        }
        return true
    }
    
    private func isEmailAddressValid() -> Bool {
        guard var emailString = emailAddressField.text else {
            return false
        }
        emailString = emailString.trimmingCharacters(in: .whitespaces)
        guard emailString.count > 0 else {
            return false
        }
        
        // Check that this is a valid email.
        let emailRegex = "\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\b"
        let regex = try! NSRegularExpression(pattern: emailRegex, options: [.caseInsensitive])
        let range = NSRange(location: 0, length: emailString.count)
        
        return nil != regex.firstMatch(in: emailString, options: [], range: range)
    }
    
    // MARK: - Contacting the issuer
    func createIssuer(from issuerUrl: URL, for recipient: Recipient, callback: ((Issuer?) -> Void)?) {
        let creationRequest = IssuerIdentificationRequest(id: issuerUrl, logger: DefaultLogger()) { [weak self] (issuer, error) in
            // TODO: consume the error 
            guard let issuer = issuer else {
                DispatchQueue.main.async { callback?(nil) }
                return
            }

            let introductionRequest = IssuerIntroductionRequest(introduce: recipient, to: issuer, loggingTo: DefaultLogger(), callback: { (error) in
                if error == nil {
                    DispatchQueue.main.async { callback?(issuer) }
                } else {
                    DispatchQueue.main.async { callback?(nil) }
                }
            })
            introductionRequest.start()
            self?.inFlightRequest = introductionRequest
        }
        creationRequest.start()
        inFlightRequest = creationRequest
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

extension AddIssuerViewController : UITextViewDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case publicKeyURLField:
            firstNamefield.becomeFirstResponder()
        case firstNamefield:
            lastNameField.becomeFirstResponder()
        case lastNameField:
            emailAddressField.becomeFirstResponder()
        case emailAddressField:
            let allValid = self.areAllFieldsValid()
            if allValid {
                captureDataAndCreateIssuer()
            } else {
                return false
            }
        default:
            break;
        }
        return true
    }
}
