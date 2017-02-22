//
//  ViewController.swift
//  Tellem
//
//  Created by Rubens Neto on 03/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase
import SCLAlertView

class SignUpController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    let databaseService = DatabaseService()
    let alertView = SCLAlertView()
    let activityIndicator = ActivityIndicatorController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        signUpButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        fbLoginButton.delegate = self
        fbLoginButton.readPermissions = ["email", "public_profile"]
        fbLoginButton.layer.cornerRadius = 3
        signUpButton.layer.cornerRadius = 3
        
    }

    @IBAction func signUp(_ sender: UIButton) {
        view.endEditing(true)
        activityIndicator.startActivityIndicator(view: self.view)
        FIRAuth.auth()?.createUser(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
            if error != nil {
                self.alertView.showError("OOPS!", subTitle: "We are not able to create your account now:\n\(error!.localizedDescription)")
            } else {
                self.databaseService.addUserOnDatabase(user: user!, name: self.fullNameTextField.text!)
            }
            self.activityIndicator.stopActivityIndicator()
        })
    }
    
    //Facebook Login
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out with FB")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            let subTitle = "We are not able to log you in with Facebook:"
            self.alertView.showError("Log in Failed", subTitle: "\(subTitle)\n\(error!.localizedDescription)")
        } else {
            activityIndicator.startActivityIndicator(view: self.view)
            FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "email, name"]).start(completionHandler: { (connection, result, err) in
                if err != nil {
                    print(err ?? "")
                } else {
                    print(result!)
                    let accessToken = FBSDKAccessToken.current()
                    let credentials = FIRFacebookAuthProvider.credential(withAccessToken: (accessToken?.tokenString)!)
                    self.databaseService.firebaseSignInWithFacebook(credentials: credentials, accessToken: accessToken, result: result!)
                }
                self.activityIndicator.stopActivityIndicator()
            })
        }
    }
    
    @IBAction func enableSignUpButton(_ sender: UITextField) {
        if (fullNameTextField.text?.characters.count)! > 5 &&
            (emailTextField.text?.characters.count)! > 5 &&
            (passwordTextField.text?.characters.count)! >= 6 {
            signUpButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 1)
        } else {
            signUpButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        }
    }
    
    @IBAction func dismissView(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}

