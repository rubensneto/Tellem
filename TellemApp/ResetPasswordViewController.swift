//
//  ResetPasswordViewController.swift
//  Tellem
//
//  Created by Rubens Neto on 09/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import FirebaseAuth
import SCLAlertView

class ResetPasswordViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var resetPasswordButton: UIButton!
    let alertView = SCLAlertView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        resetPasswordButton.layer.cornerRadius = 3
        resetPasswordButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
    }
    
    @IBAction func resetPassword(_ sender: UIButton) {
        view.endEditing(true)
        if emailTextField.text != nil {
            FIRAuth.auth()?.sendPasswordReset(withEmail: emailTextField.text!, completion: { (error) in
                if error != nil {
                    let subTitle = "We are not able to reset your passowrd:"
                    self.alertView.showError("OOPS!", subTitle: "\(subTitle)\n\(error!.localizedDescription)")
                }else{
                    let subTitle = "An email with the instructions to reset your password was sent to the address you provided."
                    self.alertView.showSuccess("Done!", subTitle: subTitle)
                }
            })
        } else {
            let subTitle = "Please provide the same email you have used to create your account."
            self.alertView.showError("Fill the field!", subTitle: subTitle)
        }
    }
    
    @IBAction func enableButton(_ sender: UITextField) {
        if (emailTextField.text?.characters.count)! > 5 {
            resetPasswordButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 1)
        } else {
            resetPasswordButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        }
    }
    
    @IBAction func backToLogin(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
