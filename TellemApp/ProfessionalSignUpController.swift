//
//  ProfessionalSignUpController.swift
//  Tellem
//
//  Created by Rubens Neto on 15/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import SCLAlertView
import Firebase

protocol CompanyObjectDelegate {
    func fetch(_ companyObject: CompanyObject)
}

class ProfessionalSignUpController: UIViewController {

    @IBOutlet weak var selectSegmentControll: UISegmentedControl!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var delegate: CompanyObjectDelegate? = nil
    var activityIndicator = ActivityIndicatorController()
    let databaseService = DatabaseService()
    let alertView = SCLAlertView()
    var isProfessional: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        nextButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        nextButton.layer.cornerRadius = 3
        nextButton.isUserInteractionEnabled = false
    }
    
    @IBAction func toggleSegmentControl(_ sender: UISegmentedControl) {
        switch selectSegmentControll.selectedSegmentIndex {
        case 0:
            nameTextField.placeholder = "COMPANY NAME"
            isProfessional = false
        case 1:
            nameTextField.placeholder = "FULL NAME"
            isProfessional = true
        default:
            break
        }
    }
    
    @IBAction func createUser(_ sender: UIButton) {
        view.endEditing(true)
       if (emailTextfield.text?.characters.count)! < 5 ||
        (nameTextField.text?.characters.count)! < 5 ||
        (passwordTextField.text?.characters.count)! < 6 {
            let subTitle = "Please fill all the fields with valid data"
            alertView.showEdit("OOPS!", subTitle: subTitle)
        } else {
            activityIndicator.startActivityIndicator(view: self.view)
            let checkedEmail = emailTextfield.text!.replacingOccurrences(of: " ", with: "").lowercased()
            FIRAuth.auth()?.createUser(withEmail: checkedEmail, password: passwordTextField.text!, completion: { (user, error) in
                if error != nil {
                    let subTitle = "We are not able to register you on database:\n\(error?.localizedDescription)"
                    self.alertView.showError("OOPS!", subTitle: subTitle)
                    
                } else{
                    let companyObject = CompanyObject()
                    
                    companyObject.name = self.nameTextField.text!
                    companyObject.email = self.emailTextfield.text!
                    companyObject.uid = user!.uid
                    companyObject.isProfessional = self.isProfessional
                    
                    let completeSignUpController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "completeSignUp") as! CompleteSignUpController
                    
                    self.delegate = completeSignUpController
                    
                    if self.delegate != nil {
                        completeSignUpController.companyObject = companyObject
                        self.navigationController?.pushViewController(completeSignUpController, animated: true)
                    } else {
                        print("Delegate is nil")
                    }
                }
                self.activityIndicator.stopActivityIndicator()
            })
        }
    }
    
    @IBAction func enableNextButton(_ sender: UITextField) {
        if (emailTextfield.text?.characters.count)! >= 5 &&
            (passwordTextField.text?.characters.count)! >= 6 &&
            (nameTextField.text?.characters.count)! >= 1 {
            nextButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 1)
            nextButton.isUserInteractionEnabled = true
        } else {
            nextButton.isUserInteractionEnabled = false
            nextButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func dismissViewController(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}
