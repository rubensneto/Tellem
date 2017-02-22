//
//  SettingsViewController.swift
//  Tellem
//
//  Created by Rubens Neto on 14/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func logout(_ sender: UIButton) {
        try! FIRAuth.auth()!.signOut()
        if FBSDKAccessToken.current() != nil {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        }
        if let storyboard = self.storyboard {
            let vc = storyboard.instantiateViewController(withIdentifier: "loginNavigationController") as! UINavigationController
            self.present(vc, animated: false, completion: nil) 
        }
    }
}
