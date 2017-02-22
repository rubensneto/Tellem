//
//  FinishSignUpController.swift
//  Tellem
//
//  Created by Rubens Neto on 19/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import SCLAlertView

class FinishSignUpController: UIViewController, UITextViewDelegate, CompanyObjectDelegate {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var businessDescriptionTextView: UITextView!
    @IBOutlet weak var signUpButton: UIButton!
    
    var databaseChild: String!
    var companyObject: CompanyObject!
    let alertView = SCLAlertView()
    let databaseService = DatabaseService()
    let activityIndicator = ActivityIndicatorController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signUpButton.isUserInteractionEnabled = false
        businessDescriptionTextView.delegate = self
        
        if databaseChild == "companies" {
            descriptionLabel.text = "Write a short description about your company:"
        } else {
            descriptionLabel.text = "Write a short description about you and/or your services:"
        }
        
        businessDescriptionTextView.layer.borderColor = UIColor.gray.cgColor
        businessDescriptionTextView.layer.borderWidth = 0.15
        businessDescriptionTextView.layer.cornerRadius = 5
        signUpButton.layer.cornerRadius = 3
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if businessDescriptionTextView.text.characters.count >= 10 {
            signUpButton.isUserInteractionEnabled = true
            signUpButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 1)
        } else {
            signUpButton.isUserInteractionEnabled = false
            signUpButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        }
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        view.endEditing(true)
        if businessDescriptionTextView.text.isEmpty {
            let subTitle = "Please provide a short description."
            alertView.showError("OOPS!", subTitle: subTitle)
        } else {
            companyObject.businessDescription = businessDescriptionTextView.text!
            activityIndicator.startActivityIndicator(view: self.view)
            databaseService.addCompanyOnDatabase(company: companyObject, completion: { 
                self.activityIndicator.stopActivityIndicator()
            })
        }
    }
    
    func fetch(companyObject: CompanyObject) {
        self.companyObject = companyObject
    }
}
