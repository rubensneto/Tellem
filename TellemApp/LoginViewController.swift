//
//  LoginViewController.swift
//  Tellem
//
//  Created by Rubens Neto on 08/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase
import SCLAlertView

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    let alertView = SCLAlertView()
    let activityIndicator = ActivityIndicatorController()
    let databaseService = DatabaseService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        loginButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        loginButton.layer.cornerRadius = 3
        fbLoginButton.delegate = self
        fbLoginButton.readPermissions = ["email", "public_profile"]
        fbLoginButton.layer.cornerRadius = 3        
    }
    
    @IBAction func login(_ sender: UIButton) {
        view.endEditing(true)
        FIRAuth.auth()?.signIn(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
            if error != nil {
                self.activityIndicator.stopActivityIndicator()
                self.alertView.showError("OOPS!", subTitle: "We are not able to log you in:\n\(error!.localizedDescription)")
            } else {
                self.activityIndicator.stopActivityIndicator()
                let appDel = UIApplication.shared.delegate as! AppDelegate
                appDel.isLoggedIn()
            }
        })
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            self.alertView.showError("Log in Failed", subTitle: "We are not able to log you in with Facebook.\n\(error!.localizedDescription)")
        } else {
            activityIndicator.startActivityIndicator(view: self.view)
            FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "email, name"]).start(completionHandler: { (connection, result, err) in
                if err != nil {
                    print(err ?? "")
                } else {
                    let accessToken = FBSDKAccessToken.current()
                    let credentials = FIRFacebookAuthProvider.credential(withAccessToken: (accessToken?.tokenString)!)
                    self.databaseService.firebaseSignInWithFacebook(credentials: credentials, accessToken: accessToken, result: result)
                }
            })
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Log out with facebook")
    }
    
    @IBAction func enableLoginButton(_ sender: UITextField) {
        if (emailTextField.text?.characters.count)! > 5 &&
            (passwordTextField.text?.characters.count)! >= 6 {
            loginButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 1)
        } else {
            loginButton.backgroundColor = UIColor(red: 77/255, green: 194/255, blue: 71/255, alpha: 0.3)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if activityIndicator.isActive == true {
            activityIndicator.stopActivityIndicator()
            print("Stopped activity indicator")
        }
    }
    
}
