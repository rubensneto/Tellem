//
//  ChooseSignUpController.swift
//  Tellem
//
//  Created by Rubens Neto on 15/02/17.
//  Copyright © 2017 Rubens Neto. All rights reserved.
//

import UIKit

class ChooseSignUpController: UIViewController {

    @IBOutlet weak var userSignUpButton: UIButton!
    @IBOutlet weak var companySignUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        companySignUpButton.layer.cornerRadius = 3
        userSignUpButton.layer.cornerRadius = 3
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func backToLogin(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

}
